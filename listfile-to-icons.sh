#!/bin/bash
LISTFILE=$1
ICONSLUA="$(realpath $(dirname ${BASH_SOURCE[0]}))/Interface/Glances/Icons.lua"

if [ ! -f "${LISTFILE}" ]; then
	echo "File does not exist: ${LISTFILE}."
	exit 1
fi

grep -e '^interface/icons' "${LISTFILE}" | cut -d'/' -f3 | cut -d'.' -f1 | sed -e 's/^/\t"/' -e 's/$/",/' -e '1s/^/select(2, ...).ICON_LIST = {\n/' -e '$s/$/\n}/' | unix2dos > "${ICONSLUA}"
