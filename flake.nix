{
  description = "Orange Pi Linux Kernels";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    linux-orange-pi-6-5-rk3588 = {
      url = "git://git.kernel.org/pub/scm/linux/kernel/git/sre/linux-misc.git";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    # cross-compile on more powerful host system
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (hostSystem:
      let
        hostPkgs = nixpkgs.legacyPackages.${hostSystem};
        targetPkgs = hostPkgs.pkgsCross.aarch64-multiplatform;
        inherit (targetPkgs) callPackage;
      in {
        packages = {
          linux-orange-pi-6-5-rk3588 =
            callPackage ./linux/orange-pi-6.5-rk3588 { inherit inputs; };
        };
      });
}
