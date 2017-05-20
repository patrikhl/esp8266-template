# Makefile for ESP8266 projects
# based on: https://github.com/esp8266/source-code-examples
# - modified by patrikhl
#
# Thanks to:
# - zarya
# - Jeroen Domburg (Sprite_tm)
# - Christian Klippel (mamalala)
# - Tommie Gannert (tommie)
#
# Changelog:
# - 2014-10-06: Changed the variables to include the header file directory
# - 2014-10-06: Added global var for the Xtensa tool root
# - 2014-11-23: Updated for SDK 0.9.3
# - 2014-12-25: Replaced esptool by esptool.py
# - 2017-05-18: Added support for compiling .S files
#				Split makefile into two (for use with docker)
#				Added flavor opton (debug / release)
#				- debug will automatically compile esp-gdbstub

# Output directors to store intermediate compiled files
# relative to the project directory
BUILD_BASE	= build/$(FLAVOR)
FW_BASE		= firmware

# base directory for the compiler
XTENSA_TOOLS_ROOT ?= /opt/esp/xtensa-lx106-elf/bin

# base directory of the ESP8266 SDK package, absolute
SDK_BASE	?= /opt/esp/sdk

# esptool.py path
ESPTOOL		?= esptool.py

# libraries used in this project, mainly provided by the SDK
LIBS		= c gcc hal pp phy net80211 lwip wpa main

# compiler flags using during compilation of source files
CFLAGS		= -Wpointer-arith -Wundef -Werror -Wl,-EL \
	          -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals \
			  -D__ets__ -DICACHE_FLASH -D$(shell echo $(FLAVOR) | tr a-z A-Z)

# linker flags used to generate the main object file
LDFLAGS		= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static

# copy to 'local varaible'
MMODULES = $(MODULES)

# set stuff based on flavor
ifeq ($(FLAVOR),debug)
MMODULES += gdbstub
CFLAGS   += -Og -ggdb
LDFLAGS  += -ggdb
else
CFLAGS   += -Os -O2
endif

# linker script used for the above linkier step
LD_SCRIPT	= eagle.app.v6.ld

# various paths from the SDK used in this project
SDK_LIBDIR	= lib
SDK_LDDIR	= ld
SDK_INCDIR	= include include/json

# addresses for firmware files
FW_FILE_1_ADDR	= 0x00000
FW_FILE_2_ADDR	= 0x10000

# select which tools to use as compiler, librarian and linker
CC		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
AR		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc

####
#### no user configurable options below here
####
SRC_DIR		:= $(MMODULES)
BUILD_DIR	:= $(addprefix $(BUILD_BASE)/,$(MMODULES))

SDK_LIBDIR	:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR	:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))

SRC_C		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
SRC_S		:= $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.S))
OBJ			:= $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC_C)) \
			   $(patsubst %.S,$(BUILD_BASE)/%.o,$(SRC_S))
LIBS		:= $(addprefix -l,$(LIBS))
APP_AR		:= $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT	:= $(addprefix $(BUILD_BASE)/,$(TARGET).out)

LD_SCRIPT	:= $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

INCDIR			:= $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR	:= $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR	:= $(addsuffix /include,$(INCDIR))

FW_FILE_1	:= $(addprefix $(FW_BASE)/,$(FW_FILE_1_ADDR).bin)
FW_FILE_2	:= $(addprefix $(FW_BASE)/,$(FW_FILE_2_ADDR).bin)

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)
vpath %.S $(SRC_DIR)

define compile-objects-c
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS) -c $$< -o $$@
endef
define compile-objects-S
$1/%.o: %.S
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS) -c $$< -o $$@
endef


.PHONY: all checkdirs flash clean

all: checkdirs $(TARGET_OUT) $(FW_FILE_1) $(FW_FILE_2)

$(FW_BASE)/%.bin: $(TARGET_OUT) | $(FW_BASE)
	$(vecho) "FW $(FW_BASE)/"
	$(Q) $(ESPTOOL) elf2image -o $(FW_BASE)/ $(TARGET_OUT)

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@

$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

checkdirs: $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(Q) mkdir -p $@

$(FW_BASE):
	$(Q) mkdir -p $@

flash: $(FW_FILE_1) $(FW_FILE_2)
	$(ESPTOOL) --port $(ESPPORT) write_flash $(FW_FILE_1_ADDR) $(FW_FILE_1) $(FW_FILE_2_ADDR) $(FW_FILE_2)

clean:
	$(Q) rm -rf $(FW_BASE) $(BUILD_BASE)


$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects-c,$(bdir))))
$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects-S,$(bdir))))