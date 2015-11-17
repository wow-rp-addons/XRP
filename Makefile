NEW_VERSION = $(shell git describe --abbrev=0 --tags | sed -e 's/^v//')
HEAD_VERSION = $(shell git describe | sed -e 's/^v//')
CURSE_API_KEY = $(shell git config --get curse.apikey)

all: build/xrp-$(NEW_VERSION).zip build/xrp-$(NEW_VERSION).zip.SHA512 build/xrp-$(NEW_VERSION).CHANGELOG

head: build/xrp-$(HEAD_VERSION).zip

upload: upload-curse upload-stormlord

clean:
	rm -rf build/

build/xrp-%.zip:
	git rev-parse v$* > /dev/null
	mkdir -p $(@D)/tmp-$*/
	git archive --prefix=xrp/ v$* | tar -xC $(@D)/tmp-$*/
	cd $(@D)/tmp-$*/ && zip -q -D -X -l -9 -r $(CURDIR)/$@ xrp/ -x xrp/Makefile xrp/CHANGES.txt xrp/.gitignore
	rm -rf $(@D)/tmp-$*/

build/xrp-%.zip.SHA512: build/xrp-%.zip
	sha512sum $< >> $@
	sed -i 's#$(@D)/##' $@

build/xrp-%.CHANGELOG: build/xrp-%.zip.SHA512
	git rev-parse v$* > /dev/null
	mkdir -p $(@D)/
	git show v$*:CHANGES.txt > $@
	echo >> $@
	echo "SHA512:" >> $@
	cat $< >> $@

upload-curse: upload-curse-$(NEW_VERSION)

upload-stormlord: upload-stormlord-$(NEW_VERSION)

upload-%: upload-stormlord-% upload-curse-%

upload-curse-%: build/xrp-%.zip build/xrp-%.CHANGELOG
	curl -F "name=v$*" -F "game_versions=$(shell curl -s http://wow.curseforge.com/game-versions.json | jq -r 'to_entries | map({id: .key, name: .value.name}) | .[] | select(.name | contains("6.2.3")) | .id')" -F "file_type=$(shell echo $* | sed -e 's#^[^_]*$$#r#' -e 's#.*_alpha.*#a#' -e 's#.*_\(beta\|rc\).*#b#')" -F "change_log=<$(word 2,$^)" -F "change_markup_type=plain" -F "file=@$<" -H "X-API-Key: $(CURSE_API_KEY)" "http://wow.curseforge.com/addons/xrp/upload-file.json"

upload-stormlord-%: build/xrp-%.zip build/xrp-%.zip.SHA512
	scp $^ asgard.stormlord.ca:~/pub/xrp/

.PHONY: all clean head upload upload-curse upload-stormlord upload-% upload-curse-% upload-stormlord-%
