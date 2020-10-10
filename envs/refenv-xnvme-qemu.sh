#!/usr/bin/env bash

# CIJOE: QEMU_* environment variables
: "${QEMU_HOST:=localhost}"; export QEMU_HOST
: "${QEMU_HOST_USER:=$USER}"; export QEMU_HOST_USER
: "${QEMU_HOST_PORT:=22}"; export QEMU_HOST_PORT
: "${QEMU_HOST_SYSTEM_BIN:=/opt/qemu/x86_64-softmmu/qemu-system-x86_64}"; export QEMU_HOST_SYSTEM_BIN
: "${QEMU_HOST_IMG_BIN:=qemu-img}"; export QEMU_HOST_IMG_BIN

: "${QEMU_GUESTS:=/opt/guests}"; export QEMU_GUESTS
: "${QEMU_GUEST_NAME:=emujoe}"; export QEMU_GUEST_NAME
# This is for defining a port-forward from host to guest
: "${QEMU_GUEST_SSH_FWD_PORT:=2222}"; export QEMU_GUEST_SSH_FWD_PORT
#: "${QEMU_GUEST_CONSOLE:=file}"; export QEMU_GUEST_CONSOLE
#: "${QEMU_GUEST_CONSOLE:=stdio}"; export QEMU_GUEST_CONSOLE
: "${QEMU_GUEST_CONSOLE:=sock}"; export QEMU_GUEST_CONSOLE
#: "${QEMU_GUEST_HOST_SHARE:=$HOME/git}"; export QEMU_GUEST_CONSOLE
: "${QEMU_GUEST_MEM:=6G}"; export QEMU_GUEST_MEM
: "${QEMU_GUEST_SMP:=4}"; export QEMU_GUEST_SMPi
# Use these to boot a custom kernel
: "${QEMU_GUEST_KERNEL:=0}"; export QEMU_GUEST_KERNEL
#: "${QEMU_GUEST_KERNEL:=1}"; export QEMU_GUEST_KERNEL
#: "${QEMU_GUEST_APPEND:=net.ifnames=0 biosdevname=0 intel_iommu=on vfio_iommu_type1.allow_unsafe_interrupts=1}"; export QEMU_GUEST_APPEND

# CIJOE: SSH_* environment variables
: "${SSH_HOST:=localhost}"; export SSH_HOST
: "${SSH_PORT:=$QEMU_GUEST_SSH_FWD_PORT}"; export SSH_PORT
: "${SSH_USER:=root}"; export SSH_USER
: "${SSH_NO_CHECKS:=1}"; export SSH_NO_CHECKS

# xNVMe: the backend to utilize, this should be set in the testplan, but define
# it here for running cijoe interactively
#
#: "${XNVME_ASYNC:=thr}"
#: "${XNVME_ASYNC:=aio}"
#: "${XNVME_ASYNC:=nil}"
#: "${XNVME_ASYNC:=iou}"
#: "${XNVME_BE:=linux}"
#: "${XNVME_BE:=fbsd}"
#: "${XNVME_BE:=spdk}"
#

# xNVMe: where are libraries and share stored on the target system? This is
# needed to find the xNVMe fio io-engine, fio scripts etc.
#
: "${XNVME_LIB_ROOT:=/usr/lib}"; export XNVME_LIB_ROOT
: "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"; export XNVME_SHARE_ROOT

# xNVMe: which device is used for testing? set PCI_DEV_NAME, NVME_CNTID, and
# NVME_NSID based on NVME_NSTYPE
#
if [[ -v NVME_NSTYPE ]]; then
  : "${PCI_DEV_NAME=0000:03:00.0}"
  : "${NVME_CNTID=0}"

  case $NVME_NSTYPE in
  lblk)
    : "${NVME_NSID=1}"
    ;;
  zoned)
    : "${NVME_NSID=2}"
    ;;
  *)
    echo "# ERROR: invalid NVME_NSTYPE(${NVME_NSTYPE})"
    exit 1
    ;;
  esac

  if [[ -v DEV_TYPE && "${DEV_TYPE}" == "nullblk" ]]; then
    case $NVME_NSTYPE in
    lblk)
      : "${NVME_DEV_NAME:=nullb0}"
      ;;
    zoned)
      : "${NVME_DEV_NAME:=nullb1}"
      ;;
    esac
  else
    : "${NVME_DEV_NAME:=nvme${NVME_CNTID}n${NVME_NSID}}"
  fi
  : "${NVME_DEV_PATH:=/dev/${NVME_DEV_NAME}}"

  export PCI_DEV_NAME
  export NVME_NSID
  export NVME_CNTID
  export NVME_DEV_NAME
  export NVME_DEV_PATH
fi

#
# xNVMe: define XNVME_URI and possibly HUGEMEM
#
if [[ -v XNVME_BE ]]; then
  : "${XNVME_DEV_PATH:=${NVME_DEV_PATH}}"

  case $XNVME_BE in
  linux|fbsd)
    : "${XNVME_URI=${XNVME_DEV_PATH}}"
    ;;
  spdk)
    : "${HUGEMEM:=4096}"
    : "${XNVME_URI=pci:${PCI_DEV_NAME}?nsid=${NVME_NSID}}"
    ;;
  *)
    echo "# ERROR: invalid XNVME_BE(${XNVME_BE})"
    exit 1
  esac

  if [[ -v XNVME_ASYNC && "${XNVME_BE}" == "linux" ]]; then
    case $XNVME_ASYNC in
    thr|iou|aio|nil)
      XNVME_URI="${XNVME_URI}?async=${XNVME_ASYNC}"
      ;;
    *)
      echo "# ERROR: invalid XNVME_ASYNC(${XNVME_ASYNC})"
      exit 1
    esac
  fi

  export HUGEMEM
  export XNVME_DEV_PATH
  export XNVME_URI
fi

# These are for running fio
if [[ -v NVME_NSTYPE ]]; then
  : "${SPDK_FIOE_ROOT:=/opt/aux}"; export SPDK_FIOE_ROOT
fi

# The external fio io-engines usually depend on the fio-version on which they
# built against. So, we set the FIO_BIN to point it to the version that comes
# with the xNVMe dockerize reference environment
: "${FIO_BIN:=/opt/aux/fio}"; export FIO_BIN

#
# These are for the nullblock hook, specifically when loading it
#
: "${NULLBLK_NR_DEVICES=0}"; export NULLBLK_NR_DEVICES
