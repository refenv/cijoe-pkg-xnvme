#!/bin/bash
#
# Verify that `xnvme_tests_scc scopy` runs without error
#
# Verify that `xnvme_tests_scc scopy` runs without error
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

if ! ssh::cmd "xnvme_tests_scc scopy $XNVME_URI"; then
  test::fail
fi

test::pass
