LIBNAME = lpeglabel
LUADIR = ../lua/

COPT = -O2
# COPT = -DLPEG_DEBUG -g

CWARNS = -Wall -Wextra -pedantic \
	-Waggregate-return \
	-Wcast-align \
	-Wcast-qual \
	-Wdisabled-optimization \
	-Wpointer-arith \
	-Wshadow \
	-Wsign-compare \
	-Wundef \
	-Wwrite-strings \
	-Wbad-function-cast \
	-Wdeclaration-after-statement \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wstrict-prototypes \
# -Wunreachable-code \


CFLAGS = $(CWARNS) $(COPT) -std=c99 -I$(LUADIR) -fPIC
CC = gcc

FILES = lplvm.o lplcap.o lpltree.o lplcode.o lplprint.o
# For Linux
linux:
	make lpeglabel.so "DLLFLAGS = -shared -fPIC"

# For Mac OS
macosx:
	make lpeglabel.so "DLLFLAGS = -bundle -undefined dynamic_lookup"

# For Windows
windows:
	make lpeglabel.dll "DLLFLAGS = -shared -fPIC"

lpeglabel.so: $(FILES)
	env $(CC) $(DLLFLAGS) $(FILES) -o lpeglabel.so
lpeglabel.dll: $(FILES)
	$(CC) $(DLLFLAGS) $(FILES) -o lpeglabel.dll $(LUADIR)/bin/lua53.dll

$(FILES): makefile

test: test.lua testlabel.lua testrelabelparser.lua relabel.lua lpeglabel.so
	lua test.lua
	lua testlabel.lua
	lua testrelabelparser.lua

clean:
	rm -f $(FILES) lpeglabel.so


lplcap.o: lplcap.c lplcap.h lpltypes.h
lplcode.o: lplcode.c lpltypes.h lplcode.h lpltree.h lplvm.h lplcap.h
lplprint.o: lplprint.c lpltypes.h lplprint.h lpltree.h lplvm.h lplcap.h
lpltree.o: lpltree.c lpltypes.h lplcap.h lplcode.h lpltree.h lplvm.h lplprint.h
lplvm.o: lplvm.c lplcap.h lpltypes.h lplvm.h lplprint.h lpltree.h

