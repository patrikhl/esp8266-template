#  project settings
TARGET  = app
FLAVOR  = debug
PORT    = /dev/ttyUSB0
MODULES = user
INCDIR  = 

# compile using docker image?
USE_DOCKER = 1

# no configurable options below
ifeq ($(USE_DOCKER),1)
MK = docker run --rm -v $(shell pwd):/home --device $(PORT) esp-open-sdk
endif

MK += make -f .makefile
VARS = TARGET=$(TARGET) FLAVOR=$(FLAVOR) ESPPORT=$(PORT) MODULES='$(MODULES)' \
	   EXTRA_INCDIR='$(INCDIR)'

all:
	$(MK) $@ $(VARS)

clean:
	$(MK) $@

flash:
	$(MK) $@ $(VARS)
