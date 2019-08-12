#!/bin/bash
#
# Verify that CLI `zoned append` runs without error
#
# The following environment variables, have defaults, but can be overwritten:
#
# SLBA
# NLB
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${NLB:=1}"
: "${SLBA:=0x0}"

if ! ssh::cmd "zoned mgmt-reset $XNVME_URI --slba $SLBA"; then
  test::fail
fi

if ! ssh::cmd "zoned append $XNVME_URI --slba $SLBA --nlb $NLB"; then
  test::fail
fi

if ! ssh::cmd "zoned append $XNVME_URI --slba $SLBA --nlb $NLB"; then
  test::fail
fi

if ! ssh::cmd "zoned append $XNVME_URI --slba $SLBA --nlb $NLB"; then
  test::fail
fi

test::pass
