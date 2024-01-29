{
  description = "Orange Pi Linux kernels and supporting NixOS modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flakelight = {
      url = "github:accelbread/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    armbian-build = {
      url = "github:armbian/build";
      flake = false;
    };
    orangepi-build = {
      url = "github:orangepi-xunlong/orangepi-build";
      flake = false;
    };
    orangepi-firmware = {
      url = "github:orangepi-xunlong/firmware";
      flake = false;
    };
    linux-orangepi-sun50iw9 = {
      url = "github:orangepi-xunlong/linux-orangepi?ref=orange-pi-6.1-sun50iw9";
      flake = false;
    };
    linux-orangepi-orange-pi-6-6-rk35xx = {
      url = "github:orangepi-xunlong/linux-orangepi?ref=orange-pi-6.6-rk35xx";
      flake = false;
    };
    u-boot-orangepi-v2021_10-sunxi = {
      url = "github:orangepi-xunlong/u-boot-orangepi?ref=v2021.10-sunxi";
      flake = false;
    };
  };

  outputs = inputs@{ flakelight, ... }:
    flakelight ./. {
      inherit inputs;
      systems = [ "aarch64-linux" ];
    } // {
      packages.x86_64-linux.pkgsCross = let
        pkgs = import inputs.nixpkgs {
          localSystem = "x86_64-linux";
          crossSystem = "aarch64-linux";
        };
      in {
        linux = pkgs.callPackage ./nix/packages/linux-6_1-sun50iw9.nix {
          inherit inputs;
        };
      };
    };
}
