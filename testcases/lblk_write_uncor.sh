!/bin/bash
#
# Verify that CLI `lblk write-uncor` runs without error
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
: "${NLB:=0}"

if ! cij::cmd "lblk write-uncor $XNVME_URI --slba ${SLBA} --nlb ${NLB}"; then
  test::fail
fi

test::pass
