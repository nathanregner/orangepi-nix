{
  description = "Orange Pi Linux Kernels";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";

    orange-pi-5-10-rk3588 = {
      url = "github:orangepi-xunlong/linux-orangepi?ref=orange-pi-5.10-rk3588";
    };
  };

  outputs = { self, nixpkgs, flake-utils }: {
    # TODO: aarch64 support
    packages = flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec { default = self.packages.x86_64-linux.hello; });
  };
}
