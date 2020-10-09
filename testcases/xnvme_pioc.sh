#!/bin/bash
#
# Verify that CLI `xnvme pioc` runs without error
#
# NOTE: NSID is hardcoded
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${XNVME_URI:?Must be set and non-empty}"

: "${NSID:=0x1}"
: "${OPCODE:=0x02}"     # read-command on I/O queue

if ! ssh::cmd "xnvme info ${XNVME_URI} > /tmp/device-info.yml"; then
  test::fail
fi
if ! ssh::pull "/tmp/device-info.yml" "/tmp/device-info.yml"; then
  test::fail
fi

DATA_NBYTES=$(cat < /tmp/device-info.yml | awk '/lba_nbytes:/ {print $2}')

CMD_FPATH=$(mktemp -u --tmpdir=/tmp -t read_XXXXXX.nvmec)

if ! ssh::cmd "nvmec create --opcode ${OPCODE} --nsid ${NSID} --cmd-output ${CMD_FPATH}"; then
  test::fail
fi

if ! ssh::cmd "nvmec show --cmd-input ${CMD_FPATH}"; then
  test::fail
fi

if ! ssh::cmd "xnvme pioc ${XNVME_URI} --cmd-input ${CMD_FPATH} --data-nbytes ${DATA_NBYTES}"; then
  test::fail
fi

test::pass
