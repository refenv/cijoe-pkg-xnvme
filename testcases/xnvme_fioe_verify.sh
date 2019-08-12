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

: "${FIOE_NRUNS:=1}"
: "${FIOE_SECTION:=default}"

for i in $(seq "$FIOE_NRUNS"); do
	cij::info "run: ${i}/${FIOE_NRUNS}"
	if ! xnvme::fioe "xnvme-verify.fio" "${FIOE_NAME}" "${FIOE_SECTION}"; then
		test::fail
	fi
done

test::pass
