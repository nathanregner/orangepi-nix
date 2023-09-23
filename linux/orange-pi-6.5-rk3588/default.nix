{ inputs, lib, pkgsBuildBuild, linuxManualConfig, ... }@args:
let inherit (pkgsBuildBuild.llvmPackages_16) bintools-unwrapped clang;
in with lib;
(linuxManualConfig rec {
  version = "6.5.0-rc1";
  modDirVersion = version;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  src = inputs.linux-orange-pi-6-5-rk3588;

  allowImportFromDerivation = true;
  configfile = ./linux-rockchip-rk3588-collabora.config;

  # build with Clang for easier cross-compilation
  extraMakeFlags = [ "LLVM=1" "CROSS_COMPILE=aarch64-linux-gnu-" ];
} // (args.argsOverride or { })).overrideAttrs (final: prev: {

  preConfigure = ''
    makeFlagsArray+=(
      KCFLAGS="-I${clang}/resource-root/include -Wno-unused-command-line-argument"
    )
  '';

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  # remove CC=stdenv.cc flag
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
