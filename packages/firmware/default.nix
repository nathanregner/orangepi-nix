{ lib, callPackage, ... }:
lib.recurseIntoAttrs { wcnmodem = callPackage ./wcnmodem.nix { }; }

