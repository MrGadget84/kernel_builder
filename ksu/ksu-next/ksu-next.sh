#!/bin/bash
#
# white

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s legacy

KSU_git_ver=$(cd drivers/kernelsu && git rev-list --count HEAD)
KSU_ver=$(($KSU_git_ver + 10000 + 200))

patchesdir="$outside/ksu/ksu-next/patches/4.14/"

if [[ -d "$patchesdir" ]]; then
   for patch_file in "$patchesdir"/*.patch ; do
     patch -p1 < "$patch_file"
   done
 else
   echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
   exit 1
 fi

grep -q "obj-\$(CONFIG_KSU)" drivers/Makefile || echo 'obj-$(CONFIG_KSU) += kernelsu/' >> drivers/Makefile
grep -q "drivers/kernelsu/Kconfig" drivers/Kconfig || sed -i '/endmenu/i source "drivers/kernelsu/Kconfig"' drivers/Kconfig
sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-ksn${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nKernelSU-Next Version Enable, ksn ver ${KSU_ver}" >> banner_append
