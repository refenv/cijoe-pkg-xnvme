#!/bin/bash
#
# Verify that the TEST `xnvme feature-set` runs without error
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${FID:=0x4}"
: "${FEAT:=0x1}"
: "${SAVE:=--save}"

if ! ssh::cmd "xnvme feature-set $XNVME_URI --fid $FID --feat $FEAT $SAVE"; then
  test::fail
fi

test::pass
