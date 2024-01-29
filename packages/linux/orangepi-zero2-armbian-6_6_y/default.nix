{ inputs, lib, pkgsBuildBuild, pkgsBuildTarget, pkgsHostTarget, runCommand, git
, fetchFromGitHub, fetchgit, llvmPackages, ... }@args:
with lib;
let
  inherit (pkgsBuildBuild) pkg-config ncurses qt5;
  inherit (pkgsBuildTarget) linuxManualConfig;
  inherit (pkgsBuildTarget.llvmPackages) bintools-unwrapped clang;

  stdenv = pkgsBuildTarget.llvmPackages.stdenv // {
    hostPlatform = pkgsBuildTarget.llvmPackages.stdenv.targetPlatform;
  };

  common = rec {
    version = "6.6.17";
    modDirVersion = version;
    extraMeta = {
      branch = versions.majorMinor version;
      # platforms = [ "aarch64-linux" ];
    };
    src = inputs.linux-orangepi-zero2-armbian-6_6_y;
  };

  applyOverrides = (drv:
    (drv.override { inherit stdenv; }).overrideAttrs (final: prev: {
      passthru = drv.passthru;

      preBuild = ''
        makeFlagsArray+=(KCFLAGS="-I${clang}/resource-root/include -Wno-everything -march=armv8-a+crypto -Wno-error=unused-command-line-argument")
        makeFlagsArray+=(CFLAGS="-I${clang}/resource-root/include -Wno-everything -Wno-error=unused-command-line-argument")
      '';

      # discard [ buildPackages.stdenv.cc ]
      depsBuildBuild = [ ];

      nativeBuildInputs = prev.nativeBuildInputs
        ++ [ pkg-config ncurses bintools-unwrapped stdenv.cc ];

      # PKG_CONFIG_PATH =
      #   "${ncurses.dev}/lib/pkgconfig:${qt5.qtbase.dev}/lib/pkgconfig";
      # QT_QPA_PLATFORM_PLUGIN_PATH =
      #   "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";
      # QT_QPA_PLATFORMTHEME = "qt5ct";

      # remove CC=stdenv.cc
      makeFlags = (filter (flag:
        !(strings.hasPrefix "CC=" flag || strings.hasPrefix "HOSTCC=" flag
          || strings.hasPrefix "HOSTLD=" flag
          || strings.hasPrefix "ARCH=" flag)) prev.makeFlags) ++ [
            "HOSTCC=${stdenv.cc}/bin/clang"
            "HOSTLD=${stdenv.cc}/bin/ld"
            "CC=${stdenv.cc}/bin/clang"
            "ARCH=arm64"
            "CROSS_COMPILE=aarch64-unknown-linux-gnu-"
          ];
    }));

  kernel = ((applyOverrides (linuxManualConfig (common // {
    configfile = ./config;
    allowImportFromDerivation = true;
  } // (args.argsOverride or { })))).overrideAttrs (final: prev: {
    name = "k"; # stay under u-boot path length limit
    passthru = prev.passthru // {
      inherit bintools-unwrapped;
      kernelArch = stdenv.hostPlatform.linuxArch;
    };
    # SHELL=bash nix develop ... $linkConfig
    linkConfig = "ln -srf ${final.passthru.configfile} .config";
  }));

  requiredKernelConfig = [
    "AUTOFS_FS"
    "CGROUPS"
    "CRYPTO_HMAC"
    "CRYPTO_SHA256"
    "CRYPTO_USER_API_HASH"
    "DEVTMPFS"
    # "DMIID"
    "EPOLL"
    "FHANDLE"
    "INOTIFY_USER"
    "NET"
    "PROC_FS"
    "SECCOMP"
    "SIGNALFD"
    "SYSFS"
    "TIMERFD"
    "TMPFS_POSIX_ACL"
    "TMPFS_XATTR"
  ];
  actual = lib.genAttrs requiredKernelConfig
    (name: lib.attrsets.attrByPath [ "CONFIG_${name}" ] "unset" kernel.config);
  invalid = lib.filterAttrs (name: value: value != "y") actual;

in assert lib.asserts.assertMsg (invalid == { })
  "Invalid kernel config options: ${
    lib.concatStringsSep ", "
    (lib.mapAttrsToList (name: value: "${name} = ${value}") invalid)
  }";

kernel // {
  # we don't need EFI - trick nixpkgs into thinking it's enabled...
  config = kernel.config // { CONFIG_DMIID = "y"; };
}

