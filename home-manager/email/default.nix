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

  maildir = "${config.xdg.dataHome}/Maildir";

in
{
  accounts.email = {
    maildirBasePath = maildir;

    accounts = {
      personal = rec {
        primary = true;
        address = "me@xandor.co.za";
        userName = address;
        inherit gpg;
        passwordCommand = "${pkgs.coreutils}/bin/cat ${
          moduleArgs.osConfig.sops.secrets."mail.xandor.co.za/me@xandor.co.za".path
        }";
        imap = {
          host = "mail.xandor.co.za";
          port = 993;
        };
        imapnotify = {
          enable = true;
          boxes = [ "INBOX" ];
          onNotify = "${config.programs.mbsync.package}/bin/mbsync personal:%s && ${config.programs.mu.package}/bin/mu index --quiet --lazy-check";
        };
        smtp = {
          host = "mail.xandor.co.za";
          port = 465;
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          # remove = "both";
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
          onNotify = "${config.programs.mbsync.package}/bin/mbsync pixeltheory-Inbox && ${config.programs.mu.package}/bin/mu index --quiet --lazy-check && ${pkgs.libnotify}/bin/notify-send 'New Mail for xandor@pixeltheory.dev'";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          # remove = "both";
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
          onNotify = "${config.programs.mbsync.package}/bin/mbsync zeorin-Inbox && ${config.programs.mu.package}/bin/mu index --quiet --lazy-check";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          # remove = "both";
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
          onNotify = "${config.programs.mbsync.package}/bin/mbsync xandorschiefer-Inbox && ${config.programs.mu.package}/bin/mu index --quiet --lazy-check";
          extraConfig = {
            xoAuth2 = true;
          };
        };
        mbsync = {
          enable = true;
          subFolders = "Maildir++";
          create = "both";
          # remove = "both";
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
    postExec = "${config.programs.mu.package}/bin/mu index --quiet";
  };

  services.imapnotify.enable = true;

  programs.msmtp.enable = true;

  programs.mu.enable = true;
}
