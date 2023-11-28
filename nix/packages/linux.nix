{ inputs, pkgs, lib }@args:
with lib;
let aarch64 = pkgs.pkgsCross.aarch64-multiplatform;
in (aarch64.buildLinux (rec {
  version = "6.1.31";
  modDirVersion = versions.pad 3 version;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  src = inputs.linux-orangepi-sun50iw9;

  structuredExtraConfig = with lib.kernel; {
    CONFIG_ARCH_SUNXI = yes;

    # UNISOC WCN Device Drivers
    CONFIG_AW_WIFI_DEVICE_UWE5622 = yes;
    CONFIG_AW_BIND_VERIFY = yes;

    CONFIG_WLAN_UWE5622 = module;
    CONFIG_SPRDWL_NG = module;
    CONFIG_UNISOC_WIFI_PS = yes;
    CONFIG_TTY_OVERY_SDIO = module;
    CONFIG_USB_NET_RNDIS_WLAN = module;
    CONFIG_VIRT_WIFI = module;
    CONFIG_IEEE802154_DRIVERS = module;
  };

  kernelPatches = [{
    name = "nix-patches";
    patch = let
      patchesPath = ./patches;
      isPatchFile = name: value:
        value == "regular" && (lib.hasSuffix ".patch" name);
      patchFilePath = name: patchesPath + "/${name}";
    in map patchFilePath (lib.naturalSort (lib.attrNames
      (lib.filterAttrs isPatchFile (builtins.readDir patchesPath))));
  }];
} // (args.argsOverride or { })))
# .override (_: { stdenv = aarch64.clangStdenv; })
