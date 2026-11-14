#!/bin/bash

set -o pipefail

export maindir="$(pwd)"
export outside="${maindir}/.."
source "${outside}/${2}env"

[ -z "$NJOBS" ] && export NJOBS=$(nproc --all) || :

# Apply compatibility fixes to the disposable kernel checkout only.
# No kernel source repository is changed by this builder.
if [[ -f include/linux/netdevice.h ]] && grep -q 'read_pnet_rcu(&dev->nd_net)' include/linux/netdevice.h; then
  if ! grep -q 'read_pnet_rcu' include/net/net_namespace.h 2>/dev/null; then
    sed -i 's/read_pnet_rcu(\&dev->nd_net)/read_pnet(\&dev->nd_net)/' include/linux/netdevice.h
  fi
fi

pack() {
  if [ ! -d "${zipper}" ]; then
    git clone "${zipper_repo}" -b "${zipper_branch}" "${zipper}" --single-branch --depth=1 || exit 1
    cd "${zipper}" || exit 1
  else
    cd "${zipper}" || exit 1
    git reset --hard
    git checkout "${zipper_branch}"
    git fetch origin "${zipper_branch}"
    git reset --hard "origin/${zipper_branch}"
  fi

  cp -af "${out_image}" "${zipper}/Image.gz"
  cp -af "${out_dtb}" "${zipper}/dtb"

  mkdir -p "${zipper}/modules/system/lib/modules/"
  find "${maindir}/out" -name '*.ko' > module_list.txt
  if [ -s module_list.txt ]; then
    xargs -r -d '\n' cp -v -t "${zipper}/modules/system/lib/modules/" < module_list.txt
  fi

  if [ -e "${maindir}/banner_append" ]; then
    cat "${maindir}/banner_append" >> "${zipper}/banner"
    if grep -q KernelSU "${maindir}/banner_append"; then
      sed -i 's/do.skipmagisk=0/do.skipmagisk=1/g' "${zipper}/anykernel.sh" || :
    fi
  fi
  zip -r9 "$1" ./* -x .git README.md ./*placeholder
  if command -v apksigner >/dev/null 2>&1 && apksigner version >/dev/null 2>&1 && [ -f "$SIGN_PK8" ] && [ -f "$SIGN_PEM" ]; then
    apksigner sign --min-sdk-version 30 --key "$SIGN_PK8" --cert "$SIGN_PEM" "$1" && SIGNED=1
  fi
  rm -f "${maindir}/banner_append" "${out_image}"
  cd "${maindir}"
}

for toolchain in $1; do
  bash -x "${outside}/toolchains/${toolchain}.sh" setup || exit 1

  BUILD_START=$(date +"%s")
  export CUR_TOOLCHAIN="${toolchain}"

  if [[ "${config_mode}" == "LumiROM" ]]; then
    echo "Preparing LumiROM A32 config (profile: ${KERNEL_PROFILE})"
    mkdir -p out
    merge_args=(
      -m
      -O out
      "${CONFIG_DIR}/mt6768_slm_defconfig"
      "${CONFIG_DIR}/a32_00_defconfig"
      "${CONFIG_DIR}/a32.config"
      "${CONFIG_DIR}/ksu.config"
    )
    if [[ -n "${profile_config}" ]]; then
      merge_args+=("${profile_config}")
    fi
    scripts/kconfig/merge_config.sh "${merge_args[@]}" || exit 1

    # RustUH RKP/KDP is incompatible with the vendor UH_RKP call sites in
    # this kernel tree. Disable only the RustUH options for this build.
    scripts/config --file out/.config \
      -d RUSTUH_RKP \
      -d RUSTUH_RKP_TEST \
      -d RUSTUH_KDP \
      -d RUSTUH_KDP_CRED \
      -d RUSTUH_KDP_NS \
      -d RUSTUH_KDP_TEST
    make O=out ARCH="${ARCH}" SUBARCH="${SUBARCH}" olddefconfig || exit 1
    toolchain_defconfig="olddefconfig"
  else
    toolchain_defconfig="${defconfig}"
  fi

  bash -x "${outside}/toolchains/${toolchain}.sh" build "${toolchain_defconfig}" || exit 1

  if [ -e "${out_image}" ]; then
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    pack "${zip_name}"
    echo "build succeeded in $((DIFF / 60))m, $((DIFF % 60))s" > "${zip_name}.info"
    echo "md5: <code>$(md5sum "${zip_name}" | cut -d' ' -f1)</code>" >> "${zip_name}.info"
    echo "compiler: $(cat "${toolchain}.info")" >> "${zip_name}.info"
    if [ "$SIGNED" = "1" ]; then
      echo "signed by <code>apksigner sign --min-sdk-version 30 --key $SIGN_PK8 --cert $SIGN_PEM</code>" >> "${zip_name}.info"
    fi

    echo "build succeeded in $((DIFF / 60))m, $((DIFF % 60))s" > "${toolchain}.log.info"
    echo "ak3 zip file: <code>${zip_name}</code>" >> "${toolchain}.log.info"
    echo "compiler: $(cat "${toolchain}.info")" >> "${toolchain}.log.info"
  else
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    echo "build failed in $((DIFF / 60))m, $((DIFF % 60))s" > "${toolchain}.log.info"
    echo "compiler: $(cat "${toolchain}.info")" >> "${toolchain}.log.info"
    exit 1
  fi
done
