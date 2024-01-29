{ fetchFromGitHub, runCommand }:
let
  src = fetchFromGitHub {
    owner = "armbian";
    repo = "firmware";
    rev = "6b6f053f6089e08dd2a675cda1ec813de2e842e2";
    sha256 = "sha256-LAHKmv5UmJJeDRDHf1RZaAhlqsprEGuwSNYGT2TeZ4g=";
    sparseCheckout = [ "uwe5622" ];
  };
in runCommand "wcnmodem-firmware" {
  # WIFI drivers are jank and have their own loading mechanism that doesn't support compression...
  passthru = { compressFirmware = false; };
} ''
  mkdir -p $out/lib/firmware
  cp -r ${src}/uwe5622/* $out/lib/firmware/
''
