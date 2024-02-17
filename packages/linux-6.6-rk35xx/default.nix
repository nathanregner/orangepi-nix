{ inputs, lib, pkgsBuildBuild, pkgsBuildTarget, runCommand, git, stdenv, ...
}@args:
with lib;
let
  inherit (pkgsBuildBuild) pkg-config ncurses;
  inherit (pkgsBuildTarget) linuxManualConfig;
  inherit (pkgsBuildBuild.llvmPackages) bintools-unwrapped clang;

  common = rec {
    version = "6.6.16";
    modDirVersion = version;
    extraMeta = {
      branch = versions.majorMinor version;
      # platforms = [ "aarch64-linux" ];
    };
    src = inputs.linux-orangepi-orange-pi-6-6-rk35xx;
    # use clang for simpler cross-compilation
    extraMakeFlags = [
      "WERROR=0"
      "LLVM=1"
      "ARCH=arm64"
      "CROSS_COMPILE=aarch64-none-linux-gnu-"
      # nativeBuildInputs doesn't get passed to the configfile derivation,
      # so set this manually...
      "LD=${bintools-unwrapped}/bin/ld.lld"
    ];
  };

  applyOverrides = (drv:
    (drv.override { inherit stdenv; }).overrideAttrs (final: prev: {
      passthru = drv.passthru;

      preBuild = ''
        makeFlagsArray+=(KCFLAGS="-I${clang}/resource-root/include -Wno-everything -march=armv8-a+crypto -Wno-error=unused-command-line-argument")
        makeFlagsArray+=(CFLAGS="-I${clang}/resource-root/include -Wno-everything -Wno-error=unused-command-line-argument")
      '';

      nativeBuildInputs = prev.nativeBuildInputs
        ++ [ bintools-unwrapped clang pkg-config ncurses ];

      # remove CC=stdenv.cc
      makeFlags = filter (flag: !(strings.hasPrefix "CC=" flag)) prev.makeFlags;
    }));

  # derive a defconfig from the one provided by orangepi-build
  # this lets us utilize extraStructuredConfig
  defconfig = (applyOverrides (linuxManualConfig (common // {
    configfile =
      "${inputs.orangepi-build}/external/config/kernel/linux-6.1-sun50iw9-next.config";
    allowImportFromDerivation = false;
  }))).overrideAttrs (final: prev: {
    name = "orangepi_zero2_defconfig";
    buildFlags = [ "savedefconfig" ];
    installPhase = "cp ./defconfig $out";
    preInstall = "";
    postInstall = "";
    dontFixup = true;
    nativeBuildInputs = prev.nativeBuildInputs;
  });

  kernel = ((applyOverrides (linuxManualConfig (common // {
    configfile = ./config;
    allowImportFromDerivation = true;

  } // (args.argsOverride or { })))).overrideAttrs (final: prev: {
    name = "k"; # stay under u-boot path length limit
    passthru = prev.passthru // {
      inherit defconfig defconfigPatch bintools-unwrapped;
      kernelArch = stdenv.hostPlatform.linuxArch;
    };
    postPatch = ''
      ${prev.postPatch or ""}
      substituteInPlace drivers/net/wireless/uwe5622/**/Makefile --replace "/lib/firmware" "/run/current-system/firmware"
    '';

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

