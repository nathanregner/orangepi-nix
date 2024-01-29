{
  description = "Orange Pi Linux kernels and supporting NixOS modules";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    linux-orangepi-zero2-armbian-6_6_y = {
      url = "github:nathanregner/linux?ref=orangepi-zero2/armbian-6.6.y";
      # url = "git+file:///home/nregner/dev/github/linux/armbian-6.6.16?shallow=1";
      flake = false;
    };
  };

  outputs = inputs@{ ... }:
    let
      mkPkgs = { callPackage, lib, ... }:
        lib.recurseIntoAttrs {
          firmware = callPackage ./packages/firmware { };
          linux = callPackage ./packages/linux { inherit inputs; };
          u-boot = callPackage ./packages/u-boot { };
        };
    in {
      packages = {
        aarch64-linux = mkPkgs inputs.nixpkgs.legacyPackages.aarch64-linux;
        x86_64-linux.pkgsCross = mkPkgs (import inputs.nixpkgs {
          localSystem = "x86_64-linux";
          crossSystem = "aarch64-linux";
        });
      };

      nixosModules = { zero2 = import ./modules/zero2.nix; };
    };
}
