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
    cij::err "usage: xnvme::fioe_compare('fio-script.fname', 'ioengine_name')"
    cij::err " or"
    cij::err "usage: xnvme::fioe_compare('fio-script.fname', 'ioengine_name', 'section')"
    return 1
  fi

  if ! xnvme::env; then
    cij::err "xnvme:fio_compare: invalid xNVMe environment"
    return 1
  fi

  : "${XNVME_URI:?Must be set and non-empty}"
  : "${CMD_PREFIX:=taskset -c 1 perf stat}"
  : "${FIOE_BIN:=fio}"

  local script_fname=$1
  local ioengine_name=$2
  local section=$3
  if [[ -z "$section" ]]; then
    section="default"
  fi
  local jobfile="${XNVME_SHARE_ROOT}/${script_fname}"

  local fioe_so="${XNVME_LIB_ROOT}/libxnvme-fio-engine.so"
  local fioe_cmd
  local fioe_uri
  local fioe_uri_opts

  if ! ssh::cmd "[[ -f \"${fioe_so}\" ]]"; then
    cij::err "xnvme:fio_compare: '${fioe_so}' does not exist!"
    return 1
  fi
  if ! ssh::cmd "[[ -f \"${jobfile}\" ]]"; then
    cij::err "xnvme:fio_compare: '${jobfile}' does not exist!"
    return 1
  fi

  fioe_cmd="${CMD_PREFIX} ${FIOE_BIN} ${jobfile}"
  fioe_cmd="${fioe_cmd} --section=${section}"

  # Add the special-sauce for the external xNVMe fio engine
  if [[ "$ioengine_name" == *"xnvme"* ]]; then
    fioe_uri=${XNVME_URI//:/\\\\:}

    fioe_uri_opts=""
    if [[ "$XNVME_URI" == *"/dev/nullb"* ]]; then
      fioe_uri_opts="${fioe_uri_opts}?pseudo=1"
    fi

    fioe_cmd="${fioe_cmd} --ioengine=external:${fioe_so}"
    fioe_cmd="${fioe_cmd} --filename=${fioe_uri}${fioe_uri_opts}"
  elif [[ "$ioengine_name" == "spdk" ]]; then
    fioe_cmd="LD_PRELOAD=${SPDK_FIOE_SO} ${fioe_cmd}"
    fioe_cmd="${fioe_cmd} --ioengine=${ioengine_name}"
    fioe_cmd="${fioe_cmd} --filename=\"${SPDK_FIOE_URI}\""
  else
    fioe_cmd="${fioe_cmd} --ioengine=${ioengine_name}"
    fioe_cmd="${fioe_cmd} --filename=${XNVME_DEV_PATH}"
  fi

  if [[ -v FIOE_AUX ]]; then
    fioe_cmd="${fioe_cmd} ${FIOE_AUX}"
  fi

  if ! ssh::cmd "${fioe_cmd}"; then
    cij::err "xnvme:fio_compare: error running fio"
    return 1
  fi

  return 0
}
