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

hook::nullblk_enter() {
  if ! nullblk::remove; then
    cij::info "hook:nullblk_enter: FAILED nullblk::remove -- continuing"
  fi

  if ! nullblk::insert; then
    cij::err "hook::nullblk_enter: FAILED: nullblk::insert"
    return 1
  fi

  if [[ ! -v NULLBLK_AUTOCONF ]]; then
    return 0;
  fi

  case $NULLBLK_AUTOCONF in
  blk_zblk)
    export NULLBLK_ZONED

    NULLBLK_ZONED="0"
    if ! nullblk::create; then
      cij::err "hook::nullblk_enter: FAILED: nullblk:create"
      return 1
    fi

    NULLBLK_ZONED="1"
    if ! nullblk::create; then
      cij::err "hook::nullblk_enter: FAILED: nullblk:create"
      return 1
    fi
    ;;
  esac

  return 0
}

hook::nullblk_enter
exit $?
