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

if ! grep -q "int path_umount" fs/namespace.c; then
    cat << 'EOF' >> fs/namespace.c

int path_umount(struct path *path, int flags)
{
    struct mount *mnt = real_mount(path->mnt);
    int ret;

    if (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))
        return -EINVAL;
    if (!may_mount())
        return -EPERM;
    if (path->dentry != path->mnt->mnt_root)
        return -EINVAL;

    ret = do_umount(mnt, flags);

    dput(path->dentry);
    mntput_no_expire(mnt);
    return ret;
}
EXPORT_SYMBOL(path_umount);
EOF
fi

grep -q "obj-\$(CONFIG_KSU)" drivers/Makefile || echo 'obj-$(CONFIG_KSU) += kernelsu/' >> drivers/Makefile
grep -q "drivers/kernelsu/Kconfig" drivers/Kconfig || sed -i '/endmenu/i source "drivers/kernelsu/Kconfig"' drivers/Kconfig
sed -i '/int do_umount(/a int path_umount(struct path *path, int flags);' include/linux/fs.h
sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-ksn${KSU_ver}\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nKernelSU-Next Version Enable, ksn ver ${KSU_ver}" >> banner_append

# 7. Делаем коммит всех изменений перед сборкой
git add . && git commit -am "drivers: KernelSU Next integrated" || :
