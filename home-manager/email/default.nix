{
  config,
  pkgs,
  ...
}@moduleArgs:

let
  common = {
    realName = "Xandor Schiefer";
  };

  gpg = {
    key = config.gpg.settings.default-key;
    signByDefault = true;
    encryptByDefault = true;
  };

  gmailChannels = {
    Inbox = {
      farPattern = "INBOX";
      nearPattern = "Inbox";
      extraConfig = {
        Create = "Near";
        Expunge = "Both";
      };
    };
    Archive = {
      farPattern = "Archived Mail";
      nearPattern = "Archive";
      extraConfig = {
        Create = "Both";
        Expunge = "Both";
      };
    };
    Junk = {
      farPattern = "[Gmail]/Spam";
      nearPattern = "Junk";
      extraConfig = {
        Create = "Near";
        Expunge = "Both";
      };
    };
    Trash = {
      farPattern = "[Gmail]/Trash";
      nearPattern = "Trash";
      extraConfig = {
        Create = "Near";
        Expunge = "Both";
      };
    };
    Drafts = {
      farPattern = "[Gmail]/Drafts";
      nearPattern = "Drafts";
      extraConfig = {
        Create = "Near";
        Expunge = "Both";
      };
    };
    Sent = {
      farPattern = "[Gmail]/Sent Mail";
      nearPattern = "Sent";
      extraConfig = {
        Create = "Near";
        Expunge = "Both";
      };
    };
  };

in
{
  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/Maildir";

    accounts = {
      personal = rec {
        primary = true;
        address = "me@xandor.co.za";
        userName = address;
        inherit gpg;
        passwordCommand = "cat ${
          moduleArgs.osConfig.sops.secrets."mail.xandor.co.za/me@xandor.co.za".path
        }";
        imap = {
          host = "mail.xandor.co.za";
          port = 993;
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "mbsync %s && ${pkgs.libnotify}/bin/notify-send 'New Mail for %s'";
        };
        smtp = {
          host = "mail.xandor.co.za";
          port = 465;
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          remove = "both";
          expunge = "both";
        };
        msmtp.enable = true;
        mu.enable = true;
      }
      // common;
      pixeltheory = rec {
        flavor = "gmail.com";
        address = "xandor@pixeltheory.dev";
        inherit gpg;
        passwordCommand = "${config.programs.oama.package}/bin/oama access ${address}";
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "mbsync %s && ${pkgs.libnotify}/bin/notify-send 'New Mail for %s'";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          remove = "both";
          expunge = "both";
          patterns = [
            "*"
            "![Gmail]*"
          ];
          groups.pixeltheory.channels = gmailChannels;
          extraConfig.account.AuthMech = "XOAUTH2";
        };
        msmtp = {
          enable = true;
          extraConfig.auth = "oauthbearer";
        };
        mu.enable = true;
      }
      // common;
      zeorin = rec {
        flavor = "gmail.com";
        address = "zeorin@gmail.com";
        inherit gpg;
        passwordCommand = "${config.programs.oama.package}/bin/oama access ${address}";
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "mbsync %s && ${pkgs.libnotify}/bin/notify-send 'New Mail for %s'";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          remove = "both";
          expunge = "both";
          patterns = [
            "*"
            "![Gmail]*"
          ];
          groups.zeorin.channels = gmailChannels;
          extraConfig.account.AuthMech = "XOAUTH2";
        };
        msmtp = {
          enable = true;
          extraConfig.auth = "oauthbearer";
        };
        mu.enable = true;
      }
      // common;
      xandorschiefer = rec {
        flavor = "gmail.com";
        address = "xandor.schiefer@gmail.com";
        inherit gpg;
        passwordCommand = "${config.programs.oama.package}/bin/oama access ${address}";
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "mbsync %s && ${pkgs.libnotify}/bin/notify-send 'New Mail for %s'";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          remove = "both";
          expunge = "both";
          patterns = [
            "*"
            "![Gmail]*"
          ];
          groups.xandorschiefer.channels = gmailChannels;
          extraConfig.account.AuthMech = "XOAUTH2";
        };
        msmtp = {
          enable = true;
          extraConfig.auth = "oauthbearer";
        };
        mu.enable = true;
      }
      // common;
    };
  };

  programs.mbsync = {
    enable = true;
    package = pkgs.isync.override {
      withCyrusSaslXoauth2 = true;
    };
  };

  services.mbsync = {
    enable = true;
    package = config.programs.mbsync.package;
    configFile = "${config.xdg.configHome}/isyncrc";
    postExec = "${config.programs.mu.package}/bin/mu index";
    # postExec = "${config.programs.emacs.finalPackage}/bin/emacsclient -e '(mu4e-update-index)'";
  };

  services.imapnotify.enable = true;

  programs.msmtp.enable = true;

  programs.mu.enable = true;
}
