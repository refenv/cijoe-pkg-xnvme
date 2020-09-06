#!/bin/bash
#
# Compares xNVMe using fio, the Flexible I/O Tester.
#
# Requires that:
#
# * xNVMe engine available at: ${XNVME_LIB_ROOT}/libxnvme-fio-engine.so
# * fio-verify script available at e.g.: ${XNVME_SHARE_ROOT}/xnvme-verify.fio
# * FIO_IOENG_NAME is set to the engine name e.g. "xnvme" or "io_uring"
#
# NOTE: see modules/xnvme.sh for the inner workings of 'xnvme::fioe', this
# script basically just calls the module-function 'FIO_NRUNS' times
#
# shellcheck disable=SC2119
#
CIJ_TEST_NAME=$(basename "${BASH_SOURCE[0]}")
export CIJ_TEST_NAME
# shellcheck source=modules/cijoe.sh
source "$CIJ_ROOT/modules/cijoe.sh"
test::enter

: "${FIO_NRUNS:=1}"
: "${FIO_SCRIPT:?Must be set and non-empty}"
: "${FIO_SECTION:?Must be set and non-empty}"
: "${FIO_IOENG_NAME:?Must be set and non-empty}"

for i in $(seq "$FIO_NRUNS"); do
  cij::info "run: ${i}/${FIO_NRUNS}"
  if ! xnvme::fioe "${FIO_SCRIPT}" "${FIO_IOENG_NAME}" "${FIO_SECTION}" "${CIJ_TEST_AUX_ROOT}/fio-output-${i}.txt"; then
    test::fail
  fi
done

test::pass
