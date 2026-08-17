#!/bin/bash
#
# UwU

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash
git add . && git commit -am "drivers: KernelSU"
SUKI_DIR="drivers/kernelsu"
KSU_git_ver=$(cd $SUKI_DIR && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

patchesdir="$outside/ksu/sukisu/hooks/"
suspatchesdir="$outside/ksu/sukisu/sus/"

if [[ -d "$suspatchesdir" ]]; then
  for patch_file in "$suspatchesdir"/*.patch ; do
    patch -p1 --fuzz=3 --ignore-whitespace < "$patch_file"
  done
else
  echo "patching susfs failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch ; do
    patch -p1 --fuzz=3 --ignore-whitespace < "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [ -f "KernelSU/kernel/tools/inline_hook_check.mk" ]; then
  sed -i 's/\$(error/\$(warning/g' KernelSU/kernel/tools/inline_hook_check.mk
fi
find . -type f \( -name "Kbuild" -o -name "*.mk" -o -name "Makefile" \) -exec sed -i 's/\$(error/\$(warning/g' {} +
echo "[FIX] Absolutely all strict blocks downgraded to warnings!"

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-suki${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nIntegration ReSukiSU ver ${KSU_ver}" >> banner_append
