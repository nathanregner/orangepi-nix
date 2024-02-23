{
  description = "Orange Pi Linux kernels and supporting NixOS modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    armbian-firmware = {
      url = "github:armbian/firmware";
      flake = false;
    };
    linux-orangepi-zero2-armbian-6_6_17 = {
      url = "github:nathanregner/linux?ref=orangepi-zero2/armbian-6.6.17";
      flake = false;
    };
  };

  outputs = inputs@{ ... }:
    let
      mkPkgs = pkgs: {
        linux-6-6-y =
          pkgs.callPackage ./packages/linux-6.6-rk35xx { inherit inputs; };

        wcnmodem-firmware =
          pkgs.callPackage ./packages/wcnmodem-firmware.nix { };
      };
    in {
      packages = {
        aarch64-linux = mkPkgs inputs.nixpkgs.legacyPackages.aarch64-linux;
        x86_64-linux.pkgsCross = mkPkgs (import inputs.nixpkgs {
          localSystem = "x86_64-linux";
          crossSystem = "aarch64-linux";
        });
      };
    };
}
