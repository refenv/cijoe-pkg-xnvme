#!/usr/bin/env bash

#
# xNVMe 1/2: set PCI_DEV_NAME, NVME_CNTID, and NVME_NSID based on NVME_NSTYPE
#
if [[ -v NVME_NSTYPE ]]; then
  case $NVME_NSTYPE in
  lblk)
    : "${PCI_DEV_NAME=0000:03:00.0}"
    : "${NVME_CNTID=0}"
    : "${NVME_NSID=1}"
    ;;
  zoned)
    : "${PCI_DEV_NAME=0000:03:00.0}"
    : "${NVME_CNTID=0}"
    : "${NVME_NSID=2}"
    ;;
  *)
    echo "# ERROR: invalid NVME_NSTYPE(${NVME_NSTYPE})"
    exit 1
    ;;
  esac

  export PCI_DEV_NAME
  export NVME_NSID
  export NVME_CNTID
fi

#
# xNVMe 2/3: set XNVME_BE if not assigned
#
#: "${XNVME_BE:=SPDK}"
#: "${XNVME_BE:=FIOC}"
#: "${XNVME_BE:=LIOC}"
: "${XNVME_BE:=LIOU}"

#
# xNVMe 3/3: set XNVME_URI and possibly HUGEMEM
#
if [[ -v XNVME_BE && -v NVME_NSTYPE ]]; then

  case $XNVME_BE in
  NWRP)
    : "${XNVME_URI=nwrp:///dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    ;;
  LIOC)
    : "${XNVME_URI=lioc:///dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    ;;
  LIOU)
    : "${XNVME_URI=liou:///dev/nvme${NVME_CNTID}n${NVME_NSID}}"
    ;;
  FIOC)
    : "${XNVME_URI=fioc:///dev/nvme${NVME_CNTID}ns${NVME_NSID}}"
    ;;
  SPDK)
    : "${XNVME_URI=pci://${PCI_DEV_NAME}/${NVME_NSID}}"

    # Set a default HUGEMEM that can be overwritten by testplan
    : "${HUGEMEM:=4096}"
    export HUGEMEM
    ;;
  *)
    echo "# ERROR: invalid XNVME_BE(${XNVME_BE})"
    exit 1
  esac

  export XNVME_URI
fi
