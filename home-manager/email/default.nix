{ config, lib, pkgs, ... }:

{
  accounts.email = {
    maildirBasePath = "${config.xdg.dataHome}/mail";

    accounts = {
      personal = {
        primary = true;
        address = "me@xandor.co.za";
        realName = "Xandor Schiefer";
        userName = "me@xandor.co.za";
        passwordCommand =
          "${pkgs.pass}/bin/pass mail.xandor.co.za/me@xandor.co.za";
        imap.host = "mail.xandor.co.za";
        # imap.port = 993;
        # imap.tls.useStartTls = true;
        # imapnotify.enable = true;
        imapnotify.boxes = [ "Inbox" ];
        imapnotify.onNotify =
          "${config.programs.mbsync.package}/bin/mbsync test-%s";
        smtp.host = "mail.xandor.co.za";
        # smtp.tls.useStartTls = true;
        mbsync.enable = true;
        mbsync.create = "both";
        # mbsync.expunge = "maildir";
        # mbsync.remove = "maildir";
        mbsync.subFolders = "Maildir++";
        msmtp.enable = true;
        gpg.key = config.gpg.settings.default-key;
        gpg.signByDefault = true;
        gpg.encryptByDefault = true;
        mu.enable = true;
        # thunderbird.enable = true;
      };
      # pixeltheory = {
      #   address = "xandor@pixeltheory.dev";
      #   aliases = [ "xandor@bitbetter.co.za" ];
      #   flavor = "gmail.com";
      #   realName = "Xandor Schiefer";
      #   passwordCommand =
      #     "${pkgs.pass}/bin/pass mail.xandor.co.za/me@xandor.co.za";
      #   mbsync.enable = true;
      #   mbsync.create = "both";
      #   # mbsync.expunge = "maildir";
      #   # mbsync.remove = "maildir";
      #   mbsync.subFolders = "Maildir++";
      #   msmtp.enable = true;
      #   gpg.key = config.gpg.settings.default-key;
      #   gpg.signByDefault = true;
      #   gpg.encryptByDefault = true;
      #   mu.enable = true;
      #   # thunderbird.enable = true;
      # };
      # zeorin = {
      #   address = "zeorin@gmail.com";
      #   flavor = "gmail.com";
      # };
      # xandorschiefer = {
      #   address = "xandorschiefer@gmail.com";
      #   flavor = "gmail.com";
      # };
    };
  };

  programs.mbsync.enable = true;
  home.file.".mbsyncrc".target =
    lib.strings.removePrefix "${config.home.homeDirectory}/"
    config.services.mbsync.configFile;
  services.mbsync.enable = true;
  services.mbsync.configFile = "${config.xdg.configHome}/isync/mbsyncrc";
  services.mbsync.package = config.programs.mbsync.package;
  services.imapnotify.enable = true;
  programs.msmtp.enable = true;
  programs.mu.enable = true;
}
