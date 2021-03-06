# libmojibake Makefile

CURL=curl
RUBY=ruby
MAKE=make

# settings

cflags = -O2 -std=c99 -pedantic -Wall -fpic $(CFLAGS)
cc = $(CC) $(cflags)
AR = ar

OS := $(shell uname)
ifeq ($(OS),Darwin)
	SHLIB_EXT = dylib
else #TODO Windows
	SHLIB_EXT = so
endif

# meta targets

all: c-library

c-library: libmojibake.a libmojibake.$(SHLIB_EXT)

clean:
	rm -f utf8proc.o libmojibake.a libmojibake.$(SHLIB_EXT) normtest UnicodeData.txt DerivedCoreProperties.txt CompositionExclusions.txt CaseFolding.txt NormalizationTest.txt
	$(MAKE) -C bench clean

update: utf8proc_data.c.new

# real targets

utf8proc_data.c.new: UnicodeData.txt DerivedCoreProperties.txt CompositionExclusions.txt CaseFolding.txt
	$(RUBY) data_generator.rb < UnicodeData.txt > utf8proc_data.c.new

UnicodeData.txt:

	$(CURL) -O http://www.unicode.org/Public/UNIDATA/UnicodeData.txt

DerivedCoreProperties.txt:
	$(CURL) -O http://www.unicode.org/Public/UNIDATA/DerivedCoreProperties.txt

CompositionExclusions.txt:
	$(CURL) -O http://www.unicode.org/Public/UNIDATA/CompositionExclusions.txt

CaseFolding.txt:
	$(CURL) -O http://www.unicode.org/Public/UNIDATA/CaseFolding.txt

utf8proc.o: mojibake.h utf8proc.c utf8proc_data.c
	$(cc) -c -o utf8proc.o utf8proc.c

libmojibake.a: utf8proc.o
	rm -f libmojibake.a
	$(AR) rs libmojibake.a utf8proc.o

libmojibake.so: utf8proc.o
	$(cc) -shared -o libmojibake.$(SHLIB_EXT) utf8proc.o
	chmod a-x libmojibake.$(SHLIB_EXT)

libmojibake.dylib: utf8proc.o
	$(cc) -dynamiclib -o $@ $^ -install_name $(libdir)/$@


# Test programs

NormalizationTest.txt:
	$(CURL) -O http://www.unicode.org/Public/UNIDATA/NormalizationTest.txt

normtest: normtest.c utf8proc.o mojibake.h
	$(cc) normtest.c utf8proc.o -o normtest

check: normtest NormalizationTest.txt
	./normtest
