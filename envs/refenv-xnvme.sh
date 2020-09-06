#!/usr/bin/env bash
#
# xNVMe: where are libraries and share stored on the target system? This is
# needed to find the xNVMe fio io-engine, fio scripts etc.
#
: "${XNVME_LIB_ROOT:=/usr/lib}"; export XNVME_LIB_ROOT
: "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"; export XNVME_SHARE_ROOT

#
# xNVMe: which device is used for testing? set PCI_DEV_NAME, NVME_CNTID, and
# NVME_NSID based on NVME_NSTYPE
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
# xNVMe: set XNVME_BE if not assigned
# NOTE: This will be deprecated as the backends are now: LINUX, FBSD, and SPDK
#
#: "${XNVME_BE:=SPDK}"
#: "${XNVME_BE:=FIOC}"
#: "${XNVME_BE:=LIOC}"
#: "${XNVME_BE:=LAIO}"
#: "${XNVME_BE:=LIOU}"

#
# xNVMe: set XNVME_URI and possibly HUGEMEM
#
if [[ -v XNVME_BE && -v NVME_NSTYPE ]]; then

  case $XNVME_BE in
  LINUX|LIOU|LIOC)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=${XNVME_DEV_PATH}?async=iou}"
    ;;
  LAIO)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=${XNVME_DEV_PATH}?async=aio}"
    ;;
  NWRP)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=${XNVME_DEV_PATH}?async=nil}"
    ;;
  FBSD|FREEBSD|FIOC)
    : "${XNVME_DEV_PATH:=/dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    : "${XNVME_URI=${XNVME_DEV_PATH}}"
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
