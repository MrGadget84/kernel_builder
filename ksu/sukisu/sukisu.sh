#!/bin/bash
#
# UwU

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/MrGadget84/MySukiSU/main/kernel/setup.sh" | bash
git add . && git commit -am "drivers: KernelSU"
SUKI_DIR="drivers/kernelsu"
KSU_git_ver=$(cd $SUKI_DIR && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

echo 'CONFIG_KSU_MULTI_MANAGER_SUPPORT=y' >> "${defconfig_file}"
patchesdir="$outside/ksu/sukisu/hooks/"
suspatchesdir="$outside/ksu/sukisu/sus/"

if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch ; do
    patch -p1 < "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [[ -d "$suspatchesdir" ]]; then
  for patch_file in "$suspatchesdir"/*.patch ; do
    patch -p1 < "$patch_file"
  done
else
  echo "patching susfs failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-MySukiSU${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nincludes MySukiSU ${KSU_ver}" >> banner_append
echo -e " \nincludes SuSFS Backport v2.2" >> banner_append
echo -e " \nincludes NoMount v2.1.1" >> banner_append
