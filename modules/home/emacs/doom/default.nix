{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.emacs.doom;
  finalEmacs = config.programs.emacs.finalPackage.emacs;
  doomemacs = (cfg.package.override { emacs = finalEmacs; });
  dpiScale = lib.${namespace}.dpiScale config.${namespace}.dpi;
in
{
  options = {
    ${namespace}.emacs.doom = {
      enable = lib.options.mkEnableOption "doomemacs";

      package = lib.options.mkPackageOption pkgs.${namespace} "doomemacs" { };

      chemacs.default = lib.options.mkOption {
        default = false;
        example = true;
        description = "Whether to make DOOM Emacs the default Chemacs profile.";
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      if ((cfg.chemacs != null) && !config.${namespace}.emacs.chemacs.enable) then
        [
          ''Chemacs has not been enabled, `config.${namespace}.emacs.doom.chemacs` options will have no effect.''
        ]
      else
        [ ];

    ${namespace}.emacs = {
      init-directory = lib.mkIf (
        !config.${namespace}.emacs.chemacs.enable
      ) "${doomemacs}/share/emacs/site-lisp";
      chemacs = lib.mkIf config.${namespace}.emacs.chemacs.enable {
        profiles = {
          doomemacs = {
            user-emacs-directory = "${doomemacs}/share/emacs/site-lisp";
          };
        };
        default = lib.mkIf cfg.chemacs.default "doomemacs";
      };
      vterm.enable = true;
      tsc.enable = true;
    };

    home.sessionVariables.DOOMDIR = "${config.xdg.configHome}/doomemacs";

    xdg.configFile = {
      "doomemacs/init.el".source = pkgs.unstable.replaceVars ./init.el {
        exec-path = pkgs.buildEnv {
          name = "doomemacs-deps";
          pathsToLink = [ "/bin" ];
          paths = map lib.getBin (
            with pkgs;
            [
              git
              emacs-lsp-booster
              dockfmt
              libxml2
              rstfmt
              texlive.combined.scheme-medium
              python3
              binutils
              (ripgrep.override { withPCRE2 = true; })
              fd
              gnutls
              imagemagick
              zstd
              shfmt
              maim
              shellcheck
              sqlite
              editorconfig-core-c
              nodePackages.mermaid-cli
              pandoc
              gcc
              gdb
              lldb
              graphviz-nox
              wordnet
              (writeShellScriptBin "hledger" ''
                # https://github.com/simonmichael/hledger/issues/367#issuecomment-956436493
                iargs=("$@")
                oargs=()
                j=0;
                date=;
                for((i=0; i<''${#iargs[@]}; ++i)); do
                    case ''${iargs[i]} in
                        --date-format)
                            # drop --date-format and the next arg
                            i=$((i+1));
                            ;;
                        xact)
                            # convert "xact" to "print --match"
                            oargs[j]=print; oargs[j+1]=--match; j=$((j+2));
                            # drop xact argument and stash the date argument
                            i=$((i+1));
                            date=''${iargs[i]};
                            ;;
                        *)
                            # keep any other args:
                            oargs[j]=''${iargs[i]};
                            j=$((j+1));
                            ;;
                    esac
                done

                if test "$date"
                then
                    # substitute the given date for the old date:
                    ${lib.getBin hledger}/bin/hledger "''${oargs[@]}" | sed "1s/....-..-../$date/"
                else
                    ${lib.getBin hledger}/bin/hledger "''${oargs[@]}"
                fi
              '')
              fava
              html-tidy
              nodejs
              nodePackages.bash-language-server
              nodePackages.stylelint
              nodePackages.dockerfile-language-server-nodejs
              nodePackages.js-beautify
              nodePackages.typescript-language-server
              nodePackages.typescript
              (writeScriptBin "vscode-css-language-server" ''
                #!${nodejs}/bin/node
                require('${vscodium}/lib/vscode/resources/app/extensions/css-language-features/server/dist/node/cssServerMain.js')
              '')
              (writeScriptBin "vscode-html-language-server" ''
                #!${nodejs}/bin/node
                require('${vscodium}/lib/vscode/resources/app/extensions/html-language-features/server/dist/node/htmlServerMain.js')
              '')
              (writeScriptBin "vscode-json-language-server" ''
                #!${nodejs}/bin/node
                require('${vscodium}/lib/vscode/resources/app/extensions/json-language-features/server/dist/node/jsonServerMain.js')
              '')
              (writeScriptBin "vscode-markdown-language-server" ''
                #!${nodejs}/bin/node
                require('${vscodium}/lib/vscode/resources/app/extensions/markdown-language-features/server/dist/node/workerMain.js')
              '')
              nodePackages.yaml-language-server
              nodePackages.unified-language-server
              nodePackages.prettier
              jq
              # nixfmt-classic
              nixfmt-rfc-style
              nil
              black
              isort
              pipenv
              python3Packages.pytest
              python3Packages.nose
              python3Packages.pyflakes
              python3Packages.python-lsp-server
              python3Packages.grip
              multimarkdown
              xclip
              xdotool
              xorg.xwininfo
              xorg.xprop
              watchman
            ]
          );
        };
      };
      "doomemacs/config.el".source = pkgs.unstable.replaceVars ./config.el {
        "12px" = toString (dpiScale 12);
        "18px" = toString (dpiScale 18);
        doom-png = ./doom.png;
        eslintServer = "${pkgs.unstable.vscode-extensions.dbaeumer.vscode-eslint}/share/vscode/extensions/dbaeumer.vscode-eslint/server/out/eslintServer.js";
        js-debug-path = "${pkgs.unstable.vscode-js-debug}/bin";
        firefox-debug-path = "${pkgs.unstable.vscode-extensions.firefox-devtools.vscode-firefox-debug}/share/vscode/extensions/firefox-devtools.vscode-firefox-debug";
      };
      "doomemacs/packages.el".source = ./packages.el;
    };

    home.packages = with pkgs; [
      doomemacs
      emacs-all-the-icons-fonts
    ];
  };
}
