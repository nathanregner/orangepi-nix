{ lib, pkgsBuildBuild, linuxManualConfig, args }:
let inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang stdenv;
in with lib;
((linuxManualConfig ({
  modDirVersion = args.version;
  extraMeta = {
    branch = versions.majorMinor args.version;
    platforms = [ "aarch64-linux" ];
  };
  allowImportFromDerivation = false;
} // args)).override { inherit stdenv; }).overrideAttrs (final: prev: {
  name = "defconfig";

  buildFlags = [ "savedefconfig" ];
  installPhase = ''
    cp ./defconfig $out
  '';

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  # remove CC=stdenv.cc
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})

