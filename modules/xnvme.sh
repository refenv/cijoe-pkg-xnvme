#!/usr/bin/env bash
#
# CIJOE module to verify environment variables for xNVMe testcases
#
# For more information about xNVMe, see: https://xnvme.io/
#
# For documentation of parameters / variables.
#
# xnvme::env    - Checks environment for module parameters
# xnvme::fioe   - Runs fio with the xNVMe fio IO Engine
#
xnvme::env() {
  if ! ssh::env; then
    cij::err "xnvme::env - Invalid SSH ENV."
    return 1
  fi

  : "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"
  export XNVME_SHARE_ROOT

  : "${XNVME_LIB_ROOT:=/usr/lib}"
  export XNVME_LIB_ROOT

  return 0
}

#
# Uses:
# - xnvme::env
# - XNVME_URI
# - CMD_PREFIX (optional)
# - XNVME_SHARE_ROOT
# - XNVME_LIB_ROOT
#
xnvme::fioe() {
  if [[ -z "$1" || -z "$2" ]]; then
    cij::err "usage: xnvme::fioe('fio-script.fname', 'ioengine_name')"
    cij::err " or"
    cij::err "usage: xnvme::fioe('fio-script.fname', 'ioengine_name', 'section')"
    return 1
  fi

  if ! xnvme::env; then
    cij::err "xnvme:fio_compare: invalid xNVMe environment"
    return 1
  fi

  : "${CMD_PREFIX:=taskset -c 1 perf stat}"
  : "${FIO_BIN:=fio}"

  local script_fname=$1
  local ioengine_name=$2
  local section=$3
  local output_fpath=$4

  local jobfile="${XNVME_SHARE_ROOT}/${script_fname}"
  local _cmd

  if ! ssh::cmd "[[ -f \"${jobfile}\" ]]"; then
    cij::err "xnvme:fioe: '${jobfile}' does not exist!"
    return 1
  fi

  _cmd="${CMD_PREFIX} ${FIO_BIN} ${jobfile}"
  _cmd="${_cmd} --section=${section}"

  # Add the special-sauce for the external xNVMe fio engine
  if [[ "$ioengine_name" == *"xnvme"* ]]; then
    : "${XNVME_URI:?Must be set and non-empty}"

    local _fioe_so="${XNVME_LIB_ROOT}/libxnvme-fio-engine.so"
    local _fioe_uri=${XNVME_URI//:/\\\\:}

    if ! ssh::cmd "[[ -f \"${_fioe_so}\" ]]"; then
      cij::err "xnvme:fioe: '${_fioe_so}' does not exist!"
      return 1
    fi

    _cmd="${_cmd} --ioengine=external:${_fioe_so}"
    _cmd="${_cmd} --filename=${_fioe_uri}"

  # Add the special-sauce for the external SPDK io-engine spdk_nvme
  elif [[ "$ioengine_name" == "spdk_nvme" ]]; then

    local _traddr=${PCI_DEV_NAME//:/.};

    _cmd="LD_PRELOAD=${SPDK_FIOE_ROOT}/${ioengine_name} ${_cmd}"
    _cmd="${_cmd} --ioengine=spdk"
    _cmd="${_cmd} --filename=\"trtype=PCIe traddr=${_traddr} ns=${NVME_NSID}\""

  # Add the special-sauce for the external SPDK/nvme_bdev
  elif [[ "$ioengine_name" == "spdk_bdev" ]]; then
    # Produce SPDK config-file
    echo "[Nvme]" > /tmp/spdk.bdev.conf
    echo "  TransportID \"trtype:PCIe traddr:${PCI_DEV_NAME}\" Nvme0" >> /tmp/spdk.bdev.conf
    ssh::push /tmp/spdk.bdev.conf /opt/aux/spdk.bdev.conf

    _cmd="LD_PRELOAD=${SPDK_FIOE_ROOT}/${ioengine_name} ${_cmd}"
    _cmd="${_cmd} --ioengine=${ioengine_name}"
    _cmd="${_cmd} --spdk_conf=${SPDK_FIOE_ROOT}/spdk.bdev.conf"
    _cmd="${_cmd} --filename=Nvme0n1"

  # Add the not-so-special-sauce for built-in io-engines
  else
    _cmd="${_cmd} --ioengine=${ioengine_name}"
    _cmd="${_cmd} --filename=${NVME_DEV_PATH}"
  fi

  if [[ -v FIO_AUX ]]; then
    _cmd="${_cmd} ${FIO_AUX}"
  fi

  local _trgt_fname="/tmp/fio-output.txt"

  _cmd="${_cmd} --output-format=normal,json --output=${_trgt_fname}"

  # Now run that fio tester!
  if ! ssh::cmd "${_cmd}"; then
    cij::err "xnvme::fioe: error running fio"

    ssh::pull "${_trgt_fname}" "${output_fpath}"
    return 1
  fi

  # Download the output
  if ! ssh::pull "${_trgt_fname}" "${output_fpath}"; then
    cij::err "xnvme::fioe: failed pulling down fio output-file"
    return 0
  fi

  # Dump it to stdout for prosperity
  cat "${output_fpath}"

  return 0
}
