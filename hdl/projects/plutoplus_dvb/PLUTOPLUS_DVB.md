# plutoplus_dvb ビットストリームの作り方

**日本語** | [English](#english)

Pluto+(Zynq-7010)用の FPGA を、**DVB-S2 送信回路(dvb_fpga)を入れた構成**で作る。
Maia-SDR の機能(ウォーターフォール表示・IQ 録音など)は入っていない。
できた `plutoplus_dvb.xsa` は、kazushinjo/plutoplus-udp-fpga-fw の `plutoplus_udp_fpga` ファームで使う。

由来: F5OEO/maia-sdr の `refactor` ブランチ(5f28808、2026-10-20)にある tezuka 用 FPGA プロジェクトから、送信に使う部分だけを取り出した。変更はブランチ `main`。

## 構成

| 項目 | 由来の F5OEO tezuka の plutoplus | plutoplus_dvb(この版) |
|---|---|---|
| Maia-SDR(ウォーターフォール・録音) | あり | **なし** |
| DVB-S2 送信回路(dvb_fpga エンコーダ + RRC ×2) | なし | **あり**(`dvb`) |
| TX FIR ×8 補間 | なし | **あり**(`txfir`) |
| AD9361 インターフェース | 2R2T | **1R1T**(`mode1r1t`) |
| DDS(試験用トーン) | なし | なし |
| 掃引(sweeper)、受信 8 ビット化(cs12_cs8) | あり | なし(Maia-SDR の経路に依存するため) |

7010 の資源: LUT 17,600 / DSP 80 / BRAM36 60。F5OEO tezuka_fw の `doc/fpga_usage.md`(plutoskyr2 の実測)からの見積もりは
LUT 約 14,000・DSP 約 70・BRAM36 約 27 で収まる見込み。**実際の値はビルド後のレポートで確かめる**。

このリポジトリには plutoplus_dvb を作るのに使うファイルだけを残している(2026-10-28 に整理。
整理前の F5OEO 版そのままの状態は F5OEO/maia-sdr の `refactor` ブランチを参照。
フォルダ名も元の `maia-hdl` から `hdl` に、`projects/tezuka` を `projects/plutoplus_dvb` に、`nomaia.tcl` を `dma.tcl` に変え、
できるファイルも `tezuka.xsa` から `plutoplus_dvb.xsa` にした)。

| 場所 | 中身 |
|---|---|
| `hdl/projects/plutoplus_dvb/` | `build_plutoplus_dvb.sh`(ビルド用スクリプト)、`Makefile`、`system_project.tcl`(デバイス `xc7z010clg400-1`)、`system_bd.tcl`(読み込む回路の順番)、`hold_fix.tcl`(Vivado 2025 のホールド違反対策)、この手順書 |
| `hdl/projects/boards/plutoplus_dvb/` | Pluto+ 基板の定義(ピン・PS7 設定・最上位回路)。由来の F5OEO tezuka の `boards/plutoplus/` と同じ内容 |
| `hdl/projects/common/` | `xilinx_init.tcl`・`xilinx_ad9361.tcl`(AD9361 まわり、`mode1r1t` で 1R1T)、`dma.tcl`(ADC/DAC の DMA を HP2 へ、HP1 を無効に)、`txfir.tcl`・`interpolator_x8.coe`(TX FIR ×8)、`dvb.tcl`・`rrc_interp_firwin2.coe`(DVB-S2 送信回路) |
| `hdl/patches/dvb_fpga/` | dvb_fpga に当てる修正 2 つ。エンコーダが送られてきたデータの 0xB8 + MODCOD を見て自分で同期するようにする(F5OEO の版で使っている形)。ビルド用スクリプトが自動で当てる |
| `hdl/adi-hdl`・`hdl/dvb_fpga` | サブモジュール(ADI の HDL、DVB-S2 エンコーダ) |

外したもの: Maia-SDR 本体(`maia_hdl`・`ip`・試験)、Web 画面などのソフト(`maia-httpd`・`maia-wasm`・`maia-kmod`)、
ほかの基板(e200・e310・libre・pluto・plutoskyr2 など)、GitHub Actions の設定。

実際にビルドしたときの経緯と、手順どおりに進まなかった点は [BUILD_HISTORY.md](BUILD_HISTORY.md) にある。

## 1. Linux PC の準備(初回だけ)

対象: x86_64 の Ubuntu 22.04 / 24.04。空き容量 100GB 前後、メモリ 16GB 以上が目安。
(Ubuntu 25.10・メモリ 9GB + スワップ 16GB・Vivado 2025.2.1 でもビルドできた。約 52 分。)

```
sudo apt update
sudo apt install -y git make build-essential python3 libtinfo-dev libncurses-dev locales
sudo locale-gen en_US.UTF-8
```

### Vivado 2025.2 を入れる

> 画面の名前・ファイル名は AMD のサイトの変更で少し違うことがある(この手順は実際の画面では未確認)。
> 迷ったら、似た名前のものを選ぶ。

#### (1) AMD のアカウントを作る(初回だけ)

1. https://www.amd.com/en/registration/create-account.html を開く(または AMD のサイト右上の人のアイコン → Create Account)
2. メールアドレス・名前・パスワードを入れて登録し、届いたメールのリンクで有効にする
3. ダウンロードのとき、氏名・住所・会社名(個人なら「Individual」や自分の名前)などを聞かれる。
   これは米国の輸出規制の確認なので、正しく入れる

#### (2) インストーラーをダウンロードする

1. https://www.xilinx.com/support/download.html を開く
2. 上の版のタブで **2025.2** を選ぶ
3. 「**AMD Unified Installer for FPGAs & Adaptive SoCs 2025.2: Linux Self Extracting Web Installer**」(数百 MB の `.bin`)をクリック
4. ログイン → 名前・住所の確認画面 → Download
5. できるファイルの例: `~/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_XXXX_XXXX_Lin64.bin`

これは「Web Installer」なので、本体はインストール中にダウンロードされる(Zynq-7000 だけなら数十 GB の目安、回線によって 1〜数時間)。

#### (3) インストーラーを実行する

```
cd ~/Downloads
chmod +x FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
sudo ./FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
```

画面が出たら、次のように進める。

| 画面(目安) | 選ぶもの |
|---|---|
| Welcome | Next(新しい版があると言われても 2025.2 のまま進める) |
| Select Install Type | AMD アカウントのメールとパスワードを入れ、「Download and Install Now」 |
| Select Product to Install | **Vivado** |
| Select Edition to Install | **Vivado ML Standard**(無料。Zynq-7010 を含む) |
| Vivado ML Standard(部品の選択) | Devices の **Production Devices → SoCs → Zynq-7000** だけにチェック。ほかのデバイス(Artix・Kintex・Spartan・Zynq UltraScale+ など)は外す。Design Tools の Vivado Design Suite は入れたまま。Install Devices for Kria SOMs、Vitis などは不要 |
| Accept License Agreements | 3 つとも I Agree |
| Select Destination Directory | 既定の **`/tools/Xilinx`**。ショートカットや Desktop のアイコンはどちらでもよい |
| Installation Summary | 必要な容量を確かめて Install |

最後に「Install Cable Drivers」と聞かれても不要(JTAG を使わないため)。

#### (4) 入ったか確かめる


```
ls /tools/Xilinx/2025.2/Vivado/settings64.sh
source /tools/Xilinx/2025.2/Vivado/settings64.sh
vivado -version          # 「Vivado v2025.2」と出ればよい
```

別の場所にあれば、その場所を下の `VIVADO_SETTINGS` に指定する。

起動時に `libtinfo.so.5` が無いというエラーが出たら(Ubuntu 24.04):

```
sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
```

Ubuntu 25.10 では `libncurses.so.5` も必要。Vivado 本体を入れ始める前に作っておく。
これが無いとバッチモードの Vivado が `libncurses.so.5: cannot open shared object file` で初期化に失敗し、
インストーラーが後処理(Vitis Model Composer を選んだときの `xlpartinfo.tcl` など)で止まったままになる。

```
sudo ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
```

### このリポジトリを取ってくる

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-fw.git
cd plutoplus-udp-fpga-fw
```

## 2. ビルド

```
VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

- サブモジュール(adi-hdl、dvb_fpga とその third_party)は、スクリプトが自動で取ってきて、dvb_fpga に修正を当てる
- かかる時間の目安: 1〜2 時間(ADI の IP 生成 → 合成 → 配置配線)
- 終わると `~/plutoplus_dvb_out/` に次ができる

| ファイル | 中身 |
|---|---|
| `plutoplus_dvb.xsa` | ビットストリーム入りのハードウェア定義(これをファームに入れる) |
| `system_top_utilization_placed.rpt` | 資源の使用量(LUT・DSP・BRAM) |
| `system_top_timing_summary_postroute_physopted.rpt` | 最終のタイミング(WNS・WHS が負なら不合格) |
| `system_top_timing_summary_routed.rpt` | `hold_fix.tcl` の再配線より前のタイミング(参考。WHS が負でも最終で合っていればよい) |
| `*.log` | Vivado のログ |

最後に、タイミングの要約と LUT・BRAM・DSP の行が表示される。

### 失敗したとき

- `plutoplus_dvb_vivado.log`(`hdl/projects/plutoplus_dvb/`)の最後の ERROR を見る
- やり直す前に片付ける: `cd hdl/projects/plutoplus_dvb && make clean PROJECT_NAME=plutoplus_dvb`
- 資源が足りない(`Placement failed` など)、タイミングが合わないときは、レポートとログを Mac に送って相談

## 3. レポートを確かめる

### 資源(`system_top_utilization_placed.rpt`)

```
grep -E "^\| (Slice LUTs|Slice Registers|Block RAM Tile|DSPs) " ~/plutoplus_dvb_out/system_top_utilization_placed.rpt
```

| 行 | Available(7010) | 見るところ |
|---|---|---|
| Slice LUTs | 17,600 | Util% が 100 未満(見積もりは約 80%) |
| Slice Registers | 35,200 | Util% が 100 未満 |
| Block RAM Tile | 60 | Util% が 100 未満 |
| DSPs | 80 | Util% が 100 未満(見積もりは約 88%) |

100% を超えるときは、そもそも配置配線が失敗している(ログに `Placement failed` など)。

### タイミング(`system_top_timing_summary_postroute_physopted.rpt`)

ビットストリームはこの最終状態から作られる。`system_top_timing_summary_routed.rpt` は `hold_fix.tcl` の再配線より前のものなので、判定には使わない。

```
grep -A6 "Design Timing Summary" ~/plutoplus_dvb_out/system_top_timing_summary_postroute_physopted.rpt
grep -i "timing constraints are" ~/plutoplus_dvb_out/system_top_timing_summary_postroute_physopted.rpt
```

- 表の **WNS(ns)** と **WHS(ns)** が 0 以上ならよい(負ならタイミング違反。実機で誤動作することがある)
- 「All user specified timing constraints are met.」と出ていればよい
- 違反があるときは、2 つのレポートと `plutoplus_dvb_vivado.log` を Mac に送って相談

## 4. Mac へ持っていく

持っていくもの: `~/plutoplus_dvb_out/` の `plutoplus_dvb.xsa`・`system_top_utilization_placed.rpt`・`system_top_timing_summary_postroute_physopted.rpt`
(ログは失敗したときだけ)。

### 方法 A: USB メモリ

```
cp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt /media/$USER/<USBメモリの名前>/
sync
```

Mac では、USB メモリから `~/Downloads/plutoplus_dvb_out/` などにコピーする。

### 方法 B: scp(同じ LAN の場合)

1. Mac で「システム設定 → 一般 → 共有 → リモートログイン」をオンにする
2. Linux から送る(`<Macのユーザー名>` は Mac の `whoami` の結果、`<Macの名前>` は「共有」画面に出る `xxx.local`)

   ```
   ssh <Macのユーザー名>@<Macの名前>.local "mkdir -p ~/Downloads/plutoplus_dvb_out"
   scp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt <Macのユーザー名>@<Macの名前>.local:~/Downloads/plutoplus_dvb_out/
   ```

3. 終わったらリモートログインはオフに戻してよい

## 5. ファームへ入れる

Mac 側の手順は kazushinjo/plutoplus-udp-fpga-fw の `board/tezuka/plutoplus_udp_fpga/README.md`
「FPGA 版 → plutoplus_dvb.xsa ができた後(Mac)」にある。概要:

1. `plutoplus_dvb.xsa` を `~/AppDev/plutoplus-udp-fpga-fw/board/tezuka/plutoplus_dvb/bitstream/` に置いてコミット・push
2. GitHub Actions で `plutoplus_udp_fpga` をビルド → プレリリースから zip を取る
3. SD カードへ書き込み → 実機で確かめる

## ライセンス

- 由来の F5OEO/maia-sdr(`hdl/` の元): MIT(`hdl/LICENSE`)
- ADI HDL(adi-hdl サブモジュール): ADI の各ライセンス(BSD 系・GPL など、ファイルごと)
- dvb_fpga(サブモジュール、Suoto / Open Research Institute): **CERN-OHL-W v2**。
  これを使ったハードウェアを作るときは、ソースの場所 https://github.com/phase4ground/dvb_fpga を
  製品の外装に見えるように書くこと(CERN-OHL-W v2 4.1 項)
- このブランチで足した変更: 元に合わせて MIT。Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)

