{ inputs, lib, pkgsBuildBuild, buildLinux, linuxManualConfig, runCommand, git
, ... }@args:
with lib;
let
  inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang stdenv;

  common = rec {
    version = "6.1.31";
    modDirVersion = version;
    extraMeta = {
      branch = versions.majorMinor version;
      platforms = [ "aarch64-linux" ];
    };
    src = inputs.linux-orangepi-sun50iw9;
    # use clang for simpler cross-compilation
    extraMakeFlags = [
      "WERROR=0"
      "LLVM=1"
      "CROSS_COMPILE=arm64-linux-gnueabi-"
      # nativeBuildInputs doesn't get passed to the configfile derivation,
      # so set this manually...
      "LD=${bintools-unwrapped}/bin/ld.lld"
    ];
  };

  applyOverrides = (drv:
    (drv.override { inherit stdenv; }).overrideAttrs (final: prev: {
      passthru = drv.passthru;

      preBuild = ''
        makeFlagsArray+=(KCFLAGS="-I${clang}/resource-root/include -Wno-everything -march=armv8-a+crypto")
      '';

      nativeBuildInputs = prev.nativeBuildInputs
        ++ [ bintools-unwrapped clang ];

      # remove CC=stdenv.cc
      makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
    }));

  # derive a defconfig from the one provided by orangepi-build
  # this lets us utilize extraStructuredConfig
  defconfig = (applyOverrides (linuxManualConfig (common // {
    configfile =
      "${inputs.orangepi-build}/external/config/kernel/linux-6.1-sun50iw9-next.config";
    allowImportFromDerivation = false;
  }))).overrideAttrs (_: _: {
    name = "orangepi_zero2_defconfig";
    buildFlags = [ "savedefconfig" ];
    installPhase = "cp ./defconfig $out";
    preInstall = "";
    postInstall = "";
    dontFixup = true;
  });
  defconfigPatch = let dir = "arch/arm64/configs";
  in runCommand "defconfig-patch" { nativeBuildInputs = [ git ]; } ''
    mkdir -p ${dir}
    cp ${defconfig} ${dir}/${defconfig.name}
    git init
    git add ${dir}
    git diff --staged > $out
  '';

in (applyOverrides (buildLinux (args // common // {
  defconfig = defconfig.name;
  autoModules = false;
  structuredExtraConfig = with lib.kernel;
    {
      RTL8723DU = no;
    } // listToAttrs (map (attr: {
      name = attr;
      value = yes;
    }) [
      "DEVTMPFS"
      "CGROUPS"
      "INOTIFY_USER"
      "SIGNALFD"
      "TIMERFD"
      "EPOLL"
      "NET"
      "SYSFS"
      "PROC_FS"
      "FHANDLE"
      "CRYPTO_USER_API_HASH"
      "CRYPTO_HMAC"
      "CRYPTO_SHA256"
      "DMIID"
      "AUTOFS_FS"
      "TMPFS_POSIX_ACL"
      "TMPFS_XATTR"
      "SECCOMP"
    ]);

  kernelPatches = [
    {
      name = "nix-patches";
      patch = let
        patchesPath = ./patches;
        isPatchFile = name: value:
          value == "regular" && (lib.hasSuffix ".patch" name);
        patchFilePath = name: patchesPath + "/${name}";
      in map patchFilePath (lib.naturalSort (lib.attrNames
        (lib.filterAttrs isPatchFile (builtins.readDir patchesPath))));
    }
    {
      name = "defconfig";
      patch = defconfigPatch;
    }
  ];
} // (args.argsOverride or { })))).overrideAttrs (final: prev: {
  name = "k"; # stay under u-boot path length limit
  passthru = prev.passthru // {
    inherit defconfig defconfigPatch bintools-unwrapped;
  };
})

