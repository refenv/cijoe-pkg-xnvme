#!/bin/bash
#
# Verify that CLI `xnvme_tests_znd_state` runs without error
#
# Fundamental check
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"
: "${SLBA:=0x0}"

if ! ssh::cmd "xnvme_tests_znd_state transition $XNVME_URI --slba $SLBA"; then
  test::fail
fi

test::pass
