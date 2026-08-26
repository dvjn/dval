# [dv]jn's [a]rtix [l]inux

## prerequisites

a booted artix install, with partitions, fstab, locale, kernel and bootloader
already done, plus:

- a user account with `sudo` configured
- network

## bootstrap

```sh
sudo pacman -S --needed git base-devel
git clone https://github.com/dvjn/dval ~/.local/share/dval
cd ~/.local/share/dval
./dval bootstrap desktop
```

## updates

```sh
dval update
```

