#!/bin/bash
# toolchains/gcc-4.9.3.sh

set -e

case $1 in
  "setup" )
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
    echo "GCC installed:"
    arm-eabi-gcc --version
    ;;

  "build" )
    export ARCH=arm
    export SUBARCH=arm
    export CROSS_COMPILE=arm-eabi-
    export PATH="/opt/gcc-4.9.3/bin:$PATH"
    
    # maindir уже указывает на папку с ядром, не добавляем лишний /kernel
    echo "Current directory: ${maindir}"
    cd "${maindir}"
    
    echo "Now in: $(pwd)"
    echo "Checking defconfig directory:"
    ls -la arch/arm/configs/ | head -20
    
    # Исправляем gcc-wrapper.py
    if [ -f scripts/gcc-wrapper.py ]; then
      echo "Fixing gcc-wrapper.py for Python 3..."
      sed -i 's/print "\(.*\)"/print("\1")/g' scripts/gcc-wrapper.py
      sed -i 's/print \(.*\),/print(\1, end=" ")/g' scripts/gcc-wrapper.py
      sed -i "s/print '\(.*\)'/print('\1')/g" scripts/gcc-wrapper.py
      sed -i 's/print line,/print(line.decode("utf-8"), end="")/g' scripts/gcc-wrapper.py
    fi
    
    DEFCONFIG="$2"
    if [ -z "$DEFCONFIG" ]; then
      DEFCONFIG="cyanogenmod_s3ve3g_defconfig"
    fi
    
    echo "Using defconfig: $DEFCONFIG"
    
    if [ ! -f "arch/arm/configs/$DEFCONFIG" ]; then
      echo "ERROR: Defconfig $DEFCONFIG not found!"
      echo "Available defconfigs:"
      ls arch/arm/configs/
      exit 1
    fi
    
    make O=out ARCH=arm "$DEFCONFIG"
    
    echo "Building kernel..."
    make -j${NJOBS:-$(nproc)} O=out ARCH=arm 2>&1 | tee build.log
    
    arm-eabi-gcc --version > "${maindir}/${toolchain}.info" 2>&1
    
    if [ -f out/arch/arm/boot/zImage ]; then
      export out_image="${maindir}/out/arch/arm/boot/zImage"
      export out_dtb="${maindir}/out/arch/arm/boot/dt.img"
      echo "Build successful!"
      ls -lh out/arch/arm/boot/zImage
    else
      echo "Build failed!"
      exit 1
    fi
    ;;
    
  * )
    echo "Usage: $0 {setup|build} [defconfig]"
    exit 1
    ;;
esac
