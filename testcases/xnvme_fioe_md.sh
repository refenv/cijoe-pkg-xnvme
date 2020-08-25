#!/bin/bash
#
# Verifies xNVMe using fio, the Flexible I/O Tester.
#
# Requires that:
#
# * xNVMe engine available at: ${XNVME_LIB_ROOT}/libxnvme-fio-engine.so
# * fio-verify script available at: ${XNVME_SHARE_ROOT}/xnvme-verify.fio
# * FIOE_NAME is set to the engine name e.g. "xnvme" or "io_uring"
#
# NOTE: see modules/xnvme.sh for the inner workings of 'xnvme::fioe'
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${FIO_NRUNS:=1}"
: "${FIO_SCRIPT:=/usr/share/xnvme/xnvme-compare.fio}"
: "${FIO_SECTION:=default}"

: "${FIOE_SO:=/usr/lib/libxnvme-fio-engine.so}"

enum=$(ssh::cmd_output "xnvme enum")
schm=$(echo "$XNVME_BE" | tr '[:upper:]' '[:lower:]')
uris=$(echo "$enum" | grep -oh "uri: '$schm:.*'" | tr -d "'" | awk '// {print $2}')

args=""
args="${FIO_SCRIPT}"
args="${args} --section $FIO_SECTION"
args="${args} --ioengine=external:${FIOE_SO}"
for uri in $uris; do
  uri=${uri//:/\\\\:}
  args="$args --filename $uri"
done

: "${FIO_NRUNS:=1}"
: "${FIO_SECTION:=default}"

for i in $(seq "$FIO_NRUNS"); do
  cij::info "run: ${i}/${FIO_NRUNS}"
  if ! ssh::cmd  "${FIO_BIN} ${args}"; then
    test::fail
  fi
done

test::pass
