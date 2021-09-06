#!/usr/bin/env bash
#
# Set up and initialize the target controller
#
CIJ_TEST_NAME="$(basename "${BASH_SOURCE[0]}")"
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

hook::spdk_nvmf_target_enter() {
  if [[ ! -v NVMEF_TARGET_XNVME_REPOS_PATH ]]; then
    cij::err "spdk_nvmf_target_enter: Missing: NVMEF_TARGET_XNVME_REPOS_PATH"
    return 1
  fi
  if [[ ! -v NVMEF_TRANSPORT ]]; then
    cij::err "spdk_nvmf_target_enter: Missing: NVMEF_TRANSPORT"
    return 1
  fi
  if [[ ! -v NVMEF_TARGET_ADDR ]]; then
    cij::err "spdk_nvmf_target_enter: Missing: NVMEF_TARGET_ADDR"
    return 1
  fi
  if [[ ! -v NVMEF_TARGET_PORT ]]; then
    cij::err "spdk_nvmf_target_enter: Missing: NVMEF_TARGET_PORT"
    return 1
  fi
  if [[ ! -v PCI_DEV_NAME ]]; then
    cij::err "spdk_nvmf_target_enter: Missing: PCI_DEV_NAME"
    return 1
  fi

  local spdk_path="${NVMEF_TARGET_XNVME_REPOS_PATH}/third-party/spdk/repos"

  SSH_HOST="${NVMEF_TARGET_SSH_HOST}"; export SSH_HOST
  SSH_PORT="${NVMEF_TARGET_SSH_PORT}"; export SSH_HOST
  local rpc="${spdk_path}/scripts/rpc.py"
  local nqn="nqn.2020-06.io.spdk:cnode1"

  cij::info "hook:spdk_nvmf_target_enter: Setting up NVMeOF target"

  # Load xnvme SPDK driver
  if ! cij::cmd "HUGEMEM=${HUGEMEM} xnvme-driver"; then
    cij::err "spdk_nvmf_target_enter: failed SPDK initialization"
    return 1
  fi
  # Start SPDK target controller
  if ! cij::cmd "screen -S fabrics -dm bash -c ${spdk_path}/build/bin/nvmf_tgt -e 0x10"; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi

  sleep 3       # wait for the target to initialize

  # Create Transport
  if ! cij::cmd "${rpc} nvmf_create_transport -t ${NVMEF_TRANSPORT} -u 16384 -p 8 -c 8192"; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi

  # Attach controller
  if ! cij::cmd "${rpc} bdev_nvme_attach_controller -b Nvme0 -t PCIe -a ${PCI_DEV_NAME}"; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi

  # Create Subsystem with two namespaces NVM(Nvme0n1) and ZNS(Nvme0n2)
  if ! cij::cmd "${rpc} nvmf_create_subsystem ${nqn} -a -s SPDK00000000000001 -d SPDK_Controller1"; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi
  if ! cij::cmd "${rpc} nvmf_subsystem_add_ns ${nqn} Nvme0n1" ; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi
  if [[ "${NVME_NSTYPE}" == "zoned" ]]; then
    if ! cij::cmd "${rpc} nvmf_subsystem_add_ns ${nqn} Nvme0n2"; then
      cij::err "spdk_nvmf_target_enter: failed fabrics setup"
      return 1
    fi
  fi

  # Add listener
  if ! cij::cmd "${rpc} nvmf_subsystem_add_listener ${nqn} -t ${NVMEF_TRANSPORT} -a ${NVMEF_TARGET_ADDR} -s ${NVMEF_TARGET_PORT}"; then
    cij::err "spdk_nvmf_target_enter: failed fabrics setup"
    return 1
  fi

  return 0
}

hook::spdk_nvmf_target_enter
exit $?
