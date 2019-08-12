#!/bin/bash
#
# Verify initialization and termination of 8 xNVMe asynchronous contexts with
# queue-depth 64
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

COUNT=8
QDEPTH=64

if ! ssh::cmd "xnvme_tests_async_intf init_term ${XNVME_URI} --count ${COUNT} --qdepth ${QDEPTH}"; then
  test::fail
fi


test::pass
