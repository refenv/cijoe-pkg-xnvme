#!/bin/bash
#
# Verify that CLI `xnvme padc` runs without error
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${OPCODE:=0x02}"     # Identify
: "${CNS:=0x1}"         # Identify-controller
: "${DATA_NBYTES:=4096}"

CMD_FPATH=$(mktemp -u --tmpdir=/tmp -t glp_XXXXXX.nvmec)

if ! ssh::cmd "nvmec create --opcode ${OPCODE} --cdw10 ${CNS} --cmd-output ${CMD_FPATH}"; then
  test::fail
fi

if ! ssh::cmd "nvmec show --cmd-input ${CMD_FPATH}"; then
  test::fail
fi

cij::info "Passing command through"

if ! ssh::cmd "xnvme padc ${XNVME_URI} --cmd-input ${CMD_FPATH} --data-nbytes ${DATA_NBYTES}"; then
  test::fail
fi

test::pass
