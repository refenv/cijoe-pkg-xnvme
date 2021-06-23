#!/bin/bash
#
# Verify that CLI `zoned mgmt` runs without error
#
# Fundamental check, note this does not pass on user space NVMe driver as the bringup/teardown
# triggers state-transitions. A hardcoded check is added for the detection of the user-space NVMe
# driver, and to quit without failing.
# Another testcase is available which does the logic-transitions in a C-implementation instead.
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

if [[ "${XNVME_URI}" = *"pci"* ]]; then
  cij::info "Skipping test; see test-description why"
  test::pass
fi

for ACTION in "mgmt-reset" "mgmt-open" "mgmt-close" "mgmt-finish"; do
  if ! cij::cmd "zoned $ACTION $XNVME_URI --slba $SLBA"; then
    test::fail
  fi

  if ! cij::cmd "zoned report $XNVME_URI --slba $SLBA --limit $LIMIT"; then
    test::fail
  fi
done

test::pass
