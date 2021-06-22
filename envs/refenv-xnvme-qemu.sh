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

# CIJOE: SSH_* environment variables; setup to SSH into qemu-guest running on localhost
: "${SSH_HOST:=localhost}"; export SSH_HOST
: "${SSH_PORT:=$QEMU_GUEST_SSH_FWD_PORT}"; export SSH_PORT
: "${SSH_USER:=root}"; export SSH_USER
: "${SSH_NO_CHECKS:=1}"; export SSH_NO_CHECKS

#
# PCIe and NVMe info; setup identifying the PCI device to use, the NVMe-
#

# Select other values based on 'NVME_NSTYPE' defined in testplan
if [[ -v NVME_NSTYPE && "${NVME_NSTYPE}" == "lblk" ]]; then
  : "${PCI_DEV_NAME:=0000:03:00.0}"; export PCI_DEV_NAME
  : "${NVME_CNTID:=0}"; export NVME_CNTID
  : "${NVME_NSID:=1}"; export NVME_NSID
elif [[ -v NVME_NSTYPE && "${NVME_NSTYPE}" == "zoned" ]]; then
  : "${PCI_DEV_NAME:=0000:03:00.0}"; export PCI_DEV_NAME
  : "${NVME_CNTID:=0}"; export NVME_CNTID
  : "${NVME_NSID:=2}"; export NVME_NSID
elif [[ -v NVME_NSTYPE && "${NVME_NSTYPE}" == "kvs" ]]; then
  : "${PCI_DEV_NAME:=0000:03:00.0}"; export PCI_DEV_NAME
  : "${NVME_CNTID:=0}"; export NVME_CNTID
  : "${NVME_NSID:=3}"; export NVME_NSID
else
  : "${PCI_DEV_NAME:=0000:03:00.0}"; export PCI_DEV_NAME
  : "${NVME_CNTID:=0}"; export NVME_CNTID
  : "${NVME_NSID:=1}"; export NVME_NSID
fi

#
# xNVMe: define XNVME_URI based on XNVME_BE and DEV_TYPE
#
if [[ -v XNVME_BE && "$XNVME_BE" == "spdk" ]]; then
    : "${XNVME_URI:=pci:${PCI_DEV_NAME}?nsid=${NVME_NSID}}"; export XNVME_URI
elif [[ -v XNVME_BE && "$XNVME_BE" == "linux" ]]; then
  if [[ -v DEV_TYPE && "$DEV_TYPE" == "char" ]]; then
    : "${XNVME_URI:=/dev/ng${NVME_CNTID}n${NVME_NSID}}"; export XNVME_URI
  elif [[ -v DEV_TYPE && "$DEV_TYPE" == "nullblk" ]]; then
    : "${XNVME_URI:=/dev/nullb0}"; export XNVME_URI
  else
    : "${XNVME_URI:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"; export XNVME_URI
  fi
elif [[ -v XNVME_BE && "$XNVME_BE" == "fbsd" ]]; then
    : "${XNVME_URI:=/dev/nvme${NVME_CNTID}ns${NVME_NSID}}"; export XNVME_URI
fi

# xNVMe: add mixins to XNVME_URI
if [[ -v XNVME_URI && -v XNVME_ADMIN ]]; then
  XNVME_URI="${XNVME_URI}?admin=${XNVME_ADMIN}"; export XNVME_URI
fi
if [[ -v XNVME_URI && -v XNVME_SYNC ]]; then
  XNVME_URI="${XNVME_URI}?sync=${XNVME_SYNC}"; export XNVME_URI
fi
if [[ -v XNVME_URI && -v XNVME_ASYNC ]]; then
  XNVME_URI="${XNVME_URI}?async=${XNVME_ASYNC}"; export XNVME_URI
fi

# xNVMe: where are libraries and share stored on the target system? This is
# needed to find the xNVMe fio io-engine, fio scripts etc.
#
: "${XNVME_LIB_ROOT:=/usr/lib}"; export XNVME_LIB_ROOT
: "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"; export XNVME_SHARE_ROOT

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
