# plutoplus_dvb のビットストリーム

ここに置く `plutoplus_dvb.xsa` は、kazushinjo/Plutoplus-FPGA-firm のブランチ `plutoplus-dvb` からビルドしたもの。
中身は F5OEO/maia-sdr の `refactor` にプロジェクト `plutoplus_dvb` を足したもので、
Pluto+(xc7z010)に dvb_fpga の DVB-S2 エンコーダ・RRC ×4・TX FIR ×8 を入れ、Maia-SDR を外し、1R1T にしてある。

Vivado 2025.2 でのビルド手順は、そのリポジトリの `hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md`。
できた `plutoplus_dvb.xsa` をこのフォルダに置く(レポートは `reports/` に)。

`fsbl.elf` と `overclock/` は `../../plutoplus/bitstream/` の写し(基板と PS7 の設定が同じため)。

`plutoplus_dvb.xsa` を置くまでは、`plutoplus_shonan_dvb` はビルドできない。
