{ inputs, lib, pkgsBuildBuild, linuxManualConfig, ... }@args:
let inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang;
in with lib;
(linuxManualConfig rec {
  version = "6.1.31";
  modDirVersion = version;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  src = inputs.linux-orange-pi-6-1-sun50iw9;

  allowImportFromDerivation = true;
  configfile = ./.config;

  # build with Clang for easier cross-compilation
  extraMakeFlags = [
    "LLVM=1"
    "KCFLAGS=-I${clang}/resource-root/include"
    "CROSS_COMPILE=aarch64-linux-gnu-"
  ];

} // (args.argsOverride or { })).overrideAttrs (final: prev: {

  nativeBuildInputs = prev.nativeBuildInputs
    ++ [ bintools-unwrapped clang pkgsBuildBuild.ubootTools ];

  # remove CC=stdenv.cc flag
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
