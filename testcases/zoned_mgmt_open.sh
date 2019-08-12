#!/bin/bash
#
# Verify that CLI `zoned mgmt-open` runs without error
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
: "${ZDI_PATH:=$CIJ_TEST_AUX_ROOT/zdi.bin}"

ZDI=$(python -c "print(\"\".join([chr(i % 26 + 65) for i in range(128)]))")
echo -n "$ZDI" > "$ZDI_PATH"
ssh::push "$ZDI_PATH" /tmp/zdi.bin

if ! ssh::cmd "zoned mgmt-reset $XNVME_URI --slba $SLBA"; then
  test::fail
fi

if ! ssh::cmd "zoned mgmt-open $XNVME_URI --slba $SLBA"; then
  test::fail
fi

if ! ssh::cmd "zoned report $XNVME_URI --slba $SLBA --limit 1 --data-output /tmp/report.bin"; then
  test::fail
fi

ssh::pull "/tmp/report.bin" "$CIJ_TEST_AUX_ROOT/report.bin"

test::pass
