{ armTrustedFirmwareAllwinnerH616, buildUBoot, fetchFromGitHub, ... }:
buildUBoot {
  version = "v2021.10";
  extraMeta.platforms = [ "aarch64-linux" ];

  src = fetchFromGitHub {
    owner = "orangepi-xunlong";
    repo = "u-boot-orangepi";
    rev = "0b91e222a025640182ea986f3c8e8db98cdc962a";
    sha256 = "sha256-sNsLKzsuLUiH9qcmEgJ5wzrGn0KMSGRHMJchk22r2ys=";
  };
  patches = [ ];
  defconfig = "orangepi_zero2_defconfig";

  BL31 = "${armTrustedFirmwareAllwinnerH616}/bl31.bin";
  filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
}
