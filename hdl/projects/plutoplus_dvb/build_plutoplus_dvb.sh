#!/bin/bash
# Build the plutoplus_dvb bitstream: Pluto+ (xc7z010) with the DVB-S2 TX
# chain (dvb_fpga encoder + RRC + TX FIR). See
# PLUTOPLUS_DVB.md next to this script.
#
# Usage (on an x86_64 Linux PC with Vivado 2025.2):
#   VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
#     hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh [output-dir]
#
# Output: <output-dir>/plutoplus_dvb.xsa plus utilization and timing reports.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TOP="$(cd "${HERE}/../../.." && pwd)"
OUT="$(mkdir -p "${1:-${TOP}/plutoplus_dvb_out}" && cd "${1:-${TOP}/plutoplus_dvb_out}" && pwd)"
VIVADO_SETTINGS="${VIVADO_SETTINGS:-/tools/Xilinx/2025.2/Vivado/settings64.sh}"

if [ ! -f "${VIVADO_SETTINGS}" ]; then
	echo "Vivado settings not found: ${VIVADO_SETTINGS}" >&2
	echo "Set VIVADO_SETTINGS to the settings64.sh of your Vivado 2025.2 install." >&2
	exit 1
fi

# adi-hdl and dvb_fpga (with its own third_party submodules) are all that is
# needed. dvb_fpga then gets the local patches in hdl/patches: without
# them the encoder expects its config through inline_config_adapter instead
# of syncing on the 0xB8 + MODCOD header in the stream itself.
cd "${TOP}"
git submodule update --init hdl/adi-hdl
git submodule update --init --recursive hdl/dvb_fpga
make -C hdl patch-dvb_fpga

# shellcheck source=/dev/null
source "${VIVADO_SETTINGS}"
export ADI_IGNORE_VERSION_CHECK=1
export PROJECT_NAME=plutoplus_dvb

cd "${HERE}"
# The ADI rule for the .xsa builds the ADI library IP it needs, creates the
# Vivado project and runs synthesis/implementation.
make "${PROJECT_NAME}.sdk/system_top.xsa"
# DEST goes through the environment: ADI's project-xilinx.mk folds make
# command-line variables into PROJECT_NAME, which breaks the install rule.
DEST="${OUT}" make install

RUNS="${HERE}/${PROJECT_NAME}.runs/impl_1"
cp -f "${RUNS}"/*utilization_placed.rpt "${OUT}/" 2>/dev/null || true
# The bitstream comes from the post-route physopt step. The routed report is
# written before hold_fix.tcl reroutes, so it can show a hold violation that
# the final design does not have.
cp -f "${RUNS}"/*timing_summary_postroute_physopted.rpt "${OUT}/" 2>/dev/null || true
cp -f "${RUNS}"/*timing_summary_routed.rpt "${OUT}/" 2>/dev/null || true
cp -f "${HERE}"/*.log "${OUT}/" 2>/dev/null || true

echo
echo "Done: ${OUT}/plutoplus_dvb.xsa"
grep -m1 -A6 "Design Timing Summary" "${OUT}"/*timing_summary_postroute_physopted.rpt 2>/dev/null || true
grep -E "^\| (Slice LUTs|Block RAM Tile|DSPs) " "${OUT}"/*utilization_placed.rpt 2>/dev/null || true
