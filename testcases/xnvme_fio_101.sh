#!/bin/bash
#
# Verifies minimal interaction of fio with the fio xNVMe IO Engine
#
# Uses an NVMe Device defined in FIO_SCRIPT
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

if ! xnvme::env; then
  test::fail "Invalid xNVMe environment"
fi

: "${XNVME_URI:?Must be set and non-empty}"
#: "${CMD_PREFIX:=taskset -c 1 perf stat}"
: "${CMD_PREFIX:=taskset -c 1}"

: "${XNVME_LIB_ROOT:=/usr/lib}"
: "${XNVME_SHARE_ROOT:=/usr/share/xnvme}"

: "${FIO_BIN:=fio}"
: "${FIO_SCRIPT:=${XNVME_SHARE_ROOT}/xnvme-verify.fio}"

: "${FIOE_SO:=${XNVME_LIB_ROOT}/libxnvme-fio-engine.so}"

if ! ssh::cmd "[[ -f \"${FIOE_SO}\" ]]"; then
  test::fail "'${FIOE_SO}' does not exist!"
fi
if ! ssh::cmd "[[ -f \"${FIO_SCRIPT}\" ]]"; then
  test::fail "'${FIO_SCRIPT}' does not exist!"
fi

XNVME_URI_FIO=${XNVME_URI//:/\\\\:}

FIOE_CMD="${CMD_PREFIX} ${FIO_BIN} ${FIO_SCRIPT}"
FIOE_CMD="${FIOE_CMD} --section=default"
FIOE_CMD="${FIOE_CMD} --ioengine=external:${FIOE_SO}"
FIOE_CMD="${FIOE_CMD} --filename=${XNVME_URI_FIO}"

cij::info "fio: xNVMe"
if ! ssh::cmd "${FIOE_CMD}"; then
  test::fail
fi

test::pass
