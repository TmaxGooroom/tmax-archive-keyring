TRUSTED-LIST := $(patsubst active-keys/add-%,trusted.gpg/tmax-archive-%.gpg,$(wildcard active-keys/add-*))
TMPRING := trusted.gpg/build-area

GPG_OPTIONS := --no-options --no-default-keyring --no-auto-check-trustdb --trustdb-name ./trustdb.gpg

# build: verify-indices keyrings/tmax-archive-keyring.gpg keyrings/tmax-archive-removed-keys.gpg verify-results $(TRUSTED-LIST)
build: verify-indices keyrings/tmax-archive-keyring.gpg verify-results $(TRUSTED-LIST)

verify-indices: keyrings/team-members.gpg
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg \
		--verify active-keys/index.asc active-keys/index
	# gpg ${GPG_OPTIONS} \
	#  	--keyring keyrings/team-members.gpg \
	#  	--verify removed-keys/index.asc removed-keys/index

# verify-results: keyrings/team-members.gpg keyrings/tmax-archive-keyring.gpg keyrings/tmax-archive-removed-keys.gpg
verify-results: keyrings/team-members.gpg keyrings/tmax-archive-keyring.gpg
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg --verify \
		keyrings/tmax-archive-keyring.gpg.asc \
		keyrings/tmax-archive-keyring.gpg
	# gpg ${GPG_OPTIONS} \
	# 	--keyring keyrings/team-members.gpg --verify \
	# 	keyrings/tmax-archive-removed-keys.gpg.asc \
	# 	keyrings/tmax-archive-removed-keys.gpg
	#FIXME: Do we need to verify the created keyrings in trusted.gpg.d, too?
	#	Maybe "just" checking that no key is added if we merge, but how…

keyrings/tmax-archive-keyring.gpg: active-keys/index
	jetring-build -I $@ active-keys
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@

# keyrings/tmax-archive-removed-keys.gpg: removed-keys/index
# 	jetring-build -I $@ removed-keys
# 	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
# 	mv -f $@.tmp $@

keyrings/team-members.gpg: team-members/index
	jetring-build -I $@ team-members
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@

$(TRUSTED-LIST) :: trusted.gpg/tmax-archive-%.gpg : active-keys/add-% active-keys/index
	mkdir -p $(TMPRING) trusted.gpg
	grep -F $(shell basename $<) -- active-keys/index > $(TMPRING)/index
	cp $< $(TMPRING)
	jetring-build -I $@ $(TMPRING)
	rm -rf $(TMPRING)
	gpg ${GPG_OPTIONS} --no-keyring --import-options import-export --import < $@ > $@.tmp
	mv -f $@.tmp $@

clean:
	rm -f keyrings/tmax-archive-keyring.gpg \
		keyrings/tmax-archive-keyring.gpg~ \
		keyrings/tmax-archive-keyring.gpg.lastchangeset
	# rm -f keyrings/tmax-archive-removed-keys.gpg \
	# 	keyrings/tmax-archive-removed-keys.gpg~ \
	# 	keyrings/tmax-archive-removed-keys.gpg.lastchangeset
	rm -f keyrings/team-members.gpg \
		keyrings/team-members.gpg~ \
		keyrings/team-members.gpg.lastchangeset
	rm -rf $(TMPRING) trusted.gpg trustdb.gpg
	rm -f keyrings/*.cache

install: build
	install -d $(DESTDIR)/usr/share/keyrings/
	cp trusted.gpg/tmax-archive-*.gpg $(DESTDIR)/usr/share/keyrings/
	cp keyrings/tmax-archive-keyring.gpg $(DESTDIR)/usr/share/keyrings/
	# cp keyrings/tmax-archive-removed-keys.gpg $(DESTDIR)/usr/share/keyrings/
	install -d $(DESTDIR)/etc/apt/trusted.gpg.d/
	cp $(shell find trusted.gpg/ -name '*.gpg' -type f) $(DESTDIR)/etc/apt/trusted.gpg.d/

.PHONY: verify-indices verify-results clean build install
