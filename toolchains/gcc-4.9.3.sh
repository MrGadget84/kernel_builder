#!/bin/bash
# GCC-4.9.3.sh - установка кросс-компилятора arm-eabi-gcc 4.9.3

set -e

INSTALL_DIR="/opt/gcc-4.9.3"
TOOLCHAIN_URL="https://releases.linaro.org/components/toolchain/binaries/4.9-2017.01/arm-linux-gnueabihf/gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf.tar.xz"
TARBALL="gcc-4.9.3.tar.xz"

sudo mkdir -p "$INSTALL_DIR"

if [ ! -f "$TARBALL" ]; then
    wget -O "$TARBALL" "$TOOLCHAIN_URL"
fi

sudo tar -xf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1

sudo ln -sf "$INSTALL_DIR/bin/arm-linux-gnueabihf-gcc" "$INSTALL_DIR/bin/arm-eabi-gcc"
sudo ln -sf "$INSTALL_DIR/bin/arm-linux-gnueabihf-g++" "$INSTALL_DIR/bin/arm-eabi-g++"
sudo ln -sf "$INSTALL_DIR/bin/arm-linux-gnueabihf-ld" "$INSTALL_DIR/bin/arm-eabi-ld"
sudo ln -sf "$INSTALL_DIR/bin/arm-linux-gnueabihf-ar" "$INSTALL_DIR/bin/arm-eabi-ar"

echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> ~/.bashrc
export PATH="$INSTALL_DIR/bin:$PATH"

rm -f "$TARBALL"

echo "Установлено. Проверка:"
arm-eabi-gcc --version