---

# English

## Building the plutoplus_dvb bitstream

Builds the FPGA for the Pluto+ (Zynq-7010) **with the DVB-S2 transmit chain (dvb_fpga)**.
The Maia-SDR features (waterfall display, IQ recording and so on) are not included.
The resulting `plutoplus_dvb.xsa` is used by the `plutoplus_udp_fpga` firmware in kazushinjo/plutoplus-udp-fpga-fw.

Origin: extracted from the tezuka FPGA project on the `refactor` branch (5f28808, 2026-10-20) of F5OEO/maia-sdr, keeping only the parts used for transmit. Changes are on the branch `main`.

### Configuration

| Item | Original F5OEO tezuka plutoplus | plutoplus_dvb (this version) |
|---|---|---|
| Maia-SDR (waterfall, recording) | Yes | **No** |
| DVB-S2 transmit chain (dvb_fpga encoder + RRC x2) | No | **Yes** (`dvb`) |
| TX FIR x8 interpolation | No | **Yes** (`txfir`) |
| AD9361 interface | 2R2T | **1R1T** (`mode1r1t`) |
| DDS (test tones) | No | No |
| Sweeper, 8-bit RX conversion (cs12_cs8) | Yes | No (they depend on the Maia-SDR path) |

7010 resources: LUT 17,600 / DSP 80 / BRAM36 60. The estimate from `doc/fpga_usage.md` in F5OEO tezuka_fw (measured on plutoskyr2) is
about 14,000 LUTs, 70 DSPs and 27 BRAM36, which should fit. **Check the real numbers in the reports after building.**

