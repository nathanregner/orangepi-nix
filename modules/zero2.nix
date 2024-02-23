{ modulesPath, config, pkgs, lib, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/minimal.nix"
  ];

  options.hardware.orangepi-zero2 = {
    pkgs = lib.mkOption { type = lib.types.attrs; };
  };

  config = let cfg = config.hardware.orangepi-zero2;
  in {

    nixpkgs.hostPlatform = "aarch64-linux";

    boot = {
      kernelPackages =
        pkgs.linuxPackagesFor cfg.pkgs.linux.orangepi-zero2-armbian-6_6_y;
      kernelParams = [ "boot.shell_on_fail" ];
      kernelModules = [
        "sprdwl_ng" # wifi driver
      ];
      loader.generic-extlinux-compatible.enable = true;
      loader.grub.enable = false;
    };

    hardware = {
      firmware = [ cfg.pkgs.firmware.wcnmodem ];
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
        dd if=${cfg.pkgs.u-boot.v2021_10-sunxi}/u-boot-sunxi-with-spl.bin of=$img bs=1k seek=8 conv=fsync \
            conv=notrunc # prevent truncation of image
      '';
      compressImage = true;
    };
  };
}

