#!/usr/bin/env bash
#
# Insert / Removes the Linux Kernel Null Block Kernel Module
#
# on-enter: insert the Linux Null Block Kernel Module
# on-exit: remove the Linux Null Block Kernel Module
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::require ssh
test::enter

hook::nullblk_exit() {
  if ! nullblk::remove; then
    cij::err "hook::nullblk_exit: failed: nullblk::insert"
    return 1
  fi

  return 0
}

hook::nullblk_exit
exit $?
