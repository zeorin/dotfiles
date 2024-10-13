{
  lib,
  pkgs,
  namespace,
  ...
}:

{
  options = {
    ${namespace}.printing = {
      enable = lib.options.mkEnableOption "printing";
    };
  };

  config = {
    services.printing.enable = true;
    services.printing.drivers = with pkgs.${namespace}; [ mfcj2340dw ];
    # Printer sharing
    services.printing.listenAddresses = [ "*:631" ];
    # this gives access to anyone on the interface you might want to limit it see the official documentation
    services.printing.allowFrom = [ "all" ];
    services.printing.browsing = true;
    services.printing.defaultShared = true; # If you want
    services.printing.openFirewall = true;
    services.samba.package = pkgs.sambaFull;
    services.samba.openFirewall = true;
    services.samba.extraConfig = ''
      load printers = yes
      printing = cups
      printcap name = cups
    '';
    services.samba.shares = {
      printers = {
        "comment" = "All Printers";
        "path" = "/var/spool/samba";
        "public" = "yes";
        "browseable" = "yes";
        # to allow user 'guest account' to print.
        "guest ok" = "yes";
        "writable" = "no";
        "printable" = "yes";
        "create mode" = 700;
      };
    };
    systemd.tmpfiles.rules = [ "d /var/spool/samba 1777 root root -" ];

    hardware.printers.ensureDefaultPrinter = "Brother-MFC-J2430DW";
    hardware.printers.ensurePrinters = [
      {
        name = "Brother-MFC-J2430DW";
        description = "Brother MFC-J2430DW";
        location = "Xandor's Office";
        deviceUri = "usb://Brother/MFC-J2340DW?serial=E81715C4H788972";
        model = "brother_mfcj2340dw_printer_en.ppd";
      }
    ];
  };
}
