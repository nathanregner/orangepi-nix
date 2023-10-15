{ inputs, lib, pkgsBuildBuild, linuxManualConfig, linuxPackages_latest
, pkgsHostTarget, pkgsBuildTarget, buildPackages # FIXME: pkgsBuildTarget
, writeTextFile, fetchurl, ... }@args:
let
  inherit (linuxPackages_latest) kernel;

  inherit (pkgsBuildBuild.llvmPackages_16) stdenv bintools-unwrapped clang;

  # stdenv = ccacheStdenv.override { stdenv = clangStdenv; };

  # https://github.com/armbian/build/blob/103d8403078c149334a8454adda1641f1151f4c5/config/sources/families/rockchip-rk3588.conf#L32
  patchesPath = "${inputs.armbian-build}/patch/kernel/rockchip-rk3588-edge/";
in with lib;
((linuxManualConfig rec {
  # TODO: pin to version that Armbian build is expecting...
  # inherit (kernel) version modDirVersion src;

  version = "6.6-rc5";
  src = fetchurl {
    url = "https://git.kernel.org/torvalds/t/linux-6.6-rc5.tar.gz";
    hash = "sha256-drpGgR7oFWfOfbd42S1eXM6QW42EfYUINlJloDWP/Kw=";
  };

  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  allowImportFromDerivation = true;

  # make LSMOD=/tmp/mylsmod LMC_KEEP="drivers/usb:drivers/gpu:fs" localmodconfig
  configfile = writeTextFile {
    name = ".config";
    text = let
      # base = builtins.readFile "${inputs.armbian-build}/config/kernel/linux-rockchip-rk3588-edge.config";
      base = builtins.readFile ./.config;
      # enable modules required by systemd: 
      # https://github.com/NixOS/nixpkgs/blob/0396d3b0fb7f62ddc79a506ad3e6124f01d2ed0a/nixos/modules/system/boot/systemd.nix#L575
    in ''
      ${base}
      CONFIG_AUTOFS4_FS=m
    '';
  };

  kernelPatches = [{
    name = "armbian-patches";
    patch = let
      isPatchFile = name: value:
        value == "regular" && (lib.hasSuffix ".patch" name);
      patchFilePath = name: patchesPath + "/${name}";
    in map patchFilePath (lib.naturalSort (lib.attrNames
      (lib.filterAttrs isPatchFile (builtins.readDir patchesPath))));
  }];

  # build with Clang for easier cross-compilation
  extraMakeFlags = [ "LLVM=1" "CROSS_COMPILE=aarch64-linux-gnu-" ];
} // (args.argsOverride or { })).override {
  # stdenv = (pkgsBuildTarget.ccacheStdenv.override {
  #   stdenv = pkgsBuildTarget.clangStdenv;
  # });
}).overrideAttrs (final: prev: {

  # re-implement armbian DTS patching
  # https://github.com/armbian/build/blob/103d8403078c149334a8454adda1641f1151f4c5/patch/kernel/rockchip-rk3588-edge/0000.patching_config.yaml
  postPatch = let dtsPath = "arch/arm64/boot/dts/rockchip/";
  in ''
    ${prev.postPatch or ""}
    cp -r ${patchesPath}dt/* ${dtsPath};
    echo "${
      lib.pipe "${patchesPath}dt" [
        builtins.readDir
        lib.attrNames
        (map (dts:
          "dtb-\\$(CONFIG_ARCH_ROCKCHIP) += ${
            lib.removeSuffix ".dts" dts
          }.dtb"))
        (lib.concatStringsSep "\n")
      ]
    }" >> ${dtsPath}/Makefile;
  '';

  depsBuildBuild = [
    # (buildPackages.ccacheStdenv.override { inherit stdenv; }).cc
    stdenv.cc
    bintools-unwrapped
    clang
  ];

  nativeBuildInputs = [
    # (pkgsBuildBuild.ccacheStdenv.override { inherit stdenv; }).cc
    stdenv.cc
    bintools-unwrapped
    clang
  ] ++ prev.nativeBuildInputs;

  preConfigure = ''
    ${prev.preConfigure or ""}
    makeFlagsArray+=(
      KCFLAGS="-I${clang}/resource-root/include -Wno-unused-command-line-argument"
    )
  '';

  # remove CC=stdenv.cc flag
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
