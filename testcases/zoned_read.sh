#!/bin/bash
#
# Verify that CLI `zoned read` runs without error
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

: "${NSID:=0x1}"
: "${SLBA:=0x1}"
: "${NLB:=0}"

if ! ssh::cmd "zoned read $XNVME_URI --nsid $NSID --slba $SLBA --nlb $NLB"; then
  test::fail
fi

test::pass
