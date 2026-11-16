# TerminalJ+: the RenkuOS Terminal with inline input methods (Mozc).
#
#   make            cross-build build/TerminalJ+
#   make hpkg       -> build/terminalj_plus-<version>-x86_64.hpkg
#
# The cross build uses the RenkuOS tree in $(RENKU) (generated/ must exist).

VERSION = 1.0.0
PKG_VERSION = $(VERSION)-1
SIGNATURE = x-vnd.RenkuOS-TerminalJPlus
BUILD = build

RENKU ?= $(HOME)/renku
GEN = $(RENKU)/generated
CROSS = $(GEN)/cross-tools-x86_64/bin/x86_64-unknown-haiku-
CXX = $(CROSS)g++
CC = $(CROSS)gcc
STRIP = $(CROSS)strip
DEVEL = $(GEN)/objects/haiku/x86_64/packaging/packages_build/regular/hpkg_-haiku_devel.hpkg/contents/develop
HDR = $(DEVEL)/headers
REL = $(GEN)/objects/haiku/x86_64/release
GCCLIB = $(wildcard $(GEN)/build_packages/gcc_syslibs-*-x86_64/lib)
TOOLS = $(GEN)/objects/linux/x86_64/release/tools
HOSTENV = env LD_LIBRARY_PATH=$(GEN)/objects/linux/lib
RC = $(TOOLS)/rc/rc
XRES = $(TOOLS)/xres
ADDATTR = $(HOSTENV) $(TOOLS)/addattr/addattr
LINKCATKEYS = $(HOSTENV) $(TOOLS)/locale/linkcatkeys
PKG_TOOL = $(HOSTENV) $(TOOLS)/package/package

INCLUDES = -Iapp -idirafter $(HDR) -idirafter $(HDR)/posix -idirafter $(HDR)/gnu \
	-idirafter $(HDR)/bsd -idirafter $(HDR)/os \
	$(foreach d,$(wildcard $(HDR)/os/*/),-idirafter $(d)) \
	-idirafter $(HDR)/os/add-ons/graphics -idirafter $(HDR)/private \
	-idirafter $(HDR)/private/shared -idirafter $(HDR)/private/libroot \
	-idirafter $(HDR)/private/system -idirafter $(HDR)/private/system/arch/x86_64 \
	-idirafter $(HDR)/private/textencoding -idirafter $(HDR)/private/kernel \
	-idirafter $(HDR)/private/tracker
FLAGS = -O2 -D_DEFAULT_SOURCE -Wall -Wno-multichar -Wno-sign-compare \
	-Wno-unused-parameter
LIBDIRS = -B$(DEVEL)/lib -L$(DEVEL)/lib -L$(REL)/kits -L$(REL)/kits/tracker \
	-L$(REL)/kits/textencoding -L$(REL)/kits/translation -L$(REL)/kits/shared \
	-L$(REL)/kits/locale -L$(REL)/system/libroot -L$(GCCLIB)
# libgcc_s holds the unwinder: without it exceptions are not caught.
LIBS = -lbe -llocalestub -lshared -ltracker -ltranslation -ltextencoding -lgcc_s

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
	@$(CXX) $(OBJECTS) $(LIBDIRS) $(LIBS) -o $@
	$(XRES) -o $@ $(BUILD)/TerminalJ+.rsrc

# The translations of Terminal, for the signature of TerminalJ+.
$(BUILD)/catalogs/%.catalog: catalogs/%.catkeys
	@mkdir -p $(dir $@)
	sed '1s/x-vnd.Haiku-Terminal/$(SIGNATURE)/' $< > $(BUILD)/catalogs/$*.catkeys
	$(LINKCATKEYS) -l $* -s $(SIGNATURE) -o $@ $(BUILD)/catalogs/$*.catkeys

HPKG = $(BUILD)/terminalj_plus-$(PKG_VERSION)-x86_64.hpkg
ROOT = $(BUILD)/hpkg

hpkg: $(APP) $(CATALOGS) packaging/PackageInfo.in
	rm -rf $(ROOT) $(HPKG)
	mkdir -p $(ROOT)/apps $(ROOT)/data/deskbar/menu/Applications \
		$(ROOT)/data/locale/catalogs/$(SIGNATURE) $(ROOT)/data/licenses
	$(STRIP) -o "$(ROOT)/apps/TerminalJ+" $(APP)
	$(XRES) -o "$(ROOT)/apps/TerminalJ+" $(BUILD)/TerminalJ+.rsrc
	$(ADDATTR) -t mime BEOS:TYPE application/x-vnd.Be-elfexecutable "$(ROOT)/apps/TerminalJ+"
	$(ADDATTR) -t mime BEOS:APP_SIG application/$(SIGNATURE) "$(ROOT)/apps/TerminalJ+"
	cp $(CATALOGS) $(ROOT)/data/locale/catalogs/$(SIGNATURE)/
	cp LICENSE "$(ROOT)/data/licenses/TerminalJ+"
	ln -s ../../../../apps/TerminalJ+ "$(ROOT)/data/deskbar/menu/Applications/TerminalJ+"
	sed 's/@VERSION@/$(PKG_VERSION)/g' packaging/PackageInfo.in > $(ROOT)/.PackageInfo
	$(PKG_TOOL) create -C $(ROOT) $(HPKG)
	@echo "-> $(HPKG)"

clean:
	rm -rf $(BUILD)

.PHONY: all hpkg clean
