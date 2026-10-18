#!/bin/bash
#
# An era has passed, ResukiSU is no more-only BakaSU remains.

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/$1env"

curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash
git add . && git commit -am "drivers: KernelSU"
SUKI_DIR="drivers/kernelsu"
KSU_git_ver=$(cd $SUKI_DIR && git rev-list --count HEAD)
KSU_ver=$KSU_git_ver

patchesdir="$outside/ksu/hooks/"

echo 'CONFIG_KSU_MULTI_MANAGER_SUPPORT=y' >> "${defconfig_file}"
echo 'CONFIG_KPM=y' >> "${defconfig_file}"
echo 'CONFIG_KALLSYMS=y' >> "${defconfig_file}"
echo 'CONFIG_KALLSYMS_ALL=y' >> "${defconfig_file}"
if [[ -d "$patchesdir" ]]; then
  for patch_file in "$patchesdir"/suki-kernel-4.14.patch ; do
    patch -p1 < "$patch_file"
  done
else
  echo "patching ksu failed, the kernel version you want to patch doesnt have patches here yet"
  exit 1
fi

sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-ksu${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nincludes SukiSU Ultra, ver ${KSU_ver}" >> banner_append
echo -e " \nincludes NoMount v2.1.0" >> banner_append
