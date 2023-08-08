{ inputs, lib, pkgsBuildBuild, linuxManualConfig, ... }@args:
let inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang;
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
  configfile = ./.config;

  # build with Clang for easier cross-compilation
  extraMakeFlags = [
    "LLVM=1"
    "KCFLAGS=-I${clang}/resource-root/include"
    "CROSS_COMPILE=aarch64-linux-gnu-"
  ];

  kernelPatches = [{
    name = "nix-patches";
    patch = let
      patchesPath = ./patches;
      isPatchFile = name: value:
        value == "regular" && (lib.hasSuffix ".patch" name);
      patchFilePath = name: patchesPath + "/${name}";
    in map patchFilePath (lib.naturalSort (lib.attrNames
      (lib.filterAttrs isPatchFile (builtins.readDir patchesPath))));

    extraStructuredConfig = with lib.kernel; { };
  }] ++ args.kernelPatches or [ ];
} // (args.argsOverride or { })).overrideAttrs (final: prev: {

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  # remove CC=stdenv.cc flag
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
