# sushi
Just run commands. Suck less.

## Install
To compile it you will need to first install fasm:
```sh
# Debian / Ubuntu
sudo apt install fasm

# Arch
sudo pacman -S fasm

# Gentoo
eselect repository add piniverlay git https://github.com/pinicarus/gentoo-overlay.git
emaint sync -r piniverlay
emerge --ask fasm 
```

After this, clone the repo and compile it (+ install it if you want):
```sh
git clone https://github.com/kickhead13/sushi.git
cd sushi
make
./sushi
# or install it to ~/opt/bin/sushi
make && make install
```

## Usage
```sh
 :3 08:44:55 ~/odiv/sushi (main)  sushi
git remote -v
origin	https://github.com/kickhead13/sushi.git (fetch)
origin	https://github.com/kickhead13/sushi.git (push)
```
