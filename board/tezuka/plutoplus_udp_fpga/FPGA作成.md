# Pluto+ FPGA 版ファーム(plutoplus_udp_fpga)の作り方

**日本語** | [English](#english)

DVB-S2 の変調を ARM のソフト(pluto_dvb)ではなく **FPGA の DVB-S2 送信回路**で行う Pluto+ 用ファームを、
FPGA のビルドから実機での確認まで通して作る手順。
設計の背景・仕組みは [README.md の「FPGA 版」](README.md#fpga-版plutoplus_udp_fpga)、
Vivado まわりの細かい説明は kazushinjo/plutoplus-udp-fpga-firm の `hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md` を参照。

## 目次

1. [全体の流れ](#全体の流れ)
2. [① Linux PC の準備(初回だけ)](#-linux-pc-の準備初回だけ)
3. [② FPGA(HDL)のビルド(Linux PC)](#-fpgahdlのビルドlinux-pc)
4. [③ Mac で確認してリポジトリへ入れる](#-mac-で確認してリポジトリへ入れる)
5. [④ ファームのビルド(GitHub Actions)](#-ファームのビルドgithub-actions)
6. [⑤ SD カードを作る(Mac)](#-sd-カードを作るmac)
7. [⑥ Pluto+ での確認](#-pluto-での確認)
8. [元に戻す方法](#元に戻す方法)
9. [注意点](#注意点)

## 全体の流れ

```
[Linux PC]  ① Vivado を入れる → ② FPGA(HDL)をビルド → plutoplus_dvb.xsa
                                              │ USB メモリ / scp
[Mac]       ③ plutoplus_dvb.xsa を確認してこのリポジトリへ push
[GitHub]    ④ Actions でファーム(plutoplus_udp_fpga)をビルド → プレリリースの zip
[Mac]       ⑤ SD カードへ書き込む
[Pluto+]    ⑥ SD から起動して確認・送信試験
```

| リポジトリ(どちらも公開) | 中身 | 作業する場所 |
|---|---|---|
| kazushinjo/plutoplus-udp-fpga-firm(ブランチ `main`) | FPGA の設計(Maia-SDR を外し DVB-S2 送信回路を入れた構成) | Linux PC |
| kazushinjo/plutoplus-udp-fpga-fw(ブランチ `main`、このリポジトリ) | ファーム本体(Buildroot) | Mac → GitHub Actions |

FPGA のビルドには Vivado(x86_64 Linux 専用)が、ファームのビルドには Linux が要る(ファームは GitHub Actions で作る)。
**Mac では ①②④ はできない。**

## ① Linux PC の準備(初回だけ)

対象: x86_64 の Ubuntu 22.04 / 24.04。空き容量 100GB 前後、メモリ 16GB 以上。

```
sudo apt update
sudo apt install -y git make build-essential python3 libtinfo-dev libncurses-dev locales gh
sudo locale-gen en_US.UTF-8
```

### Vivado 2025.2 を入れる

1. AMD のアカウントを作る(https://www.amd.com/en/registration/create-account.html)。
   ダウンロードのとき氏名・住所を聞かれる(米国の輸出規制の確認なので正しく入れる)
2. https://www.xilinx.com/support/download.html を開き、版のタブで **2025.2** を選ぶ。
   「**AMD Unified Installer for FPGAs & Adaptive SoCs 2025.2: Linux Self Extracting Web Installer**」(`.bin`)をダウンロード
3. 実行する

   ```
   cd ~/Downloads
   chmod +x FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
   sudo ./FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
   ```

4. 画面では次を選ぶ(画面の名前は AMD の変更で少し違うことがある)

   | 画面 | 選ぶもの |
   |---|---|
   | Welcome | Next(新しい版があると言われても 2025.2 のまま) |
   | Select Install Type | AMD アカウントでログインし「Download and Install Now」 |
   | Select Product to Install | **Vivado** |
   | Select Edition to Install | **Vivado ML Standard**(無料。Zynq-7010 を含む) |
   | 部品の選択 | Devices は **Production Devices → SoCs → Zynq-7000 だけ**。ほかのデバイス・Vitis・Kria は外す |
   | License Agreements | 3 つとも I Agree |
   | インストール先 | 既定の `/tools/Xilinx` |
   | Install Cable Drivers | 不要(JTAG は使わない) |

   Web Installer なので本体はインストール中にダウンロードされる(Zynq-7000 だけで数十 GB、回線によって 1〜数時間)。

5. 入ったか確かめる

   ```
   source /tools/Xilinx/2025.2/Vivado/settings64.sh
   vivado -version        # 「Vivado v2025.2」と出ればよい
   ```

   Ubuntu 24.04 で `libtinfo.so.5` が無いと言われたら:

   ```
   sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
   ```

## ② FPGA(HDL)のビルド(Linux PC)

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-firm.git
cd plutoplus-udp-fpga-firm

VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

- サブモジュール(ADI の HDL、DVB-S2 送信回路 `dvb_fpga` とその third_party)はスクリプトが自動で取ってきて、`dvb_fpga` に修正を当てる
- ADI の IP 生成 → 合成 → 配置配線で **1〜2 時間**の見込み
- 終わると `~/plutoplus_dvb_out/` に次ができる

| ファイル | 中身 |
|---|---|
| `plutoplus_dvb.xsa` | ビットストリーム入りのハードウェア定義(これをファームに入れる) |
| `system_top_utilization_placed.rpt` | FPGA 資源の使用量 |
| `system_top_timing_summary_routed.rpt` | タイミング |
| `*.log` | Vivado のログ |

### レポートの確認(一番大事)

Zynq-7010 に収まるかは、まだ見積もり(LUT 約 80%、DSP 約 88%)でしかない。

```
grep -E "^\| (Slice LUTs|Slice Registers|Block RAM Tile|DSPs) " ~/plutoplus_dvb_out/system_top_utilization_placed.rpt
grep -A6 "Design Timing Summary" ~/plutoplus_dvb_out/system_top_timing_summary_routed.rpt
grep "timing constraints are" ~/plutoplus_dvb_out/system_top_timing_summary_routed.rpt
```

| 見るところ | 合格 |
|---|---|
| Slice LUTs(17,600)・Slice Registers(35,200)・Block RAM Tile(60)・DSPs(80) | Util% がすべて 100 未満 |
| WNS(ns)・WHS(ns) | どちらも 0 以上 |
| 最後の grep | `All user specified timing constraints are met.` |

### 失敗したとき

- `hdl/projects/plutoplus_dvb/plutoplus_dvb_vivado.log` の最後の ERROR を見る
- やり直す前に片付ける: `cd hdl/projects/plutoplus_dvb && make clean PROJECT_NAME=plutoplus_dvb`
- 資源が足りない(`Placement failed` など)、タイミングが負のときは、レポート 2 つとログを Mac へ持ってきて相談

### Mac へ持っていく

持っていくもの: `plutoplus_dvb.xsa`・`system_top_utilization_placed.rpt`・`system_top_timing_summary_routed.rpt`(ログは失敗したときだけ)。

- USB メモリ

  ```
  cp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt /media/$USER/<USBメモリの名前>/ && sync
  ```

  Mac では `~/Downloads/plutoplus_dvb_out/` にコピーする。

- scp(同じ LAN)。Mac で「システム設定 → 一般 → 共有 → リモートログイン」をオンにしてから:

  ```
  ssh <Macのユーザー名>@<Macの名前>.local "mkdir -p ~/Downloads/plutoplus_dvb_out"
  scp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt <Macのユーザー名>@<Macの名前>.local:~/Downloads/plutoplus_dvb_out/
  ```

  終わったらリモートログインはオフに戻してよい。

## ③ Mac で確認してリポジトリへ入れる

```
cd ~/Downloads/plutoplus_dvb_out
unzip -l plutoplus_dvb.xsa | grep -E "system_top.bit|\.hwh"
unzip -p plutoplus_dvb.xsa '*.hwh' | grep -c dvbs2_encoder_wrapper   # 1 以上(DVB-S2 送信回路が入っている)
unzip -p plutoplus_dvb.xsa '*.hwh' | grep -c maia_sdr                # 0(Maia-SDR は入っていない)
grep -E "^\| (Slice LUTs|Block RAM Tile|DSPs) " system_top_utilization_placed.rpt
grep "timing constraints are" system_top_timing_summary_routed.rpt   # All ... are met.

cd ~/AppDev/plutoplus-udp-fpga-fw
B=board/tezuka/plutoplus_dvb/bitstream
cp ~/Downloads/plutoplus_dvb_out/plutoplus_dvb.xsa $B/
mkdir -p $B/reports && cp ~/Downloads/plutoplus_dvb_out/*.rpt $B/reports/
git add $B && git commit -m "plutoplus_dvb: add bitstream built with Vivado 2025.2" && git push origin main
```

コミットメッセージは英語・ASCII だけにする(このリポジトリの決まり)。

## ④ ファームのビルド(GitHub Actions)

```
gh workflow run main.yml --repo kazushinjo/plutoplus-udp-fpga-fw --ref main -f boards=plutoplus_udp_fpga
gh run list  --repo kazushinjo/plutoplus-udp-fpga-fw --workflow main.yml --limit 3
gh run watch <run の番号> --repo kazushinjo/plutoplus-udp-fpga-fw
```

- できた zip はプレリリース `plutoplus_udp_fpga-build<番号>` に付く(Artifacts は容量上限のため当てにしない)
- キャッシュが効くので plutoplus_udp の初回(2 時間 40 分)より短い見込み。公開リポジトリなので Actions は無料
- 次は自動で入る
  - SD 起動の対策(tezuka 0.2.4 の BOOT.bin と無圧縮カーネル。README の「SD 起動しなかった件」)
  - 版の名前 `plutoplus-udp-fpga-firm_v1.0-<コミット>`
  - 差し替えスクリプト `overlay_dvb/root/pluto_dvb.fpga`(変調方式を `tx/dvbs2/constel` へ送る修正 1518007 を含む)

## ⑤ SD カードを作る(Mac)

**plutoplus_udp(通常版)の SD カードは残しておき、別の SD カードを使う**(戻すのが差し替えだけで済む)。
32GB 以下・MBR・FAT32 にする。

```
gh release download plutoplus_udp_fpga-build<番号> --repo kazushinjo/plutoplus-udp-fpga-fw --dir ~/Downloads/plutoplus_dvb
cd ~/Downloads/plutoplus_dvb && unzip plutoplus_udp_fpga.zip

diskutil list external physical                              # SD カードの番号を必ず確認(間違えると別のディスクを消す)
diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/diskN      # 中身は全部消える
mdutil -i off /Volumes/PLUTOPLUS
COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/          # sdimg の「中身」を一番上へ(フォルダごとではない)
dot_clean -m /Volumes/PLUTOPLUS
for f in BOOT.bin devicetree.dtb system_top.bin uEnv.txt uImage uramdisk.image.xz; do
  [ "$(md5 -q sdimg/$f)" = "$(md5 -q /Volumes/PLUTOPLUS/$f)" ] && echo "一致 $f" || echo "不一致 $f"
done
diskutil eject /dev/diskN
```

## ⑥ Pluto+ での確認

### 起動

1. ジャンパ: **SD-H = 3V3**(この Pluto+ の場合)、**URST = MIO46**。SD カードを挿して電源を入れる(5V 2A 以上)
2. LED: 緑と青が点けば FPGA まで進んでいる。20〜40 秒で Linux が起動し USB ドライブ(`TEZUKA`)が出る。
   **緑だけが点きっぱなしなら起動失敗**(SD カードの中身・ジャンパを見直す)
3. ネットワーク・SSH の確認は README の「起動後の確認」と同じ(SSH は root / analog)

### 版と動いているもの

```
cat /opt/VERSIONS          # device-fw plutoplus-udp-fpga-firm_v1.0-…
ps | grep -E "pluto_stream|pluto_mqtt_ctrl|udpts|rtmppluto|lighttpd|mosquitto" | grep -v grep
ls -l /root/pluto_dvb /root/pluto_dvb.sw     # pluto_dvb はスクリプト、pluto_dvb.sw は元のソフト版
```

### 送信試験

**必ずアッテネーター(40dB など)とダミーロード/受信機をつなぐ。**

1. 別の SSH 画面で MQTT の流れを見ておく

   ```
   mosquitto_sub -h 127.0.0.1 -t 'cmd/pluto/#' -t 'dt/pluto/#' -v
   ```

2. UDP 送信アプリ(V2 など)からいつもどおり送信する(UDP 8282)。または `http://<IP>/pluto.php` で設定を保存し、Mac から試験映像を送る:

   ```
   ffmpeg -re -f lavfi -i testsrc=size=640x360:rate=25 -f lavfi -i sine=frequency=1000 \
     -c:v libx264 -b:v 300k -g 50 -c:a aac -b:a 64k -f mpegts "udp://<IP>:8282?pkt_size=1316"
   ```

3. 1 の画面に `cmd/pluto/<call>/tx/dvbs2/constel`・`fec`・`frame`・`pilots`・`sr`・`tx/frequency`・`tx/mute 0`・`tx/stream/run 1` が出れば設定が届いている
4. 周波数・LO・ゲイン

   ```
   iio_attr -c ad9361-phy altvoltage1 frequency    # 送信周波数(Hz)
   iio_attr -c ad9361-phy altvoltage1 powerdown    # 0 なら LO オン
   iio_attr -c -o ad9361-phy voltage0 hardwaregain # 送信ゲイン(dB)
   ```

5. 受信側(MiniTiouner、UDP 送信アプリの受信など)でロック・MER・映像・音声を見る。
   **8PSK・16APSK・32APSK も選び、実際にその方式で出ているか確かめる**(1518007 の修正前は常に QPSK になっていた)。
   スペクトラムアナライザーがあれば帯域と肩も見る
6. 送るのをやめると `tx/stream/run 0`・`tx/mute 1` が出る

### 受信まわり

UDP 送信アプリの RSSI 測定・受信、Langstone が今までどおり動くか(FPGA 版は 1R1T・Maia-SDR なし)。

### うまくいかないとき

pluto_stream のメッセージを見る(S96plutostream は出力を捨てているので手で起動し直す):

```
killall pluto_stream; pluto_stream 2>&1 | tee /tmp/pluto_stream.log &
```

## 元に戻す方法

FPGA 版は SD カードにしか入っていない(内蔵フラッシュには触れていない)。

- **SD カードを差し替える**: plutoplus_udp の SD カードに戻して電源を入れ直す
- **SD カードを抜かずに戻す**(ネットワークが使えるとき)

  ```
  cd ~/Downloads/plutoplus/sdimg      # plutoplus_udp を展開した場所
  scp -r * root@<IP>:/boot/
  ssh root@<IP> "sync; reboot"
  ```

- **SD カードから起動しないようにする**: SD-H ジャンパを外すと内蔵フラッシュの元のファームで起動する

## 注意点

- Maia-SDR(ウォーターフォール・IQ 録音・IQEngine)は外しているので使えない。tezuka ダッシュボードの MQTT 操作は使える
- ロールオフは FPGA 側で変えられない(0.35 のまま。`-r` は無視)
- 送受信は 1 系統ずつ(1R1T)
- dvb_fpga(Open Research Institute)は **CERN-OHL-W v2**。これを使った機器を作るときは、ソースの場所
  https://github.com/phase4ground/dvb_fpga を外から見える所に書く(4.1 項)

## 状態(2026-10-28)

| 作業 | 状態 |
|---|---|
| HDL の変更・ビルドスクリプト・手順書 | 済み(plutoplus-udp-fpga-firm に push) |
| Vivado でのビルド(②) | まだ(Linux PC の準備から) |
| ファーム側の設定・差し替えスクリプト | 済み(変調方式の命令名を 2026-10-28 に修正、1518007) |
| ファームのビルド(④)・実機(⑥) | まだ(plutoplus_dvb.xsa 待ち) |

---

# English

## Building the Pluto+ FPGA firmware (plutoplus_udp_fpga)

How to build, from the FPGA through to hardware checks, the Pluto+ firmware that performs DVB-S2 modulation in the **FPGA DVB-S2 transmit chain** instead of the ARM software (pluto_dvb).
For the design background and how it works, see the FPGA version section of [README.md](README.md). For details on Vivado, see `hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md` in kazushinjo/plutoplus-udp-fpga-firm.

### Overall flow

```
[Linux PC]  (1) Install Vivado → (2) Build the FPGA (HDL) → plutoplus_dvb.xsa
                                              | USB memory / scp
[Mac]       (3) Check plutoplus_dvb.xsa and push it to this repository
[GitHub]    (4) Build the firmware (plutoplus_udp_fpga) with Actions → prerelease zip
[Mac]       (5) Write the SD card
[Pluto+]    (6) Boot from SD, check, and run a transmit test
```

| Repository (both public) | Contents | Where the work is done |
|---|---|---|
| kazushinjo/plutoplus-udp-fpga-firm (branch `main`) | FPGA design (Maia-SDR removed, DVB-S2 chain added) | Linux PC |
| kazushinjo/plutoplus-udp-fpga-fw (branch `main`, this repository) | The firmware (Buildroot) | Mac → GitHub Actions |

The FPGA build needs Vivado (x86_64 Linux only), and the firmware build needs Linux (the firmware is built with GitHub Actions).
**Steps 1, 2 and 4 cannot be done on a Mac.**

### (1) Preparing the Linux PC (first time only)

Target: x86_64 Ubuntu 22.04 / 24.04, around 100 GB free, 16 GB of memory or more.

```
sudo apt update
sudo apt install -y git make build-essential python3 libtinfo-dev libncurses-dev locales gh
sudo locale-gen en_US.UTF-8
```

#### Installing Vivado 2025.2

1. Create an AMD account (https://www.amd.com/en/registration/create-account.html).
   The download asks for your name and address (a US export-control check, so enter it correctly)
2. Open https://www.xilinx.com/support/download.html and select **2025.2** in the version tabs.
   Download "**AMD Unified Installer for FPGAs & Adaptive SoCs 2025.2: Linux Self Extracting Web Installer**" (`.bin`)
3. Run it

   ```
   cd ~/Downloads
   chmod +x FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
   sudo ./FPGAs_AdaptiveSoCs_Unified_SDI_2025.2_*_Lin64.bin
   ```

4. Choose the following (screen names may differ slightly as AMD changes them)

   | Screen | Choose |
   |---|---|
   | Welcome | Next (stay on 2025.2 even if told a newer version exists) |
   | Select Install Type | Log in with your AMD account, "Download and Install Now" |
   | Select Product to Install | **Vivado** |
   | Select Edition to Install | **Vivado ML Standard** (free, includes Zynq-7010) |
   | Component selection | Under Devices, **Production Devices → SoCs → Zynq-7000 only**. Uncheck other devices, Vitis and Kria |
   | License Agreements | I Agree on all three |
   | Install location | The default `/tools/Xilinx` |
   | Install Cable Drivers | Not needed (JTAG is not used) |

   This is a web installer, so the main part is downloaded during installation (tens of GB for Zynq-7000 alone, one to several hours depending on the connection).

5. Confirm the installation

   ```
   source /tools/Xilinx/2025.2/Vivado/settings64.sh
   vivado -version        # should print "Vivado v2025.2"
   ```

   If Ubuntu 24.04 reports a missing `libtinfo.so.5`:

   ```
   sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
   ```

### (2) Building the FPGA (HDL) on the Linux PC

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-firm.git
cd plutoplus-udp-fpga-firm

VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

- The script fetches the submodules (ADI HDL, the DVB-S2 chain `dvb_fpga` and its third_party) and patches `dvb_fpga` automatically
- ADI IP generation → synthesis → place and route is expected to take **1 to 2 hours**
- When finished, `~/plutoplus_dvb_out/` contains:

| File | Contents |
|---|---|
| `plutoplus_dvb.xsa` | Hardware definition including the bitstream (this goes into the firmware) |
| `system_top_utilization_placed.rpt` | FPGA resource use |
| `system_top_timing_summary_routed.rpt` | Timing |
| `*.log` | Vivado logs |

#### Checking the reports (the most important step)

Whether it fits in the Zynq-7010 is still only an estimate (LUT about 80%, DSP about 88%).

```
grep -E "^\| (Slice LUTs|Slice Registers|Block RAM Tile|DSPs) " ~/plutoplus_dvb_out/system_top_utilization_placed.rpt
grep -A6 "Design Timing Summary" ~/plutoplus_dvb_out/system_top_timing_summary_routed.rpt
grep "timing constraints are" ~/plutoplus_dvb_out/system_top_timing_summary_routed.rpt
```

| What to check | Pass |
|---|---|
| Slice LUTs (17,600), Slice Registers (35,200), Block RAM Tile (60), DSPs (80) | Util% all below 100 |
| WNS(ns), WHS(ns) | Both 0 or more |
| The last grep | `All user specified timing constraints are met.` |

#### If it fails

- Look at the last ERROR in `hdl/projects/plutoplus_dvb/plutoplus_dvb_vivado.log`
- Clean up before retrying: `cd hdl/projects/plutoplus_dvb && make clean PROJECT_NAME=plutoplus_dvb`
- If resources run out (`Placement failed` and the like) or timing is negative, bring the two reports and the log to the Mac and discuss

#### Moving the files to the Mac

Take: `plutoplus_dvb.xsa`, `system_top_utilization_placed.rpt`, `system_top_timing_summary_routed.rpt` (the logs only if something failed).

- USB memory

  ```
  cp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt /media/$USER/<USB-drive-name>/ && sync
  ```

  On the Mac, copy them to `~/Downloads/plutoplus_dvb_out/`.

- scp (same LAN). On the Mac, turn on System Settings → General → Sharing → Remote Login, then:

  ```
  ssh <mac-user>@<mac-name>.local "mkdir -p ~/Downloads/plutoplus_dvb_out"
  scp ~/plutoplus_dvb_out/plutoplus_dvb.xsa ~/plutoplus_dvb_out/*.rpt <mac-user>@<mac-name>.local:~/Downloads/plutoplus_dvb_out/
  ```

  You can turn Remote Login off again afterwards.

### (3) Checking on the Mac and adding it to the repository

```
cd ~/Downloads/plutoplus_dvb_out
unzip -l plutoplus_dvb.xsa | grep -E "system_top.bit|\.hwh"
unzip -p plutoplus_dvb.xsa '*.hwh' | grep -c dvbs2_encoder_wrapper   # 1 or more (DVB-S2 chain present)
unzip -p plutoplus_dvb.xsa '*.hwh' | grep -c maia_sdr                # 0 (Maia-SDR absent)
grep -E "^\| (Slice LUTs|Block RAM Tile|DSPs) " system_top_utilization_placed.rpt
grep "timing constraints are" system_top_timing_summary_routed.rpt   # All ... are met.

cd ~/AppDev/plutoplus-udp-fpga-fw
B=board/tezuka/plutoplus_dvb/bitstream
cp ~/Downloads/plutoplus_dvb_out/plutoplus_dvb.xsa $B/
mkdir -p $B/reports && cp ~/Downloads/plutoplus_dvb_out/*.rpt $B/reports/
git add $B && git commit -m "plutoplus_dvb: add bitstream built with Vivado 2025.2" && git push origin main
```

Commit messages must be English and ASCII only (a rule of this repository).

### (4) Building the firmware (GitHub Actions)

```
gh workflow run main.yml --repo kazushinjo/plutoplus-udp-fpga-fw --ref main -f boards=plutoplus_udp_fpga
gh run list  --repo kazushinjo/plutoplus-udp-fpga-fw --workflow main.yml --limit 3
gh run watch <run-number> --repo kazushinjo/plutoplus-udp-fpga-fw
```

- The zip is attached to the prerelease `plutoplus_udp_fpga-build<number>` (Artifacts are not relied on because of the storage quota)
- Caches apply, so it should be shorter than the first plutoplus_udp build (2 h 40 min). The repository is public, so Actions are free
- The following are included automatically
  - The SD boot workaround (tezuka 0.2.4 BOOT.bin and an uncompressed kernel; see the SD boot failure section of the README)
  - The version name `plutoplus-udp-fpga-firm_v1.0-<commit>`
  - The replacement script `overlay_dvb/root/pluto_dvb.fpga` (including fix 1518007, which sends the modulation to `tx/dvbs2/constel`)

### (5) Writing the SD card (Mac)

**Keep the plutoplus_udp (normal version) SD card and use a separate SD card** (so going back only takes swapping cards).
Use 32 GB or smaller, MBR, FAT32.

```
gh release download plutoplus_udp_fpga-build<number> --repo kazushinjo/plutoplus-udp-fpga-fw --dir ~/Downloads/plutoplus_dvb
cd ~/Downloads/plutoplus_dvb && unzip plutoplus_udp_fpga.zip

diskutil list external physical                              # always confirm the SD card number (a mistake erases another disk)
diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/diskN      # erases everything on it
mdutil -i off /Volumes/PLUTOPLUS
COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/          # the contents of sdimg go at the top level (not the folder itself)
dot_clean -m /Volumes/PLUTOPLUS
for f in BOOT.bin devicetree.dtb system_top.bin uEnv.txt uImage uramdisk.image.xz; do
  [ "$(md5 -q sdimg/$f)" = "$(md5 -q /Volumes/PLUTOPLUS/$f)" ] && echo "match $f" || echo "MISMATCH $f"
done
diskutil eject /dev/diskN
```

### (6) Checking on the Pluto+

#### Booting

1. Jumpers: **SD-H = 3V3** (for this Pluto+), **URST = MIO46**. Insert the SD card and power on (5 V, 2 A or more)
2. LEDs: green and blue on means it has reached the FPGA. Linux boots in 20 to 40 seconds and a USB drive (`TEZUKA`) appears.
   **Green alone staying on means the boot failed** (recheck the SD card contents and jumpers)
3. Network and SSH checks are the same as in the README's post-boot checks (SSH is root / analog)

#### Versions and running processes

```
cat /opt/VERSIONS          # device-fw plutoplus-udp-fpga-firm_v1.0-...
ps | grep -E "pluto_stream|pluto_mqtt_ctrl|udpts|rtmppluto|lighttpd|mosquitto" | grep -v grep
ls -l /root/pluto_dvb /root/pluto_dvb.sw     # pluto_dvb is the script, pluto_dvb.sw is the original software version
```

#### Transmit test

**Always connect an attenuator (40 dB or so) and a dummy load or receiver.**

1. Watch the MQTT traffic in another SSH session

   ```
   mosquitto_sub -h 127.0.0.1 -t 'cmd/pluto/#' -t 'dt/pluto/#' -v
   ```

2. Transmit from the UDP sender app (V2 and so on) as usual (UDP 8282). Or save the settings at `http://<IP>/pluto.php` and send a test video from the Mac:

   ```
   ffmpeg -re -f lavfi -i testsrc=size=640x360:rate=25 -f lavfi -i sine=frequency=1000 \
     -c:v libx264 -b:v 300k -g 50 -c:a aac -b:a 64k -f mpegts "udp://<IP>:8282?pkt_size=1316"
   ```

3. The settings have arrived if the session from step 1 shows `cmd/pluto/<call>/tx/dvbs2/constel`, `fec`, `frame`, `pilots`, `sr`, `tx/frequency`, `tx/mute 0` and `tx/stream/run 1`
4. Frequency, LO and gain

   ```
   iio_attr -c ad9361-phy altvoltage1 frequency    # TX frequency (Hz)
   iio_attr -c ad9361-phy altvoltage1 powerdown    # 0 means the LO is on
   iio_attr -c -o ad9361-phy voltage0 hardwaregain # TX gain (dB)
   ```

5. On the receiver (MiniTiouner, the UDP sender app receive and so on), check lock, MER, video and audio.
   **Also select 8PSK, 16APSK and 32APSK and confirm that the signal really uses that modulation** (before fix 1518007 it was always QPSK).
   If you have a spectrum analyzer, also check the bandwidth and shoulders
6. When you stop sending, `tx/stream/run 0` and `tx/mute 1` appear

#### Receive functions

Check whether the UDP sender app RSSI measurement and receive, and Langstone, work as before (the FPGA version is 1R1T with no Maia-SDR).

#### If it does not work

Look at the pluto_stream messages (S96plutostream discards the output, so restart it by hand):

```
killall pluto_stream; pluto_stream 2>&1 | tee /tmp/pluto_stream.log &
```

### Going back

The FPGA version exists only on the SD card (the internal flash is not touched).

- **Swap the SD card**: put the plutoplus_udp SD card back and power cycle
- **Go back without removing the SD card** (when the network is available)

  ```
  cd ~/Downloads/plutoplus/sdimg      # where plutoplus_udp was extracted
  scp -r * root@<IP>:/boot/
  ssh root@<IP> "sync; reboot"
  ```

- **Stop booting from the SD card**: remove the SD-H jumper to boot the original firmware in internal flash

### Notes

- Maia-SDR (waterfall, IQ recording, IQEngine) is removed and cannot be used. The MQTT controls of the tezuka dashboard can be used
- The roll-off cannot be changed on the FPGA side (it stays at 0.35; `-r` is ignored)
- One transmit and one receive channel (1R1T)
- dvb_fpga (Open Research Institute) is **CERN-OHL-W v2**. Equipment built with it must show the source location
  https://github.com/phase4ground/dvb_fpga where it can be seen from outside (section 4.1)

### Status (2026-10-28)

| Task | Status |
|---|---|
| HDL changes, build script, guides | Done (pushed to plutoplus-udp-fpga-firm) |
| Build in Vivado (step 2) | Not yet (starting with the Linux PC setup) |
| Firmware settings and replacement script | Done (modulation command name fixed on 2026-10-28, 1518007) |
| Firmware build (step 4), hardware (step 6) | Not yet (waiting for plutoplus_dvb.xsa) |
