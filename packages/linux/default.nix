{ lib, callPackage, ... }:
lib.recurseIntoAttrs {
  orangepi-zero2-armbian-6_6_y = callPackage ./orangepi-zero2-armbian-6_6_y { };
}
