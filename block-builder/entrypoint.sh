#!/bin/bash
set -e

[ "${VERBOSE}" = "verbose" ] && set -x

workdir="/work"
# Wait for package feed to be available
inotifywait "${workdir}" -e create -t ${FEED_TIMEOUT} --include "package-index-ready"

finish() {
	rm -f "${workdir}/package-index-ready"
}
trap finish EXIT ERR

if [ ! -f "${workdir}/repo.yml" ]; then
	echo "Working directory in use does not contain a Balena device repository" && exit 1;
fi
if ! grep -q 'yocto-based OS image' "${workdir}/repo.yml"; then
	echo "Working directory in use does not contain a Balena device repository" && exit 1;
fi

cp /balena.yml "${workdir}"
if [ -z "${PACKAGES}" ]; then
	git config --global --add safe.directory "${workdir}/balena-yocto-scripts"
	# shellcheck disable=SC1091
	. ${workdir}/balena-yocto-scripts/automation/include/balena-lib.inc
	echo "Looking for contract for ${MACHINE}: ${APPNAME}"
	PACKAGES=$(balena_lib_contract_fetch_composedOf_list "${APPNAME}" "${MACHINE}" "${RELEASE_VERSION}" "sw.recipe.yocto")
	if [ -z "${PACKAGES}" ]; then
		echo "No packages found for ${APPNAME}"
		exit 1
	fi
fi
echo "Building ${APPNAME} for ${MACHINE} with ${PACKAGES} at ${RELEASE_VERSION} on ${WORKSPACE} to ${DEPLOY_DIR}" >&2
APPNAME=${APPNAME} \
MACHINE=${MACHINE} \
PACKAGES=${PACKAGES} \
RELEASE_VERSION=${RELEASE_VERSION} \
WORKSPACE="${WORKSPACE}" \
DEPLOY_DIR="${workdir}/blocks/" \
${workdir}/balena-yocto-scripts/automation/entry_scritps/balena-build-block.sh
