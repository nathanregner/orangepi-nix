{
  description = "Orange Pi Linux Kernels";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    # Orange Pi Zero 2
    linux-orange-pi-6-1-sun50iw9 = {
      # url = "github:orangepi-xunlong/linux-orangepi/orange-pi-6.1-sun50iw9";
      url = "github:nathanregner/linux-orangepi/orange-pi-6.1-sun50iw9";
      flake = false;
    };

    # Orange Pi 5
    linux-orange-pi-5-10-armbian = {
      url = "github:armbian/linux-rockchip/rk-5.10-rkr4";
      flake = false;
    };
    linux-orange-pi-6-5-rk3588 = {
      url =
        "git+ssh://git@github.com/nathanregner/linux-orangepi?ref=collabora-rk3588";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    # cross-compile on more powerful host system
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (hostSystem:
      let
        hostPkgs = nixpkgs.legacyPackages.${hostSystem};
        targetPkgs = hostPkgs.pkgsCross.aarch64-multiplatform;
        inherit (targetPkgs) callPackage linuxPackagesFor;
      in {
        packages = rec {
          linux-orange-pi-6-1-sun50iw9 = linuxPackagesFor
            (callPackage ./linux/orange-pi-6.1-sun50iw9 { inherit inputs; });
          linux-orange-pi-6-5-rk3588 = linuxPackagesFor
            (callPackage ./linux/orange-pi-6.5-rk3588 { inherit inputs; });
        };

        devShells.default =
          hostPkgs.mkShell { packages = [ hostPkgs.bashInteractive ]; };
      });
}
