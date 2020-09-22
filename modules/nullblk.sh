#!/usr/bin/env bash
#
# CIJOE module to insert/remove the Linux Null Block Kernel Module
#
# The module depends on 'modprobe' to do the insertion/removal
#
# The nullblk::env sets up environment variables for the Null Block parameters,
# named "NULLBLK_{PARAMATER_NAME}", see:
#
# https://www.kernel.org/doc/html/latest/block/null_blk.html
#
# For documentation of parameters / variables.
#
# nullblk::env          - Checks environment for module parameters
# nullblk::insert       - Insert the Linux Null Block Kernel module
# nullblk::remove       - Remove the Linux Null Block Kernel module
#
nullblk::env() {
  if ! ssh::env; then
    cij::err "nullblk::env - Invalid SSH ENV."
    return 1
  fi

  : "${NULLBLK_MODULE_NAME:=null_blk}"

  # Setup via cfg-path
  : "${NULLBLK_QUEUE_MODE:=2}"
  : "${NULLBLK_HOME_NODE:=0}"
  : "${NULLBLK_BS:=512}"
  : "${NULLBLK_IRQMODE:=2}"

  : "${NULLBLK_GB:=14}"
  : "${NULLBLK_NR_DEVICES:=1}"
  : "${NULLBLK_COMPLETION_NSEC:=10}"
  : "${NULLBLK_SUBMIT_QUEUES:=1}"
  : "${NULLBLK_HW_QUEUE_DEPTH:=64}"
  : "${NULLBLK_MEMORY_BACKED:=1}"

  # Multi-queue stuff
  : "${NULLBLK_USE_PER_NODE_HCTX:=0}"
  : "${NULLBLK_NO_SCHED:=0}"
  : "${NULLBLK_BLOCKING:=0}"
  : "${NULLBLK_SHARED_TAGS:=0}"

  # Zoned stuff
  : "${NULLBLK_ZONED:=0}"
  : "${NULLBLK_ZONE_SIZE:=256}"         # Size in units of MB
  : "${NULLBLK_ZONE_NR_CONV:=0}"        # Number of conventional / random-access zones
}

nullblk::params() {
  if ! nullblk::env; then
    cij::err "nullblk::env - invalid Null Block ENV."
    return 1
  fi

  NULLBLK_PARAMS=""
  NULLBLK_PARAMS="${NULLBLK_PARAMS} queue_mode=${NULLBLK_QUEUE_MODE}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} home_node=${NULLBLK_HOME_NODE}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} gb=${NULLBLK_GB}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} bs=${NULLBLK_BS}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} nr_devices=${NULLBLK_NR_DEVICES}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} irqmode=${NULLBLK_IRQMODE}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} completion_nsec=${NULLBLK_COMPLETION_NSEC}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} submit_queues=${NULLBLK_SUBMIT_QUEUES}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} hw_queue_depth=${NULLBLK_HW_QUEUE_DEPTH}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} memory_hw_queue_depth=${NULLBLK_HW_QUEUE_DEPTH}"

  NULLBLK_PARAMS="${NULLBLK_PARAMS} use_per_node_hctx=${NULLBLK_USE_PER_NODE_HCTX}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} no_sched=${NULLBLK_NO_SCHED}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} blocking=${NULLBLK_BLOCKING}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} shared_tags=${NULLBLK_SHARED_TAGS}"

  NULLBLK_PARAMS="${NULLBLK_PARAMS} zoned=${NULLBLK_ZONED}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} zone_size=${NULLBLK_ZONE_SIZE}"
  NULLBLK_PARAMS="${NULLBLK_PARAMS} zone_nr_conv=${NULLBLK_ZONE_NR_CONV}"

  export NULLBLK_PARAMS

  return 0
}

