{ inputs, lib, pkgsBuildBuild, linuxManualConfig, linuxPackages_latest, ...
}@args:
let
  inherit (pkgsBuildBuild.llvmPackages_16) bintools-unwrapped clang;
  inherit (linuxPackages_latest) kernel;
  # https://github.com/armbian/build/blob/103d8403078c149334a8454adda1641f1151f4c5/config/sources/families/rockchip-rk3588.conf#L32
  patchesPath = "${inputs.armbian-build}/patch/kernel/rockchip-rk3588-edge/";
  configPath =
    "${inputs.armbian-build}/config/kernel/linux-rockchip-rk3588-edge.config";
in with lib;
(linuxManualConfig rec {
  # TODO: pin to version that Armbian build is expecting...
  inherit (kernel) version modDirVersion src;
  extraMeta = {
    branch = versions.majorMinor version;
    platforms = [ "aarch64-linux" ];
  };

  allowImportFromDerivation = true;
  configfile = configPath;

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
} // (args.argsOverride or { })).overrideAttrs (final: prev: {

  preConfigure = ''
    ${prev.preConfigure or ""}
    makeFlagsArray+=(
      KCFLAGS="-I${clang}/resource-root/include -Wno-unused-command-line-argument"
    )
  '';

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
        (map (dts: "dtb-\\$(CONFIG_ARCH_ROCKCHIP) += ${dts}"))
        (lib.concatStringsSep "\n")
      ]
    }" >> ${dtsPath}/Makefile;
  '';

  nativeBuildInputs = prev.nativeBuildInputs ++ [ bintools-unwrapped clang ];

  # remove CC=stdenv.cc flag
  makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
})
