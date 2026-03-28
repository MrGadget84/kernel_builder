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
    
    cd "${maindir}"
    
    echo "Building in: $(pwd)"
    
    mkdir -p out
    
    # Устанавливаем dtc если нет
    if ! command -v dtc &> /dev/null; then
      echo "Installing dtc..."
      dnf install -y dtc
    fi
    
    # Исправляем gcc-wrapper.py
    if [ -f scripts/gcc-wrapper.py ]; then
      sed -i 's/print "\(.*\)"/print("\1")/g' scripts/gcc-wrapper.py
      sed -i 's/print \(.*\),/print(\1, end=" ")/g' scripts/gcc-wrapper.py
    fi
    
    # Отключаем сборку dtc, используем системный
    echo "Using system dtc"
    cat > scripts/dtc/Makefile << 'EOF'
hostprogs-y := dtc
always-y := $(hostprogs-y)

dtc-objs := dtc.o flattree.o fstree.o data.o livetree.o treesource.o srcpos.o util.o
dtc-objs += dtc-lexer.lex.o dtc-parser.tab.o

HOSTCFLAGS_dtc-lexer.lex.o := -I$(srctree)/scripts/dtc/libfdt
HOSTCFLAGS_dtc-parser.tab.o := -I$(srctree)/scripts/dtc/libfdt

$(obj)/dtc: $(addprefix $(obj)/,$(dtc-objs)) $(obj)/libfdt/libfdt.a
	$(HOSTCC) -o $@ $^

clean-files := dtc-lexer.lex.c dtc-parser.tab.c dtc-parser.tab.h
EOF
    
    # Копируем системный dtc в output
    mkdir -p out/scripts/dtc
    cp $(which dtc) out/scripts/dtc/dtc
    
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
    
    echo "Building kernel with ${NJOBS:-4} jobs..."
    make -j${NJOBS:-4} O=out ARCH=arm 2>&1 | tee build.log
    
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
