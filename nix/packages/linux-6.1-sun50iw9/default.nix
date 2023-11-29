{ inputs, lib, pkgsBuildBuild, linuxManualConfig, callPackage, ... }@args:
let inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang stdenv;
in with lib;
((linuxManualConfig rec {
  version = "6.1.31";
  modDirVersion = version;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  src = inputs.linux-orangepi-sun50iw9;

  allowImportFromDerivation = true;
  configfile = ./.config;

  kernelPatches = [{
    name = "nix-patches";
    patch = let
      patchesPath = ./patches;
      isPatchFile = name: value:
        value == "regular" && (lib.hasSuffix ".patch" name);
      patchFilePath = name: patchesPath + "/${name}";
    in map patchFilePath (lib.naturalSort (lib.attrNames
      (lib.filterAttrs isPatchFile (builtins.readDir patchesPath))));
    extraStructuredConfig = { };
  }];

  # build with Clang for easier cross-compilation
  extraMakeFlags = [ "WERROR=0" "LLVM=1" "CROSS_COMPILE=arm64-linux-gnueabi-" ];
} // (args.argsOverride or { })).override { inherit stdenv; }).overrideAttrs
(final: prev: {
  name = "k"; # stay under u-boot path length limit

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  preBuild = ''
    makeFlagsArray+=(KCFLAGS="-I${clang}/resource-root/include -Wno-everything -march=armv8-a+crypto")
  '';

  passthru.defconfig = ((linuxManualConfig rec {
    version = "6.1.31";
    modDirVersion = version;
    extraMeta = {
      branch = versions.majorMinor version;
      platforms = [ "aarch64-linux" ];
    };
    src = inputs.linux-orangepi-sun50iw9;
    configfile = ./.config;
    allowImportFromDerivation = false;
    extraMakeFlags =
      [ "WERROR=0" "LLVM=1" "CROSS_COMPILE=arm64-linux-gnueabi-" ];
  }).override { inherit stdenv; }).overrideAttrs (final: prev: {
    buildFlags = [ "savedefconfig" ];
    installPhase = "cp ./defconfig $out";

    nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];
    # remove CC=stdenv.cc
    makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
  });
})

