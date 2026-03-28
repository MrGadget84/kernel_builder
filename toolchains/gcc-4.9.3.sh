#!/bin/bash
# toolchains/gcc-4.9.3.sh

set -e

case $1 in
  "setup" )
    # Установка компилятора
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
    
    export PATH="$INSTALL_DIR/bin:$PATH"
    echo "GCC 4.9.3 installed"
    arm-eabi-gcc --version
    ;;

  "build" )
    # Сборка ядра
    export ARCH=arm
    export SUBARCH=arm
    export CROSS_COMPILE=arm-eabi-
    export PATH="/opt/gcc-4.9.3/bin:$PATH"
    
    cd "${maindir}/kernel"
    
    # Исправляем gcc-wrapper.py для Python 3
    if [ -f scripts/gcc-wrapper.py ]; then
      sed -i 's/print "\(.*\)"/print("\1")/g' scripts/gcc-wrapper.py
      sed -i 's/print \(.*\),/print(\1, end=" ")/g' scripts/gcc-wrapper.py
      sed -i 's/print line,/print(line.decode("utf-8"), end="")/g' scripts/gcc-wrapper.py
      sed -i "s/print args\[0\] + ':'/print(args[0] + ':',/g" scripts/gcc-wrapper.py
      sed -i "s/print 'Is your PATH set correctly?'/print('Is your PATH set correctly?')/g" scripts/gcc-wrapper.py
    fi
    
    # Конфигурация и сборка
    make O=out ARCH=arm $2
    
    # Сборка с выводом ошибок
    make -j${NJOBS} O=out ARCH=arm 2>&1 | tee build.log
    
    # Сохраняем информацию о компиляторе
    arm-eabi-gcc --version > ${maindir}/${toolchain}.info 2>&1
    echo "Toolchain: GCC 4.9.3 (Linaro)" >> ${maindir}/${toolchain}.info
    
    # Проверяем результат
    if [ -f out/arch/arm/boot/zImage ]; then
      export out_image="${maindir}/kernel/out/arch/arm/boot/zImage"
      export out_dtb="${maindir}/kernel/out/arch/arm/boot/dt.img"
      echo "Build successful"
    else
      echo "Build failed: zImage not found"
      exit 1
    fi
    ;;
    
  * )
    echo "Usage: $0 {setup|build}"
    exit 1
    ;;
esac
