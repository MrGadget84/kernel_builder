#!/bin/bash
#
# hdjsjfjjwufbeizihfjejzf

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/White-Society/WhiteSU/legacy/kernel/setup.sh" | bash -s legacy
git add . && git commit -am "drivers: KernelSU"
KSU_git_ver=$(cd WhiteSU && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

patchesdir="$outside/ksu/ksu-next/patches/"
suspatchesdir="$outside/ksu/ksu-next/sus_patches/"

echo 'CONFIG_KSU_EXTRAS=y' >> "${defconfig_file}"
echo '# CONFIG_KSU_SUSFS_TRY_UMOUNT is not set' >> "${defconfig_file}"
if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/*.patch ; do
    git am "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

if [[ -d "$suspatchesdir" ]]; then
  for patch_file in "$suspatchesdir"/*.patch ; do
    git am "$patch_file"
  done
else
  echo "patching ksu susfs failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-ks${KSU_ver}sus\"/" "${defconfig_file}"

echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"

echo -e " \nincludes WhiteSU, ver ${KSU_ver}" >> banner_append
echo -e " \nincludes SuSFS v2.1.0" >> banner_append

