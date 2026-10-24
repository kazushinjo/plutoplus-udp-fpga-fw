# plutoplus-0.2.4-BOOT.bin

Pluto+ 用の SD 起動の BOOT.bin。F5OEO/tezuka_fw のリリース **0.2.4**(2026-01-10、コミット 365ea2e)の
`plutoplus.zip` の `sdimg/BOOT.bin` そのもの(1,678,828 バイト、md5 a6ce0ad427d714ca554f8fe555d81b76)。

中身: FSBL + 0.2.4 のビットストリーム(Maia-SDR)+ **U-Boot 2016.07**。

## なぜ使うか

今の tezuka(v0.3.x)が作る BOOT.bin(FSBL + U-Boot 2025.01、ビットストリームなし)は、
この Pluto+(SD-H=3V3、URST=MIO46)では SD カードから起動しなかった(緑 LED のみ、FPGA の DONE(青)なし、USB も出ない)。
FSBL は新旧で書き込まれる中身が同じなので、原因は U-Boot 2025.01 の側と判断した(シリアルで原因は未確認)。

0.2.4 の U-Boot は SD カードの `uEnv.txt`(このビルドのもの)を読み込み、このビルドの
ビットストリーム(`system_top.bin`)・デバイスツリー・ramdisk を読んで起動する。
ただし LZMA 圧縮の uImage は開けないので、`../postimage-legacy-sd.sh` がカーネルを無圧縮の uImage にする。

## ライセンス

- U-Boot 2016.07(ADI u-boot-xlnx): GPL-2.0+。ソースは tezuka_fw 0.2.4 が使っていた u-boot-xlnx(tezuka_fw の 365ea2e の設定を参照)
- FSBL: Xilinx(AMD)の FSBL のライセンス
- ビットストリーム: maia-sdr(MIT)・ADI HDL など。起動後は u-boot がこのビルドのビットストリームを読み直す
