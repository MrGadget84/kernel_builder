#!/bin/bash
# install_gcc_4.9.3.sh – установка кросс-компилятора GCC 4.9.3 для ARM (cortex-a9)
# Основано на toolchain от FriendlyARM [citation:3][citation:4]

set -e  # прерывать скрипт при любой ошибке

TOOLCHAIN_URL="https://github.com/friendlyarm/prebuilts/raw/master/gcc-x64/arm-cortexa9-linux-gnueabihf-4.9.3.tar.xz"
INSTALL_DIR="/opt/FriendlyARM/toolchain/4.9.3"
TARBALL="arm-cortexa9-linux-gnueabihf-4.9.3.tar.xz"

echo "=== Установка ARM toolchain GCC 4.9.3 для сборки ядра s3ve3g ==="

# Проверка: система должна быть 64-битной Linux
if [ "$(uname -m)" != "x86_64" ]; then
    echo "Ошибка: этот toolchain предназначен для 64-битных систем x86_64."
    exit 1
fi

# Создаём директорию для установки (требуются права sudo)
echo "Создаю директорию $INSTALL_DIR (требуется sudo)..."
sudo mkdir -p "$INSTALL_DIR"

# Скачиваем архив, если его нет
if [ ! -f "$TARBALL" ]; then
    echo "Скачиваю toolchain..."
    wget -O "$TARBALL" "$TOOLCHAIN_URL"
else
    echo "Архив $TARBALL уже есть, пропускаю загрузку."
fi

# Распаковываем в целевую директорию
echo "Распаковываю в $INSTALL_DIR (требуется sudo)..."
sudo tar xf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1

# Настраиваем PATH для текущей сессии
export PATH="$INSTALL_DIR/bin:$PATH"
echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> ~/.bashrc
echo "export GCC_COLORS=auto" >> ~/.bashrc

# Очистка
rm -f "$TARBALL"

echo "=== Установка завершена ==="
echo "Проверьте версию компилятора, выполнив: arm-linux-gcc --version"
echo "Чтобы изменения PATH вступили в силу в текущем окне, выполните: source ~/.bashrc"
