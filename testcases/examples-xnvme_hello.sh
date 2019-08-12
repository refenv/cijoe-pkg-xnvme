#!/bin/bash
#
# Verify that `xnvme_hello` runs without error
#
# Primitive check to verify that the example code is valid
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

if ! ssh::cmd "xnvme_hello hw $XNVME_URI"; then
  test::fail
fi

test::pass
