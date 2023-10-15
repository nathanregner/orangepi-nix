{
  description = "Orange Pi Linux Kernels";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    armbian-build = {
      url = "github:armbian/build";
      flake = false;
    };

    rockchip-3588 = {
      url =
        "https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    # cross-compile on more powerful host system
    flake-utils.lib.eachDefaultSystem (hostSystem:
      let
        hostPkgs = nixpkgs.legacyPackages.${hostSystem};
        targetPkgs = hostPkgs.pkgsCross.aarch64-multiplatform;
        inherit (targetPkgs) callPackage linuxPackagesFor;
      in {
        packages = {
          pkgsCross.aarch64-multiplatform.linuxKernel.packages.linux-rockchip-rk3588-edge =
            linuxPackagesFor
            (callPackage ./linux/rockchip-rk3588-edge { inherit inputs; });
        };
      });
}
