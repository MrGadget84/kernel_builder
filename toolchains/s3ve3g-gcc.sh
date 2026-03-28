#!/bin/bash
# toolchains/s3ve3g-gcc.sh

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
    
    # Создаём симлинки для всех утилит
    cd "$INSTALL_DIR/bin"
    for tool in arm-linux-gnueabihf-*; do
      new_tool="${tool/arm-linux-gnueabihf/arm-eabi}"
      sudo ln -sf "$tool" "$new_tool"
    done
    cd -
    
    export PATH="$INSTALL_DIR/bin:$PATH"
    echo "GCC installed:"
    arm-eabi-gcc --version
    ;;

  "build" )
    export ARCH=arm
    export SUBARCH=arm
    export CROSS_COMPILE=arm-eabi-
    export PATH="/opt/gcc-4.9.3/bin:$PATH"
    
    cd "${maindir}"
    
    echo "Building in: $(pwd)"
    
    mkdir -p out
    
    # Исправляем gcc-wrapper.py
    if [ -f scripts/gcc-wrapper.py ]; then
      echo "Fixing gcc-wrapper.py for Python 3..."
      sed -i 's/print "\(.*\)"/print("\1")/g' scripts/gcc-wrapper.py
      sed -i 's/print \(.*\),/print(\1, end=" ")/g' scripts/gcc-wrapper.py
    fi
    
    # Исправляем dtc
    echo "Fixing dtc yylloc issue..."
    if [ -f scripts/dtc/dtc-lexer.l ]; then
      sed -i 's/extern YYLTYPE yylloc;/YYLTYPE yylloc;/' scripts/dtc/dtc-lexer.l
      cd scripts/dtc
      flex -o dtc-lexer.lex.c dtc-lexer.l 2>/dev/null || true
      bison -o dtc-parser.tab.c dtc-parser.y 2>/dev/null || true
      cd ../..
    fi
    
    DEFCONFIG="$2"
    if [ -z "$DEFCONFIG" ]; then
      DEFCONFIG="cyanogenmod_s3ve3g_defconfig"
    fi
    
    echo "Using defconfig: $DEFCONFIG"
    
    if [ ! -f "arch/arm/configs/$DEFCONFIG" ]; then
      echo "ERROR: Defconfig $DEFCONFIG not found!"
      echo "Available defconfigs:"
      ls arch/arm/configs/ | grep -E "(s3ve3g|cyanogenmod)"
      exit 1
    fi
    
    make O=out ARCH=arm "$DEFCONFIG"
    
    echo "Building kernel with ${NJOBS:-$(nproc)} jobs..."
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
