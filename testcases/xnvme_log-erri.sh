#!/bin/bash
#
# Verify that CLI `xnvme log-erri` runs without error
#
# Primitive check to verify functionality of `xnvme log-erri`.
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${NSID:=0x0}"
: "${NBYTES:=4096}"

if ! cij::cmd "xnvme log-erri $XNVME_URI --nsid $NSID --data-output /tmp/xnvme_log-erri.bin"; then
  test::fail
fi

# Grab the log-output
ssh::pull "/tmp/xnvme_log-erri.bin" "$CIJ_TEST_AUX_ROOT/"

test::pass
