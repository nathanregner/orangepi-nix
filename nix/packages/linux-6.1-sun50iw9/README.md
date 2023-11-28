## Kernel Config

```shell
cat /proc/config.gz | gunzip > running.config
cp running.config .config
make -j24 ARCH=arm64 CROSS_COMPILE=aarch64-unknown-linux-gnu- prepare modules_prepare
make savedefconfig 
cp defconfig ...
```

## Kernel Hacking

```shell
cd path_to_linux
nix develop path_to_flake#packages.aarch64-linux.cross.linux_orange-pi-5_16-sun50iw9
cp .config .config
# make sure to build with a different output path like nix does
make $makeFlags "${makeFlagsArray[@]}" -j24 O=.. prepare modules_prepare
make $makeFlags "${makeFlagsArray[@]}" -j24 O=.. M=drivers/net/wireless
```
