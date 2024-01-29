with import <nixpkgs> { };
(pkgs.buildFHSUserEnv {
  name = "kernel-build-env";
  targetPkgs = pkgs:
    (with pkgs;
      [
        bc
        bison
        flex
        gnumake
        llvmPackages.bintools-unwrapped
        llvmPackages.clang
        ncurses
        openssl
        pkg-config
      ] ++ pkgs.linux.nativeBuildInputs);
  runScript = pkgs.writeScript "init.sh" ''
    export ARCH=arm64
    export LLVM=1
    export hardeningDisable=all
    export CROSS_COMPILE=aarch64-unknown-linux-gnu-
    export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkgconfig"
    exec bash
  '';
}).env
