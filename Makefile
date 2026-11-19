# TerminalJ+: the RenkuOS Terminal with inline input methods (Mozc).
#
#   make            cross-build build/<arch>/TerminalJ+
#   make hpkg       -> build/<arch>/terminalj_plus-<version>-<arch>.hpkg
#
# ARCH=x86_64 (the default) uses the RenkuOS tree in $(RENKU) (generated/
# must exist). ARCH=x86_gcc2h builds for the 32-bit x86_gcc2 hybrid with
# gcc 2, as its Terminal is, against $(GEN) (default
# $(RENKU)/generated.x86_gcc2h).

VERSION = 1.0.0
PKG_VERSION = $(VERSION)-2
SIGNATURE = x-vnd.RenkuOS-TerminalJPlus
ARCH ?= x86_64

RENKU ?= $(HOME)/renku
ifeq ($(ARCH),x86_64)
GEN ?= $(RENKU)/generated
PKG_ARCH = x86_64
CROSS = $(GEN)/cross-tools-x86_64/bin/x86_64-unknown-haiku-
DEVEL = $(GEN)/objects/haiku/x86_64/packaging/packages_build/regular/hpkg_-haiku_devel.hpkg/contents/develop
REL = $(GEN)/objects/haiku/x86_64/release
GCCLIB = $(wildcard $(GEN)/build_packages/gcc_syslibs-*-x86_64/lib)
SYSARCH = x86_64
# libgcc_s holds the unwinder: without it exceptions are not caught.
ARCH_LIBS = -lgcc_s
ARCH_FLAGS = -Wno-unused-parameter
PKG_REQUIRES = haiku\n\tlib:libstdc++
else ifeq ($(ARCH),x86_gcc2h)
GEN ?= $(RENKU)/generated.x86_gcc2h
PKG_ARCH = x86_gcc2
CROSS = $(GEN)/cross-tools-x86_gcc2/bin/i586-pc-haiku-
DEVEL = $(GEN)/objects/haiku/x86_gcc2/packaging/packages_build/regular/hpkg_-haiku_devel.hpkg/contents/develop
REL = $(GEN)/objects/haiku/x86_gcc2/release
GCCLIB = $(REL)/system/libroot
SYSARCH = x86
# gcc 2's C++ runtime is libstdc++.r4, which is in the haiku package.
ARCH_LIBS = $(REL)/libs/stdc++/legacy/libstdc++.r4.so -lroot
ARCH_FLAGS = -march=pentium
# gcc 2's C++ headers are in the devel package, and its driver does not find
# Haiku's glue code: link the way the Haiku build links its Terminal.
ARCH_INCLUDES = -I$(HDR)/c++/2.95.3
GCC2_LIB = $(wildcard $(GEN)/cross-tools-x86_gcc2/lib/gcc-lib/i586-pc-haiku/*)
LINK_FLAGS = -nostdlib -Xlinker --no-undefined -Xlinker -soname=_APP_
LINK_BEGIN = $(DEVEL)/lib/crti.o $(GCC2_LIB)/crtbeginS.o \
	$(DEVEL)/lib/start_dyn.o $(DEVEL)/lib/init_term_dyn.o
LINK_END = $(GCC2_LIB)/libgcc.a $(GCC2_LIB)/crtendS.o $(DEVEL)/lib/crtn.o
PKG_REQUIRES = haiku
else
$(error ARCH must be x86_64 or x86_gcc2h)
endif
BUILD = build/$(PKG_ARCH)
CXX = $(CROSS)g++
CC = $(CROSS)gcc
STRIP = $(CROSS)strip
HDR = $(DEVEL)/headers
TOOLS = $(GEN)/objects/linux/x86_64/release/tools
HOSTENV = env LD_LIBRARY_PATH=$(GEN)/objects/linux/lib
RC = $(TOOLS)/rc/rc
XRES = $(TOOLS)/xres
ADDATTR = $(HOSTENV) $(TOOLS)/addattr/addattr
LINKCATKEYS = $(HOSTENV) $(TOOLS)/locale/linkcatkeys
PKG_TOOL = $(HOSTENV) $(TOOLS)/package/package

INCLUDES = -Iapp $(ARCH_INCLUDES) -idirafter $(HDR) -idirafter $(HDR)/posix -idirafter $(HDR)/gnu \
	-idirafter $(HDR)/bsd -idirafter $(HDR)/os \
	$(foreach d,$(wildcard $(HDR)/os/*/),-idirafter $(d)) \
	-idirafter $(HDR)/os/add-ons/graphics -idirafter $(HDR)/private \
	-idirafter $(HDR)/private/shared -idirafter $(HDR)/private/libroot \
	-idirafter $(HDR)/private/system -idirafter $(HDR)/private/system/arch/$(SYSARCH) \
	-idirafter $(HDR)/private/textencoding -idirafter $(HDR)/private/kernel \
	-idirafter $(HDR)/private/tracker
