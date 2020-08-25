#!/usr/bin/env bash
#
# QEMU target environment skeleton
#
# The SSH configuration is overwritten such that everything using the "ssh::"
# module will be targeted towards the QEMU guest.
#
# To access the QEMU host an explicit "QEMU_HOST" and utility functions are
# provided by the "qemu::" module
#

# CIJOE: QEMU_* environment variables
: "${QEMU_HOST:=localhost}"; export QEMU_HOST
: "${QEMU_HOST_USER:=$USER}"; export QEMU_HOST_USER
: "${QEMU_HOST_PORT:=22}"; export QEMU_HOST_PORT
: "${QEMU_HOST_SYSTEM_BIN:=/opt/qemu/x86_64-softmmu/qemu-system-x86_64}"; export QEMU_HOST_SYSTEM_BIN
: "${QEMU_HOST_IMG_BIN:=qemu-img}"; export QEMU_HOST_IMG_BIN

: "${QEMU_GUESTS:=/opt/guests}"; export QEMU_GUESTS
: "${QEMU_GUEST_NAME:=emujoe}"; export QEMU_GUEST_NAME
: "${QEMU_GUEST_SSH_FWD_PORT:=2222}"; export QEMU_GUEST_SSH_FWD_PORT
: "${QEMU_GUEST_CONSOLE:=file}"; export QEMU_GUEST_CONSOLE
: "${QEMU_GUEST_MEM:=6G}"; export QEMU_GUEST_MEM
: "${QEMU_GUEST_SMP:=4}"; export QEMU_GUEST_SMP
#: "${QEMU_GUEST_KERNEL:=1}"; export QEMU_GUEST_KERNEL
#: "${QEMU_GUEST_APPEND:=net.ifnames=0 biosdevname=0}"; export QEMU_GUEST_APPEND

# CIJOE: SSH_* environment variables
: "${SSH_HOST:=localhost}"; export SSH_HOST
: "${SSH_PORT:=$QEMU_GUEST_SSH_FWD_PORT}"; export SSH_PORT
: "${SSH_USER:=root}"; export SSH_USER
: "${SSH_NO_CHECKS:=1}"; export SSH_NO_CHECKS

#
# xNVMe: where are libraries and share stored on the target system? This is
# needed to find the xNVMe fio io-engine, fio scripts etc.
#
: "${XNVME_LIB_ROOT:=/usr/lib}"; export XNVME_LIB_ROOT
: "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"; export XNVME_SHARE_ROOT

#
# xNVMe 1/2: set PCI_DEV_NAME, NVME_CNTID, and NVME_NSID based on NVME_NSTYPE
#
if [[ -v NVME_NSTYPE ]]; then
  case $NVME_NSTYPE in
  lblk)
    : "${PCI_DEV_NAME=0000:03:00.0}"
    : "${NVME_CNTID=0}"
    : "${NVME_NSID=1}"
    : "${NVME_DEV_NAME:=nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${NVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    ;;
  zoned)
    : "${PCI_DEV_NAME=0000:03:00.0}"
    : "${NVME_CNTID=0}"
    : "${NVME_NSID=2}"
    : "${NVME_DEV_NAME:=nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${NVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    ;;
  *)
    echo "# ERROR: invalid NVME_NSTYPE(${NVME_NSTYPE})"
    exit 1
    ;;
  esac

  export PCI_DEV_NAME
  export NVME_NSID
  export NVME_CNTID
  export NVME_DEV_NAME
  export NVME_DEV_PATH
fi

#
# xNVMe: the XNVME_BE should be set by testplan, but a default is provided for
# running interactively
#
#: "${XNVME_BE:=SPDK}"
#: "${XNVME_BE:=FIOC}"
#: "${XNVME_BE:=LIOC}"
#: "${XNVME_BE:=LAIO}"
: "${XNVME_BE:=LIOU}"

#
# xNVMe: set XNVME_URI and possibly HUGEMEM
#
if [[ -v XNVME_BE && -v NVME_NSTYPE ]]; then

  case $XNVME_BE in
  LIOC)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=lioc:${XNVME_DEV_PATH}}"
    ;;
  LIOU)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=liou:${XNVME_DEV_PATH}}"
    ;;
  LAIO)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=laio:${XNVME_DEV_PATH}}"
    ;;
  FIOC)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=fioc:${XNVME_DEV_PATH}}"
    ;;
  SPDK)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=pci:${PCI_DEV_NAME}?nsid=${NVME_NSID}}"

    # Set a default HUGEMEM that can be overwritten by testplan
    : "${HUGEMEM:=4096}"
    export HUGEMEM
    ;;
  *)
    echo "# ERROR: invalid XNVME_BE(${XNVME_BE})"
    exit 1
  esac

  # Operating system device path
  export XNVME_DEV_PATH
  # xNVMe URI
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
: "${NULLBLK_QUEUE_MODE=2}"; export NULLBLK_QUEUE_MODE
: "${NULLBLK_IRQMODE=0}"; export NULLBLK_IRQMODE
