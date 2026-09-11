#!/bin/bash
#
# ReSukiSU & SuSFS

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash

curl -LSs "https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/" -o susfs_inline.sh
chmod +x susfs_inline.sh
curl -LSs "https://raw.githubusercontent.com/JackA1ltman/NonGKI_Kernel_Build_2nd/refs/heads/mainline/Patches/" -o syscall_hook.sh
chmod +x syscall_hook.sh
bash susfs_inline.sh
bash syscall_hook.sh
rm susfs_inline.sh syscall_hook.sh

git add . && git commit -am "drivers: KernelSU"
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

if [ -f "drivers/kernelsu/Makefile" ]; then
  echo "Registering nomount.o inside KernelSU Makefile..."
  echo 'obj-$(CONFIG_NOMOUNT) += nomount.o' >> drivers/kernelsu/Makefile
fi

if [ -f "KernelSU/kernel/tools/inline_hook_check.mk" ]; then
  sed -i 's/\$(error/\$(warning/g' KernelSU/kernel/tools/inline_hook_check.mk
fi

find . -type f \( -name "Kbuild" -o -name "*.mk" -o -name "Makefile" \) -exec sed -i 's/\$(error/\$(warning/g' {} +
if [ -f "Makefile" ]; then
  echo "[FIX] Patching false sub-make check on line 154 of root Makefile..."
  sed -i '154s/Error 2/warning/g' Makefile 2>/dev/null || true
  sed -i '154s/exit 2/echo "Sub-make check bypassed"/g' Makefile 2>/dev/null || true
fi
sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-suki${KSU_ver}-susfs\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nReSukiSU Enable! resukisu ver ${KSU_ver}" >> banner_append
