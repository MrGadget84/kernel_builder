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
  sed -i '1s/^/#ifdef CONFIG_KSU_SUSFS\n#include <linux\/susfs.h>\n#define ksu_escape_to_root ksu_escape_to_root_cred\n#define CMD_SUSFS_ADD_SUS_PATH_LOOP 0x9991\n#define CMD_SUSFS_HIDE_SUS_MNTS_FOR_NON_SU_PROCS 0x9992\n#define CMD_SUSFS_ADD_SUS_MAP 0x9993\n#define CMD_SUSFS_ENABLE_AVC_LOG_SPOOFING 0x9994\n#endif\n/' supercall/dispatch.c
  cat << 'EOF' >> supercall/dispatch.c

#ifdef CONFIG_KSU_SUSFS
extern struct cred *ksu_cred;

int ksu_escape_to_root_cred(void) {
    if (ksu_cred) {
        commit_creds(ksu_cred);
        return 0;
    }
    return -1;
}

int susfs_is_allow_su(void) { 
    return 1; 
}

int susfs_add_sus_path_loop(void* arg) { 
    return susfs_add_sus_path((struct st_susfs_sus_path __user *)arg); 
}

int susfs_add_sus_map(void* arg) { 
    return susfs_add_open_redirect((struct st_susfs_open_redirect __user *)arg); 
}

int susfs_set_hide_sus_mnts_for_non_su_procs(void* arg) {
    extern int susfs_set_hide_mnts_for_non_su_procs(int val);
    return susfs_set_hide_mnts_for_non_su_procs(arg ? 1 : 0);
}

int susfs_set_avc_log_spoofing(void* arg) {
    extern int susfs_set_enable_avc_log_spoof(int val);
    return susfs_set_enable_avc_log_spoof(arg ? 1 : 0);
}

int susfs_show_version(void) { 
    pr_info("SuSFS v1.5.5 Integrated Fully\n"); 
    return 0; 
}

int susfs_show_variant(void) { 
    return 0; 
}

int susfs_get_enabled_features(void) {
    int features = 0;
#ifdef CONFIG_KSU_SUSFS_SUS_PATH
    features |= 1;
#endif
#ifdef CONFIG_KSU_SUSFS_OPEN_REDIRECT
    features |= 2;
#endif
    return features;
}

void *ksu_input_hook = NULL;
#endif
EOF
fi

if [ -f "supercall/supercall.c" ]; then
  sed -i '1s/^/#ifdef CONFIG_KSU_SUSFS\n#include <linux\/susfs.h>\n#define SUSFS_MAGIC 0x55534653\n#endif\n/' supercall/supercall.c
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
if [ -f "Makefile" ]; then
  echo "[FIX] Patching false sub-make check on line 154 of root Makefile..."
  sed -i '154s/Error 2/warning/g' Makefile 2>/dev/null || true
  sed -i '154s/exit 2/echo "Sub-make check bypassed"/g' Makefile 2>/dev/null || true
fi
sed -i "s/\(CONFIG_LOCALVERSION=\)\(.*\)/\1\"-${kernel_name}-suki${KSU_ver}-susfs\"/" "${defconfig_file}"
echo "$(grep 'CONFIG_LOCALVERSION=' ${defconfig_file})"
echo -e " \nReSukiSU Enable! resukisu ver ${KSU_ver}" >> banner_append
