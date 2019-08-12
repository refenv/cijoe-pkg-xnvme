#!/bin/bash
#
# Verify that CLI `zoned report` runs without error
#
# Basic verification that a report is returned for LIMIT(10) amount, starting
# from somewhere which is not LBA 0x0
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${SLBA:=0x000000000001dc00}"
: "${LIMIT:=10}"

if ! ssh::cmd "zoned report $XNVME_URI --slba $SLBA --limit $LIMIT"; then
  test::fail
fi

test::pass
