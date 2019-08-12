#!/bin/bash
#
# Verify that the CLI `xnvme idfy-ns` runs without error
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

: "${NSID:=0x1}"

if ! ssh::cmd "xnvme idfy-ns $XNVME_URI --nsid $NSID"; then
  test::fail
fi

test::pass