nullblk::create() {
  if ! nullblk::env; then
    cij::err "nullblk::env - invalid Null Block ENV."
    return 1
  fi

  local _kpath="/sys/kernel/config/nullb"
  local _devname=""
  local _size
  local _id=0
  local _limit=0
  local _cfg_path
  local _cmd

  while [[ _limit -lt 10 ]]; do
    _devname="nullb${_id}"
    _cfg_path="${_kpath}/${_devname}"

    if ssh::cmd "mkdir ${_cfg_path}"; then
      break
    fi

    _limit=$(( _limit + 1 ))
    _id=$(( _id + 1 ))
  done

  if [[ _limit -eq 10 ]]; then
    cij::err "failed"
    return 1
  fi

  _size=$(( NULLBLK_GB * 1024 ))
  _cmd="${_cmd} echo '${_size}' >> ${_cfg_path}/size"

  _cmd="${_cmd} && echo '${NULLBLK_HW_QUEUE_DEPTH}' >> ${_cfg_path}/hw_queue_depth"
  _cmd="${_cmd} && echo '${NULLBLK_HOME_NODE}' >> ${_cfg_path}/home_node"
  _cmd="${_cmd} && echo '${NULLBLK_QUEUE_MODE}' >> ${_cfg_path}/queue_mode"
  _cmd="${_cmd} && echo '${NULLBLK_BS}' >> ${_cfg_path}/blocksize"
  _cmd="${_cmd} && echo '${NULLBLK_COMPLETION_NSEC}' >> ${_cfg_path}/completion_nsec"
  _cmd="${_cmd} && echo '${NULLBLK_IRQMODE}' >> ${_cfg_path}/irqmode"
  _cmd="${_cmd} && echo '${NULLBLK_BLOCKING}' >> ${_cfg_path}/blocking"
  _cmd="${_cmd} && echo '${NULLBLK_MEMORY_BACKED}' >> ${_cfg_path}/memory_backed"

  _cmd="${_cmd} && echo '${NULLBLK_ZONED}' >> ${_cfg_path}/zoned"
  if [[ -v NULLBLK_ZONED && "${NULLBLK_ZONED}" == "1" ]]; then
    _cmd="${_cmd} && echo '${NULLBLK_ZONE_SIZE}' >> ${_cfg_path}/zone_size"
    _cmd="${_cmd} && echo '${NULLBLK_ZONE_NR_CONV}' >> ${_cfg_path}/zone_nr_conv"
  fi

  _cmd="${_cmd} && echo '1' >> ${_cfg_path}/power"

  if ! ssh::cmd "${_cmd}"; then
    cij::err "nullblk:::create: failed creating nullblk instance: '${_devname}'"
    return 1
  fi

  cij::info "nullblk:::create: created nullblk instance: '${_devname}'"

  return 0
}

nullblk::insert() {
  if ! nullblk::params; then
    cij::err "nullblk::env - invalid params"
    return 1
  fi

  # Create Null-block instances via config-fs instead
  if [[ "${NULLBLK_NR_DEVICES}" == "0" ]]; then
    NULLBLK_PARAMS="nr_devices=0"
    cij::info "nullblk::insert: nr_devices == 0; expecting config via cfgfs"
  else
    cij::info "nullblk::insert: nr_devices > 0; doing stuff"
  fi

  if ! ssh::cmd "modprobe ${NULLBLK_MODULE_NAME} ${NULLBLK_PARAMS}"; then
    cij::err "nullblk:::insert: failed modprobe"
    return 1
  fi

  return 0
}

nullblk::remove() {
  if ! nullblk::env; then
    cij::err "nullblk::env - invalid Null Block ENV."
    return 1
  fi

  if ! ssh::cmd "rmdir /sys/kernel/config/nullb/nullb*"; then
    cij::info "nullblk:::remove: failed removing instances"
  fi
  if ! ssh::cmd "modprobe -r ${NULLBLK_MODULE_NAME}"; then
    cij::err "nullblk:::remove: failed removing module"
    return 1
  fi

  return 0
}
