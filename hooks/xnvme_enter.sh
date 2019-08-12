#!/usr/bin/env bash
#
# Verifies that environment variables required by the xNVMe testcases are
# defined and detaches / re-attaches NVMe devices from kernel to user space
#
# on-enter: de-attach from kernel NVMe driver
# on-exit: re-attach to kernel NVMe driver
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::require ssh
test::enter

hook::xnvme_enter() {
  if ! xnvme::env; then
    cij::err "xnvme::env - Invalid xNVMe env."
    return 1
  fi

  if [[ ! -v XNVME_BE || -z "$XNVME_BE" ]]; then
    cij::err "hook::xnvme_enter: XNVME_BE is not set or is the empty string"
    return 1
  fi

  cij::info "hook:xnvme_enter: XNVME_BE($XNVME_BE)"

  if [[ "$XNVME_BE" != "SPDK" ]]; then
    cij::info "hook::xnvme_enter: not using SPDK driver -> nothing to do"
    return 0
  fi

  XNVME_DRIVER_CMD="xnvme-driver"
  if [[ -v HUGEMEM && -n "$HUGEMEM" ]]; then
    XNVME_DRIVER_CMD="HUGEMEM=$HUGEMEM $XNVME_DRIVER_CMD"
  fi
  if [[ -v NRHUGE && -n "$NRHUGE" ]]; then
    XNVME_DRIVER_CMD="NRHUGE=$NRHUGE $XNVME_DRIVER_CMD"
  fi
  if [[ -v HUGENODE && -n "$HUGENODE" ]]; then
    XNVME_DRIVER_CMD="HUGENODE=$HUGENODE $XNVME_DRIVER_CMD"
  fi

  if ! ssh::cmd "$XNVME_DRIVER_CMD"; then
    cij::err "hook::xnvme_enter: FAILED: detaching NVMe driver"
    return 1
  fi

  return 0
}

hook::xnvme_enter
exit $?
