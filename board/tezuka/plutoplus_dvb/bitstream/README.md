# plutoplus_dvb bitstream

`tezuka.xsa` here is built from kazushinjo/maia-sdr-plutoplus-dvb, branch
`plutoplus-dvb` (F5OEO maia-sdr `refactor` + project `plutoplus_dvb`: Pluto+
xc7z010 with the dvb_fpga DVB-S2 encoder, RRC x4 and TX FIR x8, no Maia-SDR,
1R1T). See `maia-hdl/projects/tezuka/PLUTOPLUS_DVB.md` there for the Vivado
2025.2 build; copy its `tezuka.xsa` to this directory.

`fsbl.elf` and `overclock/` are copies of `../../plutoplus/bitstream/` (same
board and PS7 configuration).

Until `tezuka.xsa` is present, `plutoplus_shonan_dvb` does not build.
