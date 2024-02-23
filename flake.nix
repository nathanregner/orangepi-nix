{
  description = "Orange Pi Linux kernels and supporting NixOS modules";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  outputs = inputs@{ ... }:
    let
      mkPkgs = { callPackage, lib, ... }:
        lib.recurseIntoAttrs {
          firmware = callPackage ./packages/firmware { };
          linux = callPackage ./packages/linux { };
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
