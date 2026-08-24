CC ?= cc
CFLAGS ?= -O2 -pipe
CPPFLAGS ?=
LDFLAGS ?=
LDLIBS ?= -lX11

.PHONY: all check clean

all: watch-x11-geometry

watch-x11-geometry: watch-x11-geometry.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -std=c11 -Wall -Wextra -Wpedantic \
		$(LDFLAGS) -o $@ $< $(LDLIBS)

check:
	bash -n ./*.sh
	$(CC) $(CPPFLAGS) -std=c11 -Wall -Wextra -Wpedantic \
		-fsyntax-only watch-x11-geometry.c

clean:
	$(RM) watch-x11-geometry
