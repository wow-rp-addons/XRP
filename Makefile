NEW_VERSION = $(shell git describe --abbrev=0 --tags)
HEAD_VERSION = $(shell git describe)
CURSE_API_KEY = $(shell git config --get curse.apikey)

all: build/xrp_$(NEW_VERSION).zip build/xrp_$(NEW_VERSION).zip.SHA512SUM build/xrp_$(NEW_VERSION).CHANGELOG

head: build/xrp_$(HEAD_VERSION).zip

upload: upload-curse upload-stormlord

clean:
	rm -rf build/

build/xrp_%.zip:
	git rev-parse $* > /dev/null
	mkdir -p $(@D)/tmp-$*/
	git archive --prefix=xrp/ $* | tar -xC $(@D)/tmp-$*/
	cd $(@D)/tmp-$*/ && zip -q -D -X -l -9 -r $(CURDIR)/$@ xrp/ -x xrp/lib/libmspx.lua xrp/Makefile xrp/docs/CHANGES.txt xrp/.gitignore
	rm -rf $(@D)/tmp-$*/

build/xrp_%.zip.SHA512SUM: build/xrp_%.zip
	sha512sum $< >> $@
	sed -i 's#$(@D)/##' $@

build/xrp_%.CHANGELOG: build/xrp_%.zip.SHA512SUM
	git rev-parse $* > /dev/null
	mkdir -p $(@D)/
	git show $*:docs/CHANGES.txt > $@
	echo >> $@
	echo "SHA512SUM:" >> $@
	cat $< >> $@

upload-curse: upload-curse-$(NEW_VERSION)

upload-stormlord: upload-stormlord-$(NEW_VERSION)

upload-%: upload-stormlord-% upload-curse-%

upload-curse-%: build/xrp_%.zip build/xrp_%.CHANGELOG
	curl -F "name=$*" -F "game_versions=$(shell curl -s http://wow.curseforge.com/game-versions.json | jq -r 'to_entries | map({id: .key, name: .value.name}) | .[] | select(.name | contains("$(shell echo $* | sed -e 's#^v##' -e 's#\.[^\.]*$$##')")) | .id')" -F "file_type=$(shell echo $* | sed -e 's#^[^_]*$$#r#' -e 's#.*_alpha.*#a#' -e 's#.*_\(beta\|rc\).*#b#')" -F "change_log=<$(word 2,$^)" -F "change_markup_type=plain" -F "file=@$<" -H "X-API-Key: $(CURSE_API_KEY)" "http://wow.curseforge.com/addons/xrp/upload-file.json"

upload-stormlord-%: build/xrp_%.zip build/xrp_%.zip.SHA512SUM
	scp $^ asgard.stormlord.ca:~/pub/xrp/

.PHONY: all clean upload upload-curse upload-stormlord upload-% upload-curse-% upload-stormlord-%
