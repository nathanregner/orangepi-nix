{ linuxManualConfig, args, ... }:
(linuxManualConfig
  ({ allowImportFromDerivation = false; } // args)).overrideAttrs
(final: prev: {
  buildFlags = [ "savedefconfig" ];
  installPhase = "cp ./defconfig $out";
})

