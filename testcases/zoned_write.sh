#!/bin/bash
#
# Verify that CLI `zoned write` runs without error
#
# NOTE: As is, then this test will most likely fail due to the condition of the
# hard-coded zone address (0x0).
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
: "${NLB:=0}"
: "${LIMIT:=1}"

if ! ssh::cmd "zoned mgmt-reset $XNVME_URI --slba $SLBA"; then
  test::fail
fi

if ! ssh::cmd "zoned report $XNVME_URI --slba $SLBA --limit $LIMIT"; then
  test::fail
fi

if ! ssh::cmd "zoned write $XNVME_URI --slba $SLBA --nlb $NLB"; then
  test::fail
fi

if ! ssh::cmd "zoned report $XNVME_URI --slba $SLBA --limit $LIMIT"; then
  test::fail
fi

test::pass
