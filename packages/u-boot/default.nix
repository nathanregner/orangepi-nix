{ lib, callPackage, ... }:
lib.recurseIntoAttrs { v2021_10-sunxi = callPackage ./v2021_10-sunxi.nix { }; }
