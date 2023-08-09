{
  description = "Orange Pi Linux Kernels";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

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
          linux-orange-pi-6-5-rk3588 = linuxPackagesFor
            (callPackage ./linux/orange-pi-6.5-rk3588 { inherit inputs; });
        };

        devShells.default =
          hostPkgs.mkShell { packages = [ hostPkgs.bashInteractive ]; };
      });
}
