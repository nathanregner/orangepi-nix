{ modulesPath, pkgs, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/minimal.nix"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux-6_6-rk35xx;
    kernelParams = [ "boot.shell_on_fail" ];
    kernelModules = [
      "sprdwl_ng" # wifi driver
    ];
    loader.generic-extlinux-compatible.enable = true;
    loader.grub.enable = false;
  };

  hardware = {
    firmware = [ pkgs.wcnmodem-firmware ];
    deviceTree = {
      name = "allwinner/sun50i-h616-orangepi-zero2.dtb";
      filter = "sun50i-h616-orangepi-zero2.dtb";
    };
  };

  sdImage = {
    postBuildCommands = ''
      # Emplace bootloader to specific place in firmware file
      dd if=/dev/zero of=$img bs=1k count=1023 seek=1 status=noxfer \
          conv=notrunc # prevent truncation of image
      dd if=${pkgs.u-boot-v2021_10-sunxi}/u-boot-sunxi-with-spl.bin of=$img bs=1k seek=8 conv=fsync \
          conv=notrunc # prevent truncation of image
    '';
    compressImage = true;
  };
}