FLAGS = -O2 -D_DEFAULT_SOURCE -Wall -Wno-multichar -Wno-sign-compare \
	$(ARCH_FLAGS)
LIBDIRS = -B$(DEVEL)/lib -L$(DEVEL)/lib -L$(REL)/kits -L$(REL)/kits/tracker \
	-L$(REL)/kits/textencoding -L$(REL)/kits/translation -L$(REL)/kits/shared \
	-L$(REL)/kits/locale -L$(REL)/system/libroot -L$(GCCLIB)
LIBS = -lbe -llocalestub -lshared -ltracker -ltranslation -ltextencoding \
	$(ARCH_LIBS)

SOURCES = $(wildcard app/*.cpp) $(wildcard app/*.c)
OBJECTS = $(patsubst app/%,$(BUILD)/obj/%.o,$(SOURCES))
APP = $(BUILD)/TerminalJ+
CATALOGS = $(patsubst catalogs/%.catkeys,$(BUILD)/catalogs/%.catalog,$(wildcard catalogs/*.catkeys))

all: $(APP) $(CATALOGS)

$(BUILD)/obj/%.cpp.o: app/%.cpp $(wildcard app/*.h)
	@mkdir -p $(dir $@)
	@echo "  CXX  $<"
	@$(CXX) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILD)/obj/%.c.o: app/%.c
	@mkdir -p $(dir $@)
	@echo "  CC   $<"
	@$(CC) $(FLAGS) $(INCLUDES) -c $< -o $@

$(BUILD)/TerminalJ+.rsrc: app/TerminalJ+.rdef app/XColors.rdef
	@mkdir -p $(dir $@)
	$(RC) -o $@ $^

$(APP): $(OBJECTS) $(BUILD)/TerminalJ+.rsrc
	@echo "  LINK $@"
	@$(CXX) $(LINK_FLAGS) $(LINK_BEGIN) $(OBJECTS) $(LIBDIRS) $(LIBS) \
		$(LINK_END) -o $@
	$(XRES) -o $@ $(BUILD)/TerminalJ+.rsrc

# The translations of Terminal, for the signature of TerminalJ+.
$(BUILD)/catalogs/%.catalog: catalogs/%.catkeys
	@mkdir -p $(dir $@)
	sed '1s/x-vnd.Haiku-Terminal/$(SIGNATURE)/' $< > $(BUILD)/catalogs/$*.catkeys
	$(LINKCATKEYS) -l $* -s $(SIGNATURE) -o $@ $(BUILD)/catalogs/$*.catkeys

HPKG = $(BUILD)/terminalj_plus-$(PKG_VERSION)-$(PKG_ARCH).hpkg
ROOT = $(BUILD)/hpkg

hpkg: $(APP) $(CATALOGS) packaging/PackageInfo.in
	rm -rf $(ROOT) $(HPKG)
	mkdir -p $(ROOT)/apps $(ROOT)/data/deskbar/menu/Applications \
		$(ROOT)/data/locale/catalogs/$(SIGNATURE) $(ROOT)/data/licenses
	$(STRIP) -o "$(ROOT)/apps/TerminalJ+" $(APP)
	$(XRES) -o "$(ROOT)/apps/TerminalJ+" $(BUILD)/TerminalJ+.rsrc
	# The executable bit does not survive strip -o everywhere (the 32-bit
	# package had none, and TerminalJ+ could not be launched).
	chmod 755 "$(ROOT)/apps/TerminalJ+"
	$(ADDATTR) -t mime BEOS:TYPE application/x-vnd.Be-elfexecutable "$(ROOT)/apps/TerminalJ+"
	$(ADDATTR) -t mime BEOS:APP_SIG application/$(SIGNATURE) "$(ROOT)/apps/TerminalJ+"
	python3 -I tools/rdef_icon.py app/TerminalJ+.rdef $(BUILD)/TerminalJ+.hvif
	$(ADDATTR) -f $(BUILD)/TerminalJ+.hvif -c VICN BEOS:ICON "$(ROOT)/apps/TerminalJ+"
	cp $(CATALOGS) $(ROOT)/data/locale/catalogs/$(SIGNATURE)/
	cp LICENSE "$(ROOT)/data/licenses/TerminalJ+"
	ln -s ../../../../apps/TerminalJ+ "$(ROOT)/data/deskbar/menu/Applications/TerminalJ+"
	sed -e 's/@VERSION@/$(PKG_VERSION)/g' -e 's/@ARCH@/$(PKG_ARCH)/' \
		-e 's/@REQUIRES@/$(PKG_REQUIRES)/' packaging/PackageInfo.in > $(ROOT)/.PackageInfo
	$(PKG_TOOL) create -C $(ROOT) $(HPKG)
	@echo "-> $(HPKG)"

clean:
	rm -rf $(BUILD)

.PHONY: all hpkg clean
