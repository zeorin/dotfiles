{
  config,
  lib,
  pkgs,
  ...
}:

let
  round = x: if ((x / 2.0) >= 0.5) then (builtins.ceil x) else (builtins.floor x);
  dpiScale = x: round (x * (config.dpi / 96.0));
  emacs = config.programs.emacs.finalPackage;
  doomScriptEnvVars = ''
    export PATH="${config.xdg.configHome}/doom-emacs/bin/:${emacs}/bin:$PATH"
    export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
    export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
    export LSP_USE_PLISTS=true
  '';
in
{
  xdg.configFile = {
    doom-emacs = {
      source = pkgs.doomemacs;
      onChange = "${pkgs.writeShellScript "doom-change" ''
        ${doomScriptEnvVars}
        if [ ! -d "$DOOMLOCALDIR" ]; then
          doom --force install
        else
          doom --force sync -u
        fi
      ''}";
    };
    "doom/init.el" = {
      source = pkgs.replaceVars ./doom/init.el {
        exec-path = pkgs.buildEnv {
          name = "doom-emacs-deps";
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
              zathura
              texlab
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
              nixd
              elixir-ls
              marksman
              black
              isort
              pipenv
              python3Packages.pytest
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
      onChange = "${pkgs.writeShellScript "doom-config-init-change" ''
        ${doomScriptEnvVars}
        doom --force sync
      ''}";
    };
    "doom/config.el" = {
      source = pkgs.replaceVars ./doom/config.el {
        "12px" = toString (dpiScale 12);
        "18px" = toString (dpiScale 18);
        doom-png = ./doom.png;
        inherit (pkgs) nodejs;
        inherit (pkgs.unstable) vscode-js-debug;
        inherit (pkgs.unstable.vscode-extensions.dbaeumer) vscode-eslint;
        inherit (pkgs.unstable.vscode-extensions.firefox-devtools) vscode-firefox-debug;
        inherit (config.home.sessionVariables) DOOMLOCALDIR XDG_DOCUMENTS_DIR XDG_DATA_HOME;
      };
      onChange = "${pkgs.writeShellScript "doom-config-packages-change" ''
        ${doomScriptEnvVars}
        doom --force sync -u
      ''}";
    };
    "doom/packages.el".source = ./doom/packages.el;
  };

  home.packages = with pkgs; [ emacs-all-the-icons-fonts ];
}
