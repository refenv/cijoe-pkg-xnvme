#!/bin/bash
#
# Verify that the CLI `xnvme idfy` runs without error
#
# This is using XNVME_NSID=0x1, this test can have the identify arguments
# overwritten by environment values, see the source
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${XNVME_CNS:=0x0}"
: "${XNVME_CNTID:=0x0}"
: "${XNVME_NSID:=0x1}"
: "${XNVME_SETID:=0x0}"
: "${XNVME_UUID:=0x0}"

if ! ssh::cmd "xnvme idfy $XNVME_URI --cns $XNVME_CNS --cntid $XNVME_CNTID --nsid $XNVME_NSID --setid $XNVME_SETID --uuid $XNVME_UUID"; then
  test::fail
fi

test::pass
