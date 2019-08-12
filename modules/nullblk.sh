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

  : "${NULLBLK_QUEUE_MODE:=2}"
  : "${NULLBLK_HOME_NODE:=0}"
  : "${NULLBLK_GB:=100}"
  : "${NULLBLK_BS:=512}"
  : "${NULLBLK_NR_DEVICES:=1}"
  : "${NULLBLK_IRQMODE:=2}"
  : "${NULLBLK_COMPLETION_NSEC:=10}"
  : "${NULLBLK_SUBMIT_QUEUES:=1}"
  : "${NULLBLK_HW_QUEUE_DEPTH:=64}"

  # Multi-queue stuff
  : "${NULLBLK_USE_PER_NODE_HCTX:=0}"
  : "${NULLBLK_NO_SCHED:=0}"
  : "${NULLBLK_BLOCKING:=0}"
  : "${NULLBLK_SHARED_TAGS:=0}"

  # Zoned stuff
  : "${NULLBLK_ZONED:=0}"
  : "${NULLBLK_ZONE_SIZE:=256}"         # Size in units of MB
  : "${NULLBLK_ZONE_NR_CONV:=0}"        # Number of conventional / random-access zones

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

nullblk::insert() {
  if ! nullblk::env; then
    cij::err "nullblk::env - invalid Null Block ENV."
    return 1
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

  if ! ssh::cmd "modprobe -r ${NULLBLK_MODULE_NAME}"; then
    cij::err "nullblk:::insert: failed modprobe"
    return 1
  fi

  return 0
}
