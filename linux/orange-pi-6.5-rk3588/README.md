## Kernel Sources

[Sebastian Reichel's Kernel Branch](https://git.kernel.org/pub/scm/linux/kernel/git/sre/linux-misc.git)

[rk3588s-orangepi-5.dts](https://github.com/armbian/build/blob/f7c410de2f60b24e130c24b8d1f87ae4a7671aed/patch/kernel/rockchip-rk3588-edge/dt/rk3588s-orangepi-5.dts) from `armbian-build`

[.config](https://github.com/armbian/build/blob/9a0908f9babdb7bb3aa71feeecd56f6e4cbdd901/config/kernel/linux-rockchip-rk3588-edge.config) from `armbian-build`

## Kernel Hacking

```shell
mkdir build
cd cd build
cp flake_path/linux/orange-pi-6.5-rk3588/.config .config

# make sure to build with a different output path like nix does
ln -s path_to_linux source
cd source

nix develop flake_path#orange-pi-6-5-rk3588

make $makeFlags "${makeFlagsArray[@]}" -j24 O=..
```
