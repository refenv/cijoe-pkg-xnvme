#!/bin/bash
#
# Verify that `xnvme_tests_scc support` runs without error
#
# This test requires that the device identified by $XNVME_URI supports the
# simple-copy command.
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

if ! ssh::cmd "xnvme_tests_scc support $XNVME_URI"; then
  test::fail
fi

test::pass
