#!/usr/bin/bash
# Author: Ben Fairless <benfairless@gmail.com>
# Description: Quck reboot using kexec

# Load SHL functions.
# shellcheck disable=SC1091
source /usr/local/lib/shl
SELF=$(basename "${0}")
COMMAND="${*}"

################################################################################
################################### RUNTIME ####################################
################################################################################

# Print title summary
shl_intro 'Fast reboot for new kernels' | shl_log

# Check dependencies.
shl_require_root
shl_dependency kexec kexec-tools
shl_dependency kernel

# Check kernel versions
NEW_KERNEL=$(rpm -q --last kernel | sed -r 's/^kernel-(\S+).*/\1/')
CURRENT_KERNEL=$(uname -r)

if [[ "${NEW_KERNEL}" == "${CURRENT_KERNEL}" ]]; then
  shl_say "Latest installed kernel already applied." | shl_log SUCCESS
  echo "Current kernel: ${CURRENT_KERNEL}" | shl_log
  exit 1
else
  shl_title "A new kernel is available to be applied." | shl_log
  echo "Current kernel: ${CURRENT_KERNEL}" | shl_log
  echo "Latest kernel:  ${NEW_KERNEL}" | shl_log
fi

# If the 'apply' argument was used, reboot
if [[ "${COMMAND}" == 'apply' ]]; then
  # Set paths to new kernel and inital ram disk
  DELAY=${DELAY:-'3'}
  VMLINUZ="/boot/vmlinuz-${NEW_KERNEL}"
  INITRD="/boot/initramfs-${NEW_KERNEL}.img"
  if [[ -f ${VMLINUZ} ]] && [[ -f ${INITRD} ]]; then
    kexec -u # Clear any existing kexec config
    kexec -l "${VMLINUZ}" --initrd="${INITRD}" --reuse-cmdline
    [[ -f '/usr/bin/wall' ]] && wall "Rebooting for system upgrade."
    sleep "${DELAY}"
    systemctl kexec
  else
    shl_title "Kernel '${NEW_KERNEL}' not installed properly!" | shl_log ERROR
    echo "Could not find '${VMLINUZ}' or '${INITRD}'." | shl_log ERROR
    exit 1
  fi
else
  echo | shl_log
  shl_say "You can reboot using the new kernel by running '${SELF} apply'" | shl_log
  exit 0
fi
