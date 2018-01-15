prefix ?= /usr

.PHONY: all

all:
	echo "Nothing to build."

install:
	perl Makefile.pl -install -prefix "$(prefix)"

uninstall:
	perl Makefile.pl -remove -prefix "$(prefix)"

clean:
	echo "Nothing to clean up."
