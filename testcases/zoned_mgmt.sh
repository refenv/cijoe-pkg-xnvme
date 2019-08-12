#!/bin/bash
#
# Verify that CLI `zoned mgmt` runs without error
#
# Fundamental check
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
: "${LIMIT:=1}"

for ACTION in "mgmt-reset" "mgmt-open" "mgmt-close" "mgmt-finish"; do
  if ! ssh::cmd "zoned $ACTION $XNVME_URI --slba $SLBA"; then
    test::fail
  fi

  if ! ssh::cmd "zoned report $XNVME_URI --slba $SLBA --limit $LIMIT"; then
    test::fail
  fi
done

test::pass
