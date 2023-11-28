{ inputs, pkgs, armTrustedFirmwareAllwinnerH616, ... }:
pkgs.buildUBoot {
  version = "v2021.10";
  extraMeta.platforms = [ "aarch64-linux" ];

  src = inputs.u-boot-orangepi-v2021_10-sunxi;
  patches = [ ];
  defconfig = "orangepi_zero2_defconfig";

  BL31 = "${armTrustedFirmwareAllwinnerH616}/bl31.bin";
  filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
}
