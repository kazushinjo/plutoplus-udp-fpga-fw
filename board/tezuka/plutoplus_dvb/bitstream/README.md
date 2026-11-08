# plutoplus_dvb のビットストリーム

**日本語** | [English](#english)

ここに置く `plutoplus_dvb.xsa` は、kazushinjo/Plutoplus-FPGA-firm のブランチ `main` からビルドしたもの。
中身は F5OEO/maia-sdr の `refactor` にプロジェクト `plutoplus_dvb` を足したもので、
Pluto+(xc7z010)に dvb_fpga の DVB-S2 エンコーダ・RRC ×4・TX FIR ×8 を入れ、Maia-SDR を外し、1R1T にしてある。

Vivado 2025.2 でのビルド手順は、そのリポジトリの `hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md`。
できた `plutoplus_dvb.xsa` をこのフォルダに置く(レポートは `reports/` に)。

`fsbl.elf` と `overclock/` は `../../plutoplus/bitstream/` の写し(基板と PS7 の設定が同じため)。

`plutoplus_dvb.xsa` を置くまでは、`plutoplus_shonan_dvb` はビルドできない。

---

# English

## The plutoplus_dvb bitstream

The `plutoplus_dvb.xsa` placed here is built from the branch `main` of kazushinjo/Plutoplus-FPGA-firm.
It is the `refactor` branch of F5OEO/maia-sdr with the project `plutoplus_dvb` added:
the Pluto+ (xc7z010) with the dvb_fpga DVB-S2 encoder, RRC x4 and TX FIR x8, Maia-SDR removed, and 1R1T.

The build steps with Vivado 2025.2 are in `hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md` of that repository.
Put the resulting `plutoplus_dvb.xsa` in this folder (and the reports in `reports/`).

`fsbl.elf` and `overclock/` are copies of `../../plutoplus/bitstream/` (the board and PS7 settings are the same).

`plutoplus_shonan_dvb` cannot be built until `plutoplus_dvb.xsa` is in place.
