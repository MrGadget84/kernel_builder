#!/bin/bash
#
# WhiteSU & SuSFS New

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/White-Society/KernelSU/master/kernel/setup.sh" | bash -s master
git add . && git commit -am "drivers: KernelSU"
KOW_DIR="drivers/kernelsu"
KSU_git_ver=$(cd $KOW_DIR && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

patchesdir="$outside/ksu/hooks/"
#suspatchesdir="$outside/ksu/sus/"

if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch ; do
    git am "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

#echo 'CONFIG_KSU_SUSFS=y' >> "${defconfig_file}"
#if [[ -d "$suspatchesdir" ]]; then
#  for patch_file in "$suspatchesdir"/*.patch ; do
#    git am "$patch_file"
#  done
#else
#  echo "patching ksu susfs failed, the kernel version you want to patch doesnt have patches here yet"
#  exit 1
#fi

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-ksu${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nincludes Root My WKP ${KSU_ver}" >> banner_append
echo -e " \nincludes NoMount" >> banner_append
#echo -e " \nincludes SuSFS" >> banner_append
