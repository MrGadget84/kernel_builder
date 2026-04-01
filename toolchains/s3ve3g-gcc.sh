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
    
    # Устанавливаем lzop (нужен для сжатия ядра)
    dnf install -y lzop
    
    cd "${maindir}"
    
    echo "Building in: $(pwd)"
    
    mkdir -p out
    
    # Создаём обёртку для gcc
    cat > scripts/gcc-wrapper.py << 'EOF'
#!/usr/bin/env python3
import sys
import os

if __name__ == '__main__':
    os.execvp(sys.argv[1], sys.argv[1:])
EOF
    chmod +x scripts/gcc-wrapper.py
    sed -i 's|scripts/gcc-wrapper.py|./scripts/gcc-wrapper.py|g' scripts/Makefile
    
    # Отключаем сборку dtc
    cat > scripts/dtc/Makefile << 'EOF'
hostprogs-y :=
always-y :=
clean-files :=
EOF
    mkdir -p out/scripts/dtc
    ln -sf /usr/bin/dtc out/scripts/dtc/dtc
    
    DEFCONFIG="$2"
    if [ -z "$DEFCONFIG" ]; then
      DEFCONFIG="cyanogenmod_s3ve3g_defconfig"
    fi
    
    echo "Using defconfig: $DEFCONFIG"
    
    if [ ! -f "arch/arm/configs/$DEFCONFIG" ]; then
      echo "ERROR: Defconfig $DEFCONFIG not found!"
      ls arch/arm/configs/ | head -20
      exit 1
    fi
    
    make O=out ARCH=arm "$DEFCONFIG"
    
    echo "Disabling ARM crypto modules that cause Thumb errors..."
    scripts/config --file out/.config --disable CRYPTO_AES_ARM_BS
    scripts/config --file out/.config --disable CRYPTO_AES_ARM
    scripts/config --file out/.config --disable CRYPTO_SHA1_ARM_NEON
    scripts/config --file out/.config --disable CRYPTO_SHA1_ARM
    scripts/config --file out/.config --disable CRYPTO_SHA256_ARM
    
    echo "Building kernel with ${NJOBS:-4} jobs..."
    make -j${NJOBS:-4} O=out ARCH=arm 2>&1 | tee build.log
    
    if [ -f out/arch/arm/boot/zImage ]; then
      export out_image="${maindir}/out/arch/arm/boot/zImage"
     # export out_dtb="${maindir}/out/arch/arm/boot/dt.img"
      export out_dtb="${maindir}/out/arch/${ARCH}/boot/msm8226-sec-s3ve3*.dtb"
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