This repository keeps only the files used to build plutoplus_dvb (cleaned up on 2026-10-28.
For the unchanged F5OEO state from before the cleanup, see the `refactor` branch of F5OEO/maia-sdr.
The folders were also renamed from `maia-hdl` to `hdl` and from `projects/tezuka` to `projects/plutoplus_dvb`, `nomaia.tcl` became `dma.tcl`,
and the output changed from `tezuka.xsa` to `plutoplus_dvb.xsa`).

| Location | Contents |
|---|---|
| `hdl/projects/plutoplus_dvb/` | `build_plutoplus_dvb.sh` (build script), `Makefile`, `system_project.tcl` (device `xc7z010clg400-1`), `system_bd.tcl` (order of blocks to load), `hold_fix.tcl` (Vivado 2025 hold-violation workaround), this guide |
| `hdl/projects/boards/plutoplus_dvb/` | Pluto+ board definition (pins, PS7 settings, top level). Same as `boards/plutoplus/` in the original F5OEO tezuka |
| `hdl/projects/common/` | `xilinx_init.tcl`, `xilinx_ad9361.tcl` (AD9361 logic, 1R1T with `mode1r1t`), `dma.tcl` (ADC/DAC DMA to HP2, HP1 disabled), `txfir.tcl`, `interpolator_x8.coe` (TX FIR x8), `dvb.tcl`, `rrc_interp_firwin2.coe` (DVB-S2 chain) |
| `hdl/patches/dvb_fpga/` | Two patches for dvb_fpga. They make the encoder synchronize itself on the 0xB8 + MODCOD header in the incoming data (the form used in F5OEO's version). Applied automatically by the build script |
| `hdl/adi-hdl`, `hdl/dvb_fpga` | Submodules (ADI HDL, DVB-S2 encoder) |

Removed: Maia-SDR itself (`maia_hdl`, `ip`, tests), the software such as the web UI (`maia-httpd`, `maia-wasm`, `maia-kmod`),
other boards (e200, e310, libre, pluto, plutoskyr2 and others) and the GitHub Actions settings.

The history of the actual build, and the places where this guide did not work as written, are in [BUILD_HISTORY.md](BUILD_HISTORY.md).

### 1. Preparing the Linux PC (first time only)

Target: x86_64 Ubuntu 22.04 / 24.04. Around 100 GB of free disk space and 16 GB or more of memory are recommended.
(It also built on Ubuntu 25.10 with 9 GB of memory + 16 GB of swap and Vivado 2025.2.1, in about 52 minutes.)

```
sudo apt update
sudo apt install -y git make build-essential python3 libtinfo-dev libncurses-dev locales
sudo locale-gen en_US.UTF-8
```

#### Installing Vivado 2025.2

> Screen and file names may differ slightly as AMD changes its site (these steps were not checked against the actual screens).
> If in doubt, pick the most similar name.

##### (1) Create an AMD account (first time only)

1. Open https://www.amd.com/en/registration/create-account.html (or the person icon at the top right of the AMD site → Create Account)
2. Register with your email address, name and password, then activate the account with the link in the email
3. The download asks for your full name, address and company (for an individual, "Individual" or your own name).
   This is a US export-control check, so enter it correctly

##### (2) Download the installer

1. Open https://www.xilinx.com/support/download.html
2. Select **2025.2** in the version tabs at the top
3. Click "**AMD Unified Installer for FPGAs & Adaptive SoCs 2025.2: Linux Self Extracting Web Installer**" (a `.bin` of a few hundred MB)
4. Log in → confirm your name and address → Download
5. Example of the resulting file: `~/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_XXXX_XXXX_Lin64.bin`

This is a web installer, so the main part is downloaded during installation (tens of GB for Zynq-7000 alone, one to several hours depending on the connection).

##### (3) Run the installer

```
cd ~/Downloads
chmod +x FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
sudo ./FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
```

When the window appears, proceed as follows.

| Screen (approximate) | Choose |
|---|---|
| Welcome | Next (stay on 2025.2 even if told a newer version exists) |
| Select Install Type | Enter your AMD account email and password, "Download and Install Now" |
| Select Product to Install | **Vivado** |
| Select Edition to Install | **Vivado ML Standard** (free, includes Zynq-7010) |
| Vivado ML Standard (component selection) | Under Devices, check only **Production Devices → SoCs → Zynq-7000**. Uncheck the other devices (Artix, Kintex, Spartan, Zynq UltraScale+ and so on). Keep Vivado Design Suite under Design Tools. Install Devices for Kria SOMs, Vitis and the like are not needed |
| Accept License Agreements | I Agree on all three |
| Select Destination Directory | The default **`/tools/Xilinx`**. Shortcuts and Desktop icons are optional |
| Installation Summary | Check the required space and click Install |

If asked to "Install Cable Drivers" at the end, it is not needed (JTAG is not used).

##### (4) Confirm the installation

```
ls /tools/Xilinx/2025.2/Vivado/settings64.sh
source /tools/Xilinx/2025.2/Vivado/settings64.sh
vivado -version          # should print "Vivado v2025.2"
```

If it is somewhere else, give that location in `VIVADO_SETTINGS` below.

If startup fails with a missing `libtinfo.so.5` (Ubuntu 24.04):

```
sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
```

Ubuntu 25.10 also needs `libncurses.so.5`. Create it before starting the Vivado installation.
Without it, batch-mode Vivado fails to initialize with `libncurses.so.5: cannot open shared object file`,
and the installer hangs in its post-install steps (such as `xlpartinfo.tcl` when Vitis Model Composer is selected).

```
sudo ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
```

#### Getting this repository

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-fw.git
cd plutoplus-udp-fpga-fw
```

### 2. Build

```
VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

- The script fetches the submodules (adi-hdl, dvb_fpga and its third_party) and patches dvb_fpga automatically
- Expected time: 1 to 2 hours (ADI IP generation → synthesis → place and route)
- When finished, `~/plutoplus_dvb_out/` contains:

| File | Contents |
|---|---|
| `plutoplus_dvb.xsa` | Hardware definition including the bitstream (this goes into the firmware) |
| `system_top_utilization_placed.rpt` | Resource use (LUT, DSP, BRAM) |
| `system_top_timing_summary_postroute_physopted.rpt` | Final timing (fails if WNS or WHS is negative) |
| `system_top_timing_summary_routed.rpt` | Timing before the `hold_fix.tcl` reroute (reference only; a negative WHS here is fine if the final report passes) |
| `*.log` | Vivado logs |

At the end, the timing summary and the LUT, BRAM and DSP lines are printed.

#### If it fails

- Look at the last ERROR in `plutoplus_dvb_vivado.log` (in `hdl/projects/plutoplus_dvb/`)
- Clean up before retrying: `cd hdl/projects/plutoplus_dvb && make clean PROJECT_NAME=plutoplus_dvb`
- If resources run out (`Placement failed` and the like) or timing fails, send the reports and logs to the Mac and discuss

### 3. Checking the reports

#### Resources (`system_top_utilization_placed.rpt`)

```
grep -E "^\| (Slice LUTs|Slice Registers|Block RAM Tile|DSPs) " ~/plutoplus_dvb_out/system_top_utilization_placed.rpt
```

| Line | Available (7010) | What to check |
|---|---|---|
| Slice LUTs | 17,600 | Util% below 100 (estimate about 80%) |
| Slice Registers | 35,200 | Util% below 100 |
| Block RAM Tile | 60 | Util% below 100 |
| DSPs | 80 | Util% below 100 (estimate about 88%) |

Above 100%, place and route will already have failed (`Placement failed` and the like in the log).

#### Timing (`system_top_timing_summary_postroute_physopted.rpt`)

The bitstream is generated from this final state. `system_top_timing_summary_routed.rpt` predates the `hold_fix.tcl` reroute, so do not use it to judge timing.

```
grep -A6 "Design Timing Summary" ~/plutoplus_dvb_out/system_top_timing_summary_postroute_physopted.rpt
grep -i "timing constraints are" ~/plutoplus_dvb_out/system_top_timing_summary_postroute_physopted.rpt
```

- **WNS(ns)** and **WHS(ns)** in the table should be 0 or more (a negative value is a timing violation and can cause malfunction on the hardware)
- It should say "All user specified timing constraints are met."
- If there are violations, send the two reports and `plutoplus_dvb_vivado.log` to the Mac and discuss

### 4. Moving the files to the Mac

Take these from `~/plutoplus_dvb_out/`: `plutoplus_dvb.xsa`, `system_top_utilization_placed.rpt`, `system_top_timing_summary_postroute_physopted.rpt`
(the logs only if something failed).

#### Method A: USB memory

```
cp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt /media/$USER/<USB-drive-name>/
sync
```

On the Mac, copy them from the USB memory to `~/Downloads/plutoplus_dvb_out/` or similar.

#### Method B: scp (on the same LAN)

1. On the Mac, turn on System Settings → General → Sharing → Remote Login
2. Send from Linux (`<mac-user>` is the output of `whoami` on the Mac, `<mac-name>` is the `xxx.local` shown on the Sharing screen)

   ```
   ssh <mac-user>@<mac-name>.local "mkdir -p ~/Downloads/plutoplus_dvb_out"
   scp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt <mac-user>@<mac-name>.local:~/Downloads/plutoplus_dvb_out/
   ```

3. You can turn Remote Login off again afterwards

### 5. Putting it into the firmware

The Mac steps are in `board/tezuka/plutoplus_udp_fpga/README.md` of kazushinjo/plutoplus-udp-fpga-fw,
under "FPGA version → after plutoplus_dvb.xsa is ready (Mac)". In summary:

1. Put `plutoplus_dvb.xsa` in `~/AppDev/plutoplus-udp-fpga-fw/board/tezuka/plutoplus_dvb/bitstream/`, commit and push
2. Build `plutoplus_udp_fpga` with GitHub Actions → get the zip from the prerelease
3. Write the SD card → check on the hardware

### License

- Origin, F5OEO/maia-sdr (source of `hdl/`): MIT (`hdl/LICENSE`)
- ADI HDL (adi-hdl submodule): ADI's licenses, per file (BSD-style, GPL and others)
- dvb_fpga (submodule, Suoto / Open Research Institute): **CERN-OHL-W v2**.
  Hardware built with it must show the source location https://github.com/phase4ground/dvb_fpga
  visibly on the product's exterior (CERN-OHL-W v2 section 4.1)
- Changes added on this branch: MIT, matching the origin. Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)
