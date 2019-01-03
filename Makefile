prefix ?= /usr
tool = hw-probe
tool_dir = $(DESTDIR)$(prefix)/bin

.PHONY: all

all:
	echo "Nothing to build."

install:
	mkdir -p $(tool_dir)
	install -m 755 $(tool).pl $(tool_dir)/$(tool)

uninstall:
	rm -f $(tool_dir)/$(tool)

clean:
	echo "Nothing to clean up."
