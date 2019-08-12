#!/bin/bash
#
# Verify xNVMe identifier parsing
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

if ! ssh::cmd "xnvme_tests_ident ident_from_uri"; then
  test::fail
fi

test::pass
