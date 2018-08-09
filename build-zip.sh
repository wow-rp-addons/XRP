#!/bin/bash
TARGET_TAG=$1

submodule-archive() {
	local prefix=$1
	local targetcommit=$2
	local buildtmp=$3
	local sha submodpath ref
	git submodule status | while read sha submodpath ref; do
		pushd "${submodpath}" >/dev/null
		pushd .. >/dev/null
		local arr=($(git ls-tree ${targetcommit} "${submodpath##*/}"))
		popd >/dev/null
		local commit=${arr[2]}
		git archive --prefix="${prefix}${submodpath}/" "${commit}" | tar -xC "${buildtmp}"
		submodule-archive "${prefix}${submodpath}/" "${commit}" "${buildtmp}"
		popd >/dev/null
	done
}

PREFIX="XRP/"
REPODIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
#echo "${REPODIR}"

#LATEST_TAG=$(git describe --abbrev=0 --tags --always)

cd "${REPODIR}"

if git rev-parse "${TARGET_TAG}^{tag}" >/dev/null 2>&1; then
	echo -n "Packaging ${TARGET_TAG}... "
else
	echo "Target tag not found."
	exit 1
fi

BUILDTMP=$(mktemp -p "${REPODIR}" -d)
#echo "${BUILDTMP}"

git archive --prefix=${PREFIX} ${TARGET_TAG} | tar -xC "${BUILDTMP}"
submodule-archive "${PREFIX}" "${TARGET_TAG}" "${BUILDTMP}"

TIMESTAMP=$(stat -c "%Y" "${BUILDTMP}/${PREFIX}XRP.toc")
sed -i -e "s/^## Version: .*/## Version: ${TARGET_TAG/v/}/" "${BUILDTMP}/${PREFIX}XRP.toc"
touch -d @${TIMESTAMP} "${BUILDTMP}/${PREFIX}XRP.toc"
pushd "${BUILDTMP}" >/dev/null
zip -q -D -X -9 -r out.zip ${PREFIX}
popd >/dev/null

mv "${BUILDTMP}/out.zip" "${REPODIR}/XRP-${TARGET_TAG/v/}.zip"

echo "Done!"
rm -rf "${BUILDTMP}"
