#!/bin/bash
#
# Verify that the TEST `xnvme feature-get` runs without error
#
# Verifies that is it possible to get feature information via `xnvme gfeat` CLI
# Feature identifier for error-recovery and temperature thresholds are used
#
# NOTE: The select-bit is used in this test, however, it does not error on
# commands using it, since the test does not check whether it is supported
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

for FID in "0x4" "0x5"; do

  case $FID in
  "0x4") cij::info "Temperature threshold" ;;
  "0x5") cij::info "Error recovery" ;;
  esac

  cij::info "Getting feature with FID: ${FID} without setting select bit"

  if ! ssh::cmd "xnvme feature-get $XNVME_URI --fid $FID"; then
    test::fail
  fi

  cij::info "Getting feature with FID: ${FID} and setting select bit"

  for SEL in "0x0" "0x1" "0x2" "0x3"; do

    case $SEL in
    "0x0") cij::info "Getting 'current' value for fid: ${FID}" ;;
    "0x1") cij::info "Getting 'default' value for fid: ${FID}" ;;
    "0x2") cij::info "Getting 'saved' value for fid: ${FID}" ;;
    "0x3") cij::info "Getting 'supported' value for fid: ${FID}" ;;
    esac

    if ! ssh::cmd "xnvme feature-get $XNVME_URI --fid $FID --sel $SEL"; then
      cij::warn "Device support for select-bit is not checked"
    fi

  done
done

test::pass
