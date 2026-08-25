#!/bin/bash
#
# ReSukiSU & SuSFS

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash
git add . && git commit -am "drivers: KernelSU"
curl -LSs https://gitlab.com/simonpunk/susfs4ksu/-/raw/kernel-4.14/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch -o drivers/kernelsu/10_enable_susfs_for_ksu.patch
cd drivers/kernelsu
patch -p1 --fuzz=3 --ignore-whitespace < 10_enable_susfs_for_ksu.patch
if [ -f "supercall/dispatch.c" ]; then
  echo "[FIX] Injecting SuSFS v1.6.0 compatibility layers into dispatch.c..."
  sed -i '1s/^/#ifdef CONFIG_KSU_SUSFS\n#include <linux\/susfs.h>\n#define CMD_SUSFS_ADD_SUS_PATH_LOOP 0x9991\n#define CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS 0x9992\n#define CMD_SUSFS_ADD_SUS_MAP 0x9993\n#define CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING 0x9994\n#endif\n/' supercall/dispatch.c
fi
cd ../..
SUKI_DIR="drivers/kernelsu"
KSU_git_ver=$(cd $SUKI_DIR && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

patchesdir="$outside/ksu/hooks/"
suspatchesdir="$outside/ksu/sus/"

if [[ -d "$suspatchesdir" ]]; then
  for patch_file in "$suspatchesdir"/*.patch ; do
    patch -p1 < "$patch_file"
  done
else
  echo "patching susfs failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch ; do
    patch -p1 < "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [ -f "KernelSU/kernel/tools/inline_hook_check.mk" ]; then
  sed -i 's/\$(error/\$(warning/g' KernelSU/kernel/tools/inline_hook_check.mk
fi

find . -type f \( -name "Kbuild" -o -name "*.mk" -o -name "Makefile" \) -exec sed -i 's/\$(error/\$(warning/g' {} +
sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-suki${KSU_ver}-susfs\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nReSukiSU Enable! resukisu ver ${KSU_ver}" >> banner_append
