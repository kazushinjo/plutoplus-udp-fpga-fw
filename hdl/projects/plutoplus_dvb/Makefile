####################################################################################
## Copyright (c) 2018 - 2023 Analog Devices, Inc.
### SPDX short identifier: BSD-1-Clause
####################################################################################
# Pluto+ (xc7z010) with the DVB-S2 TX chain.
# Normally run through build_plutoplus_dvb.sh.

PROJECT_NAME ?= plutoplus_dvb

export PROJECT_NAME

M_DEPS += ../../adi-hdl/library/common/ad_iobuf.v
M_DEPS += ../../adi-hdl/library/axi_ad9361/axi_ad9361_delay.tcl
LIB_DEPS += xilinx/util_clkdiv
LIB_DEPS += axi_ad9361
LIB_DEPS += util_rfifo
LIB_DEPS += util_wfifo
LIB_DEPS += axi_dmac
LIB_DEPS += util_pack/util_cpack2
LIB_DEPS += util_pack/util_upack2

DEST ?= ../../../plutoplus_dvb_out
include ../../adi-hdl/projects/scripts/project-xilinx.mk

build_project: $(PROJECT_NAME).xpr

clean:
	bash -c "rm -rf build $(PROJECT_NAME).*"
	bash -c "rm -f *.log *.jou *.str *.xpr *.xsa"

install:
	bash -c "mkdir -p $(DEST) && cp -f $(PROJECT_NAME).sdk/system_top.xsa $(DEST)/$(notdir $(CURDIR)).xsa"

all: build_project install

.PHONY: build_project install all clean
