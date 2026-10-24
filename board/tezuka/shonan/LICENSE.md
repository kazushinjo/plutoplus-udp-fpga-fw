# ライセンス(plutoplus_shonan)

このファームは、いくつものソフトウェアを組み合わせて作っている。部品ごとのライセンスは次のとおり。

## 全体(tezuka_fw と、このリポジトリで足したもの)

- tezuka_fw(F5OEO and contributors): **GNU General Public License v3.0**(リポジトリ直下の [LICENSE](../../../LICENSE))
- このリポジトリで足した設定・スクリプト・文書
  (`configs/plutoplus_shonan_defconfig`、`board/tezuka/shonan/` の post-build.sh・lighttpd.conf・S89patchfirm・README.md など、
  `.github/workflows/main.yml` の変更): tezuka_fw に合わせて **GPL-3.0**。Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)

## ファームに入る OSS パッケージ

Linux カーネル(GPL-2.0)、U-Boot(GPL-2.0+)、BusyBox(GPL-2.0)、glibc(LGPL-2.1+)、libiio(LGPL-2.1+)、
PHP(PHP-3.01)、lighttpd(BSD-3-Clause)、FFmpeg(LGPL-2.1+、GPL 部品を有効にした場合は GPL-2.0+)、
OpenSSL(Apache-2.0)、maia-sdr ほか、Buildroot が組み込む各パッケージは、それぞれのライセンスに従う。

- 全パッケージのライセンス文と SBOM(CycloneDX)は、ビルドのたびに Buildroot の `legal-info` で集めている。
  プレリリースの `plutoplus_shonan-licenses.zip`(`bom/licenses/`・`bom/sbom.json`)に入っている。
- 起動中の Pluto+ の USB ドライブにも `LICENSE.html` がある(tezuka の仕組み)。
- GPL・LGPL の部品のソースは、Buildroot の各パッケージの取得元(`legal-info` の manifest に一覧)と、
  このリポジトリ(defconfig・パッチ・overlay)から得られる。

## SD 起動用の BOOT.bin(tezuka 0.2.4)

`board/tezuka/shonan/legacy-boot/plutoplus-0.2.4-BOOT.bin` は F5OEO/tezuka_fw リリース 0.2.4(コミット 365ea2e)の
`plutoplus.zip` の `sdimg/BOOT.bin` をそのまま使っている(SD 用の BOOT.bin はこれに置き換わる)。

| 中身 | ライセンス |
|---|---|
| U-Boot 2016.07(ADI u-boot-xlnx) | GPL-2.0+。ソースは tezuka_fw 0.2.4 が使っていた u-boot-xlnx |
| FSBL | Xilinx(AMD)の FSBL のライセンス |
| ビットストリーム(0.2.4 の Maia-SDR 版) | maia-sdr(MIT)・ADI HDL など。起動後は U-Boot がこのビルドのビットストリームを読み直す |

## FPGA 版(plutoplus_shonan_dvb)で増えるもの

| 部品 | ライセンス | 備考 |
|---|---|---|
| pluto_stream・pluto_mqtt_ctrl(F5OEO/pluto-ori-ps `tezukadvb`) | GPL-2.0+ | tezuka の `package/pluto_stream` でソースからビルド |
| plutoplus_dvb ビットストリーム(`board/tezuka/plutoplus_dvb/bitstream/tezuka.xsa`) | 下の各ライセンスの組み合わせ | kazushinjo/maia-sdr-plutoplus-dvb からビルド |
| ・maia-hdl のプロジェクト(F5OEO/maia-sdr) | MIT | Copyright (c) Daniel Estevez ほか。この版の変更も MIT |
| ・ADI HDL(analogdevicesinc/hdl) | ADI の各ライセンス(ファイルごと、BSD 系・GPL など) | |
| ・dvb_fpga(Suoto / Open Research Institute) | **CERN-OHL-W v2** | これを使ったハードウェアを作るときは、ソースの場所 https://github.com/phase4ground/dvb_fpga を製品の外装に見えるように書くこと(CERN-OHL-W v2 4.1 項) |
| `overlay_dvb/root/pluto_dvb.fpga`(差し替えスクリプト) | GPL-3.0 | Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX) |

## datvplutofrm から持ってきた DATV の部品

`board/tezuka/shonan/overlay/` の次のものは、F5OEO/datvplutofrm(F5OEO、F5UII ほか)を
kazushinjo/datvplutofrm の `v0.39-shonan` ブランチで手直ししたものを、そのまま持ってきている。

| 部品 | 作者 | ライセンス |
|---|---|---|
| `root/udpts.sh`、`rtmppluto.sh`、`watchudp.sh`、`strategy.sh`、`report*.sh`、`readconfig_from_env.sh`、`writeconfig_to_env.sh`、`update_frm_reboot.sh`、`pluto_temp.sh`、`etc/init.d/S90datv`、`etc/php.ini` | F5OEO、F5UII ほか(手直し: Kazu Shinjo (JA6FUF/JH1XHX)) | 元リポジトリにライセンスの明記なし |
| `www/` の PHP・画像・`lib/wf.js`・`lib/u16Websocket.js`・`lib/tooltip.js` | F5OEO、F5UII ほか(手直し: Kazu Shinjo (JA6FUF/JH1XHX)) | 元リポジトリにライセンスの明記なし |
| `root/pluto_dvb`(ビルド済みの実行ファイル) | F5OEO | 元リポジトリにライセンスの明記なし。ソースは公開されているものを見つけられていない |

元の F5OEO/datvplutofrm には LICENSE ファイルが無く、ライセンスが決められていない。
このため、これらの部品を含むこのファームを**公開・配布する前に、作者(F5OEO)の許可を得るか、ライセンスを確認すること**。
このリポジトリは非公開で、個人の利用を前提にしている。

## 同梱しているサードパーティのライブラリ

| 部品 | 版 | ライセンス | 著作権 |
|---|---|---|---|
| TSDuck(`usr/bin/tsp`、`usr/lib/tsduck.so`、`usr/lib/tsplugin_*.so`) | datvplutofrm 同梱のビルド済み | BSD-2-Clause | Copyright (c) Thierry Lelegard |
| jQuery(`www/lib/jquery-3.5.1.min.js`) | 3.5.1 | MIT | (c) JS Foundation and other contributors |
| Chart.js(`www/Chart.bundle.js`) | 2.9.3 | MIT | (c) 2019 Chart.js Contributors |
| chartjs-plugin-labels(`www/lib/chartjs-plugin-labels.js`) | 1.1.0 | MIT | Chen, Yi-Cyuan |
| Socket.IO クライアント(`www/lib/socket.io-2.3.0.min.js`) | 2.3.0 | MIT | (c) 2014-2019 Guillermo Rauch |
| js-cookie(`www/lib/js.cookie.min.js`) | 3.0.0-rc.1 | MIT | Klaus Hartl & Fagner Brack |

### BSD-2-Clause(TSDuck)

```
Copyright (c) Thierry Lelegard
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

### MIT(jQuery、Chart.js、chartjs-plugin-labels、Socket.IO、js-cookie)

上の表の各著作権者について:

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
