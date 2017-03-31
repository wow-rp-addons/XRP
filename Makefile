NEW_VERSION = $(shell git describe --abbrev=0 --tags | sed -e 's/^v//')
HEAD_VERSION = $(shell git describe | sed -e 's/^v//')

all: build/xrp-$(NEW_VERSION).zip build/xrp-$(NEW_VERSION).zip.SHA256 build/xrp-$(NEW_VERSION).CHANGELOG

head: build/xrp-$(HEAD_VERSION).zip

clean:
	rm -rf build/

build/xrp-%.zip:
	git rev-parse v$* > /dev/null
	mkdir -p $(@D)/tmp-$*/
	git archive --prefix=XRP/ v$* | tar -xC $(@D)/tmp-$*/
	cd $(@D)/tmp-$*/ && zip -q -D -X -l -9 -r $(CURDIR)/$@ XRP/ -x XRP/Makefile XRP/CHANGES.txt XRP/.gitignore
	rm -rf $(@D)/tmp-$*/
	touch -m -d '$(shell date -d '$(shell git log --date=local -1 --format=%ai v$*)')' $(CURDIR)/$@

build/xrp-%.zip.SHA256: build/xrp-%.zip
	sha256sum $< >> $@
	sed -i 's#$(@D)/##' $@
	touch -m -d '$(shell date -d '$(shell git log --date=local -1 --format=%ai v$*)')' $@

build/xrp-%.CHANGELOG: build/xrp-%.zip.SHA256
	git rev-parse v$* > /dev/null
	mkdir -p $(@D)/
	git show v$*:CHANGES.txt > $@
	echo >> $@
	echo "SHA256:" >> $@
	cat $< >> $@
	touch -m -d '$(shell date -d '$(shell git log --date=local -1 --format=%ai v$*)')' $@

.PHONY: all clean head
