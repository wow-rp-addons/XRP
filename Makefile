# Copyright The Total RP 3 Authors
# SPDX-License-Identifier: Apache-2.0

PYTHON ?= python3
LIBDIR := Libraries
PACKAGER_URL := https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh
SCHEMA_URL := https://raw.githubusercontent.com/Meorawr/wow-ui-schema/main/UI.xsd

libs:
	@curl -s $(PACKAGER_URL) | bash -s -- -c -d -z
	@cp -a .release/XRP/$(LIBDIR)/* $(LIBDIR)/

