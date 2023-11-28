{ inputs, runCommand }:
let src = inputs.orangepi-firmware;
in runCommand "wcnmodem-firmware" {
  # WIFI drivers are jank and have their own loading mechanism that doesn't support compression...
  passthru = { compressFirmware = false; };
} ''
  mkdir -p $out/lib/firmware/
  cp ${src}/wcnmodem.bin $out/lib/firmware/
  cp ${src}/wifi_2355b001_1ant.ini $out/lib/firmware/
''
