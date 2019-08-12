#!/bin/bash
#
# Verify that CLI `xnvme log` runs without error
#
# Primitive check to verify functionality of `xnvme log`, it requests the
# error-log as this is a log which should be easily retrieved as it is mandatory
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${LID:=0x1}"
: "${LSP:=0x0}"
: "${LPO_NBYTES:=0}"
: "${NSID:=0x0}"
: "${RAE:=0}"
: "${NBYTES:=4096}"

if ! ssh::cmd "xnvme log $XNVME_URI --lid $LID --lsp $LSP --lpo-nbytes $LPO_NBYTES --nsid $NSID --rae $RAE --data-nbytes $NBYTES --data-output /tmp/xnvme-log.bin"; then
  test::fail
fi

# Grab the log-output
ssh::pull "/tmp/xnvme-log.bin" "$CIJ_TEST_AUX_ROOT/"

test::pass
