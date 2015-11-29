prefix ?= /usr

.PHONY: install
install:
	perl Makefile.pl -install -prefix "$(prefix)"

uninstall:
	perl Makefile.pl -remove -prefix "$(prefix)"
