{ ... }:

final: prev: {
  linuxPackages = prev.linuxPackages.extend (
    lpfinal: lpprev: {
      ddcci-driver = prev.linuxPackages.ddcci-driver.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          # https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/issues/44
          (final.fetchpatch {
            url = "https://gitlab.com/ddcci-driver-linux/ddcci-driver-linux/-/merge_requests/16.patch";
            hash = "sha256-PapgP4cE2+d+YbNSEd6mQRvnumdiEfQpyR5f5Rs1YTs=";
          })
        ];
      });
    }
  );
}
