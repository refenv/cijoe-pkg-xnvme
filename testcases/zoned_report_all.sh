#!/bin/bash
#
# Verify that CLI `zoned report` runs without error
#
# Basic verification that a report is returned for when requesting a report
# with default values, this should return a report with for all zones
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

if ! ssh::cmd "zoned report $XNVME_URI"; then
  test::fail
fi

test::pass
