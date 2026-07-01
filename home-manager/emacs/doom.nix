{
  config,
  lib,
  pkgs,
  ...
}:

let
  emacs = config.programs.emacs.finalPackage;
  doomemacs = pkgs.symlinkJoin {
    name = "doomemacs";
    paths = [ pkgs.doomemacs ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/doom" \
        --set LSP_USE_PLISTS true \
        --set DOOMDIR "${config.xdg.configHome}/doom" \
        --set DOOMLOCALDIR "${config.xdg.dataHome}/doom" \
        --prefix PATH : "${lib.makeBinPath [ emacs ]}"
    '';
  };
  nodejs = pkgs.nodejs_latest;
in
{
  home.sessionPath = [ "${doomemacs}/bin" ];
  xdg.configFile = {
    "doom/init.el" = {
      source = pkgs.replaceVars ./doom/init.el {
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
              zathura
              texlab
              python3
              binutils
              (ripgrep.override { withPCRE2 = true; })
              ast-grep
              fd
              gnutls
              imagemagick
              zstd
              shfmt
              maim
              shellcheck
              sqlite
              editorconfig-core-c
              mermaid-cli
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
              bash-language-server
              stylelint
              dockerfile-language-server
              js-beautify
              typescript-language-server
              typescript-go
              typescript
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
              yaml-language-server
              prettier
              jq
              nixfmt
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
              wl-clipboard
              watchman
            ]
          );
        };
      };
      onChange = "${pkgs.writeShellScript "on-doomemacs-init-el-change" ''
        ${doomemacs}/bin/doom --force sync
      ''}";
    };
    "doom/config.el" = {
      source = pkgs.replaceVars ./doom/config.el {
        doom-png = "${./doom.png}";
        DOOMLOCALDIR = "${config.xdg.dataHome}/doom";
        XDG_DOCUMENTS_DIR = "${config.xdg.userDirs.documents}";
        XDG_DATA_HOME = "${config.xdg.dataHome}";

        inherit nodejs;
        inherit (pkgs.unstable) vscode-js-debug;
        inherit (pkgs.unstable.vscode-extensions.dbaeumer) vscode-eslint;
        inherit (pkgs.unstable.vscode-extensions.firefox-devtools) vscode-firefox-debug;
      };
    };
    "doom/packages.el" = {
      source = ./doom/packages.el;
      onChange = "${pkgs.writeShellScript "on-doomemacs-packages-el-change" ''
        ${doomemacs}/bin/doom --force sync
      ''}";
    };
  };

  home.extraDependencies = [
    "${doomemacs}"
  ];

  home.packages = with pkgs; [
    emacs-all-the-icons-fonts
  ];
}
