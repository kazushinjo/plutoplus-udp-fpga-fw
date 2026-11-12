# plutoplus-udp-fpga-fw

[tezuka](https://github.com/F5OEO/tezuka_fw)(F5OEO 氏)をもとにした、**Zynq-7010 の Pluto+ 用の SD カード起動ファーム(FPGA 版)**です。
UDP 送信アプリから UDP で送られる TS を DATV(DVB-S/S2)で送信できるようにしてあります。**DVB-S2 の変調は FPGA の送信回路で行います**。
A **SD card boot firmware for the Zynq-7010 Pluto+ (FPGA build)**, based on [tezuka](https://github.com/F5OEO/tezuka_fw) by F5OEO, with DATV (DVB-S/S2) transmit of a TS sent over UDP from a UDP sender app. **DVB-S2 modulation is done in the FPGA transmit chain.**

> このリポジトリは F5OEO 氏の許可を得て公開しています。 / Published with the permission of F5OEO.

> [!IMPORTANT]
> **UDP 専用のファームです。** Portsdown 4 で使っているアナログチューナー用のファームではありません。
> UDP 送信アプリなどから UDP(ポート 8282)で送られる MPEG-TS を受け取り、DVB-S/S2 で送信する用途に変更しています。

> [!IMPORTANT]
> **This is a UDP-only firmware.** It is not the analog-tuner firmware used with Portsdown 4.
> It is modified to receive an MPEG-TS over UDP (port 8282) from a UDP sender app on a PC or phone and transmit it as DVB-S/S2.

| 版 / Variant | DVB-S2 の変調 / Modulation | Maia-SDR | 場所 / Where |
|---|---|---|---|
| `plutoplus_udp_fpga`(このリポジトリ / this repository) | FPGA | **なし / Not supported** | [board/tezuka/plutoplus_udp_fpga/README.md](board/tezuka/plutoplus_udp_fpga/README.md)、[FPGA作成.md](board/tezuka/plutoplus_udp_fpga/FPGA作成.md)、HDL: [plutoplus-udp-fpga-firm](https://github.com/kazushinjo/plutoplus-udp-fpga-firm) |
| `plutoplus_udp`(ソフト版 / software build) | ARM のソフト(pluto_dvb) / ARM software | あり / Yes | 別リポジトリ / separate repository: kazushinjo/plutoplus-udp-fw |

**ダウンロード / Download:** [Releases](https://github.com/kazushinjo/plutoplus-udp-fpga-fw/releases)(`plutoplus_udp_fpga-build<番号>`)。
FPGA 版は [plutoplus-udp-fpga-firm の Releases](https://github.com/kazushinjo/plutoplus-udp-fpga-firm/releases) にも置きます。 / The FPGA build is also published on the Releases of plutoplus-udp-fpga-firm.

**注意 / Notes**

- **Zynq-7010(`XC7Z010`)の Pluto+ 専用**。Zynq-7020 などの基板では動きません。 / **Zynq-7010 Pluto+ only**; it does not work on Zynq-7020 or other boards.
- **SD カード起動専用**(内蔵フラッシュには書き込みません)。32GB 以下・MBR・FAT32 のカードに zip の `sdimg/` の中身をコピーします。 / **SD card boot only** (the internal flash is not written). Copy the contents of `sdimg/` to a 32 GB or smaller MBR + FAT32 card.
- **SD 起動には古い U-Boot 2016.07(tezuka 0.2.4 の BOOT.bin)が必要**です。今の tezuka の U-Boot 2025.01 ではこの Pluto+ は SD 起動しません。そのため `BOOT.bin` は 0.2.4 のもの、`uImage` は無圧縮にしてあります。`BOOT.bin` を入れ替えないでください。 / **SD boot needs the old U-Boot 2016.07 (tezuka 0.2.4 BOOT.bin)**; the current U-Boot 2025.01 does not boot this Pluto+ from SD. `BOOT.bin` is therefore the 0.2.4 one and `uImage` is uncompressed. Do not replace `BOOT.bin`.
- **版名には大文字の `FPGA` が入っています**(例: `plutoplus-udp-fpga-firm_v1.0-FPGA-26a1`)。UDP 送信アプリ(Pi4・Pi5・Win・Mac・iPad・iPhone・Android の全版)は、Pluto の `fw_version` に大文字の `FPGA` があるときだけ 16APSK・32APSK を選べるようにしています(大文字・小文字を区別)。版名を変えるときも大文字の `FPGA` を残してください(`board/tezuka/plutoplus_udp_fpga/post-build.sh`)。 / **The version name contains an upper-case `FPGA`** (e.g. `plutoplus-udp-fpga-firm_v1.0-FPGA-26a1`). The UDP sender apps (all versions: Pi4, Pi5, Win, Mac, iPad, iPhone, Android) enable 16APSK/32APSK only when the Pluto `fw_version` contains an upper-case `FPGA` (case-sensitive). Keep it when renaming (`board/tezuka/plutoplus_udp_fpga/post-build.sh`).
- **Maia-SDR に対応していません**(Zynq-7010 に DVB-S2 送信回路と両方は入らないため)。 / **Maia-SDR is not supported** (the Zynq-7010 cannot hold it together with the DVB-S2 chain).
- 送信の試験では必ずアッテネーターとダミーロードを使ってください。 / Always use an attenuator and a dummy load when testing transmission.
- クレジットとライセンスは [下の節](#license) と [board/tezuka/plutoplus_udp_fpga/LICENSE.md](board/tezuka/plutoplus_udp_fpga/LICENSE.md) を参照。 / See [License](#license) and [board/tezuka/plutoplus_udp_fpga/LICENSE.md](board/tezuka/plutoplus_udp_fpga/LICENSE.md) for credits and licenses.

## SD カードへの書き込み方 / Writing the SD card

1. ファームの zip(`plutoplus_udp_fpga.zip`)を手に入れて展開する。中の `sdimg/` フォルダを使う(`flash/` は空)。
   / Get the firmware zip (`plutoplus_udp_fpga.zip`) and unzip it. Use the `sdimg/` folder inside (`flash/` is empty).
2. **32GB 以下**の SD カードを **MBR・FAT32** で初期化する(中身は全部消える)。 / Format an SD card of **32 GB or less** as **MBR + FAT32** (everything on it is erased).
   - Mac: ディスク番号を `diskutil list external physical` で確かめてから(**間違えると別のディスクを消す**)
     / check the disk number first (**a wrong number erases another disk**):
     ```sh
     diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/diskN
     ```
   - Windows: エクスプローラーで SD カードを右クリック →「フォーマット」→ ファイルシステム **FAT32**。 / Explorer → right-click the card → Format → **FAT32**.
   - Linux: `sudo mkfs.vfat -F 32 -n PLUTOPLUS /dev/sdX1`(MBR のパーティションが 1 つの場合 / with a single MBR partition)
3. `sdimg/` の**中身**を SD カードの一番上にコピーする(`sdimg` フォルダごとではない)。 / Copy the **contents** of `sdimg/` to the top of the card (not the `sdimg` folder itself).
   - Mac では隠しファイルを作らないように / On a Mac, avoid hidden files:
     ```sh
     COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/
     dot_clean -m /Volumes/PLUTOPLUS
     ```
   - SD カードの一番上に次の 7 つがあればよい / The top of the card should hold these 7 files:
     `BOOT.bin` `devicetree.dtb` `plutoplus_dvb_top.bin` `system_top.bin` `uEnv.txt` `uImage` `uramdisk.image.xz`
4. 取り出す(Mac は `diskutil eject /dev/diskN`)。 / Eject the card.

> [!IMPORTANT]
> `BOOT.bin` は SD 起動できる古い U-Boot(tezuka 0.2.4)、`uImage` は無圧縮です。ほかのファームのものと入れ替えないでください。
> / `BOOT.bin` is the old SD-bootable U-Boot (tezuka 0.2.4) and `uImage` is uncompressed. Do not replace them with files from other firmware.

**起動中に更新する / Updating while running** — SD カードは起動中の Pluto+ で `/boot` に見えるので、抜かずに入れ替えられる。
/ The card appears as `/boot` on the running Pluto+, so it can be updated without removing it:

```sh
scp sdimg/* root@<IP>:/boot/        # パスワード / password: analog
ssh root@<IP> "sync; reboot"
```

## Pluto+ の設定方法 / Setting up the Pluto+

### ジャンパ / Jumpers

電源とケーブルを外し、上ぶた(ネジ 4 本)を開けて設定する。位置は基板のシルクを見る。 / Power off, open the top cover (4 screws) and set them; see the board silkscreen.

| ジャンパ / Jumper | 設定 / Setting | 理由 / Why |
| --- | --- | --- |
| SD-H | **1V8** か **3V3**(基板のシルクにある方) / **1V8** or **3V3** (whichever the silkscreen shows) | SD カードから起動する。外すと内蔵フラッシュのファームで起動 / Boot from the SD card; removing it boots the internal flash firmware |
| URST | **MIO46** | 内蔵 LAN を使う(MIO52 は ADI 公式ファーム用) / Use the built-in LAN (MIO52 is for the ADI firmware) |
| EXCLK | 普段は外す(外部基準クロックのときだけ GND) / Normally open (GND only with an external reference clock) | |

### 起動 / Booting

1. SD カードを挿し、micro USB で電源を入れる(5V 2A 以上)。LAN ケーブルもつなぐ。 / Insert the card and power it from micro USB (5 V, 2 A or more). Connect the LAN cable.
2. **緑と青**の LED が点けば FPGA まで進んでいる(青は FPGA の DONE)。20〜40 秒で起動し、USB ドライブ `TEZUKA` が出る。
   **緑だけで青が点かなければ起動失敗**(SD カードの中身・ジャンパを見直す)。
   / **Green and blue** LEDs mean the FPGA is loaded (blue = FPGA DONE); it boots in 20–40 s and a USB drive `TEZUKA` appears.
   **Green only, no blue, means the boot failed** (check the card contents and jumpers).
3. 確かめる / Check:
   - `ping <IP>`、ブラウザで `http://<IP>/`(状態ページ。版名・送信の状態) / the status page shows the version and TX state
   - `ssh root@<IP>`(パスワード `analog`)で `cat /opt/VERSIONS` → `device-fw plutoplus-udp-fpga-firm_v1.0-FPGA-…`
   - UDP 送信アプリの「設定」→「Pluto 情報」→「バージョン」 / In the UDP sender app: Config → Pluto Info → Version

### ネットワークと周波数範囲の設定 / Network and frequency range

設定は Pluto+ の**内蔵フラッシュに保存**され、SD 起動でも内蔵ファームでも同じ値を使う。USB ドライブ `TEZUKA` の `config.txt` を書き換えて
**ドライブを取り出す**と保存される(`SUCCESS_ENV_UPDATE` が出る)。設定後は電源を入れ直す。
/ Settings are **stored in the Pluto+ internal flash** and shared by the SD and internal firmware. Edit `config.txt` on the `TEZUKA` USB drive and
**eject the drive** to save (`SUCCESS_ENV_UPDATE` appears), then power cycle.

```ini
[USB_ETHERNET]
ipaddr_eth = 192.168.0.20
netmask_eth = 255.255.255.0
gateway_eth = 192.168.0.1

[SYSTEM]
usb_ethernet_mode = ncm
```

- `ipaddr_eth` は内蔵 LAN の固定 IP。空にすると DHCP。 / `ipaddr_eth` is the built-in LAN static IP; leave it empty for DHCP.
- `usb_ethernet_mode = ncm` は USB ネットワークの方式。Mac・Windows 10 以降はドライバ不要。 / `ncm` needs no driver on Mac or Windows 10 and later.
- 値の後ろにコメントを書かない(値の一部として読まれる)。 / Do not put comments after a value (they would be read as part of it).

- USB でつないだときの Pluto+ は `192.168.2.1`(PC 側 `192.168.2.10`)。 / Over USB the Pluto+ is `192.168.2.1` (PC side `192.168.2.10`).
- 固定 IP は、LAN のリンクが一時的に切れても消えずに残る(このファームの修正)。 / The static IP stays even if the LAN link drops for a while (fixed in this firmware).
- **周波数範囲を 46.875 MHz〜6 GHz にする(ad9364 扱い) / Extend to 46.875 MHz–6 GHz (ad9364)** — SSH で入って / over SSH:
  ```sh
  fw_setenv attr_name compatible
  fw_setenv attr_val ad9364
  reboot
  ```
  `dmesg | grep ad9361_probe` が `enter (ad9364)` になれば有効。戻すときは `fw_setenv attr_val ad9363a`。AD9363 の保証範囲(325 MHz〜3.8 GHz)の外は個体によって性能が落ちることがある。
  / Active when `dmesg | grep ad9361_probe` shows `enter (ad9364)`; revert with `fw_setenv attr_val ad9363a`. Outside the AD9363 rated range (325 MHz–3.8 GHz) performance may drop.
- Pluto のユーザー名 `root`・パスワード `analog` は変えない(UDP 送信アプリが SSH で使う)。 / Keep `root` / `analog`; the UDP sender apps use SSH.

### 元のファームに戻す / Going back to the internal firmware

SD-H のジャンパを外して電源を入れ直す。 / Remove the SD-H jumper and power cycle.

## UDP 専用であること / UDP-only

このファームの DATV 送信は **UDP 専用**です。UDP 送信アプリから UDP 8282 に送られた MPEG-TS を `tsp` → FPGA の DVB-S2 送信回路(`pluto_stream` が操作)で DVB-S/S2 送信することだけを目的にしています。
F5OEO 氏の datvplutofrm v0.32-dirty にあった、ほかの送信モード・Pluto 内でのエンコード・受信機能は入れていません(下の表)。
RTMP 7272(`rtmppluto.sh`、H.264/H.265 をそのまま TS にして送信)は datvplutofrm と同じものが残っていますが、主な使い方ではなく実機では確認していません。

The DATV transmit path of this firmware is **UDP only**: an MPEG-TS sent to UDP port 8282 by a UDP sender app goes through `tsp` → the FPGA DVB-S2 transmit chain (driven by `pluto_stream`) and is transmitted as DVB-S/S2.
The other transmit modes, on-board encoding and receive functions of F5OEO's datvplutofrm v0.32-dirty are not included (see the table below).
RTMP on port 7272 (`rtmppluto.sh`, remuxes H.264/H.265 to TS and transmits) is kept as in datvplutofrm, but it is not the intended use and has not been tested on hardware.

## v0.32-dirty と比べて無い機能 / Features missing compared with v0.32-dirty

比較の対象は F5OEO/datvplutofrm `63f2465`(v0.32-dirty)。FPGA 版はこの表に加えて Maia-SDR・IQEngine・tezuka ダッシュボードも無い(7010 に入りきらないため)。 / Compared with F5OEO/datvplutofrm `63f2465` (v0.32-dirty). In addition, the FPGA build has no Maia-SDR, IQEngine or tezuka dashboard (they do not fit in the 7010 together with the DVB-S2 chain).

| 分類 / Area | 無いもの / Missing | 内容 / Notes |
|---|---|---|
| ほかの送信モード / Other TX modes | `hacktv` | アナログ TV 送信 / analog TV transmit |
| | `plutotx` + `csdr`(`fm.sh`・`ssb.sh`) | FM・SSB 送信 / FM and SSB transmit |
| | `audio.sh`(RTMP 7373)・`pisstv` | FreeDV・SSTV・SSB の音声送信 / FreeDV, SSTV and SSB from an RTMP audio stream |
| | `leandvbtx`・`paintrf`・`radar`・`rx2tx`・`scream-raw`・`qo100websdr` | 実験用ツール / experimental tools |
| DATV の付属機能 / DATV extras | `rtmppluto_transcode.sh`(x264) | Pluto 内での再エンコード(x264 も無し) / on-board re-encoding (no x264) |
| | `camOK.sh`(v4l・USB カメラ) | USB カメラを Pluto に直接つないで送信 / transmit from a USB camera on the Pluto (no V4L/UVC) |
| | `autoudp.sh`(UDP 11000) | 設定なしの簡易 UDP 送信 / simple UDP transmit without settings |
| | `watchconsoletx.sh` | 送信ゲインに連動した AD9361 GPO の PTT 出力。Web 画面の PTT ボタン(`requests.php`)だけ残っている / PTT on the AD9361 GPO following the TX gain; only the PTT button in `requests.php` remains |
| 受信・解析 / Receive and analysis | `leandvb`・`ldpc_tool` | DVB-S/S2 受信 / DVB-S/S2 receive |
| | `rcv_analyse.sh`・`rcv_analyse.php`・`decodevideo.sh` | 受信 TS の解析(`analysis.php` の受信解析は動かない) / received-TS analysis (the receive part of `analysis.php` does not work) |
| | `www/rx/` | ブラウザの WebSDR 画面 / browser WebSDR page |
| TSDuck | プラグイン 73 個 → 5 個(ip・file・sdt・analyze・pcrextract)、`tsresync`・`tsversion` | UDP 送信に要るものだけ / only what UDP transmit needs |
| システム / System | gpsd・ntp | GPS・時刻合わせ / GPS and NTP |
| | hostapd | Wi-Fi アクセスポイント / Wi-Fi access point |
| | `S91nfs-mount` | 起動時の NFS マウント(カーネルの NFS は有効) / NFS mount at boot (kernel NFS is enabled) |
| | opkg・nano・strace・alsa-utils(aplay)・ad936x_ref_cal・fftw | パッケージ / packages |
| | `www/index.html` | F5OEO の説明ページ。`/` は tezuka のダッシュボード / F5OEO's info page; `/` is the tezuka dashboard |
| | `/mnt/jffs2/patch.zip` の中身 / contents of `patch.zip` | 実機に入っていた追加分は不明で移していない / extras installed on the original device are unknown and not carried over |

v0.32-dirty から持ってこなかったが不要なもの(`S94pluto-mods`・busybox httpd など)は [board/tezuka/plutoplus_udp_fpga/README.md](board/tezuka/plutoplus_udp_fpga/README.md#datvplutofrm-から持ってこなかったもの) を参照。 / Items not carried over because they are not needed (`S94pluto-mods`, busybox httpd, etc.) are listed in the board README.

以下は元の tezuka の README です。 / The original tezuka README follows.

---

![tezuka banner](/doc/tezuka.png)

[![Tezuka](https://github.com/F5OEO/tezuka_fw/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/F5OEO/tezuka_fw/actions/workflows/main.yml)
[![GitHub Release](https://img.shields.io/github/release/F5OEO/tezuka_fw.svg)](https://github.com/F5OEO/tezuka_fw/releases/latest)  [![Github Releases](https://img.shields.io/github/downloads/F5OEO/tezuka_fw/total.svg)](https://github.com/F5OEO/tezuka_fw/releases/latest)

## About tezuka firmware 

* **Universal firmware** builder designed to unlock the full potential of your PlutoSDR/clone. 

* Built entirely for the **SDR enthusiast** community—bringing new features, wider frequency ranges, and massive performance boosts to your existing device.

* **Quick addition** of new board (already 10 boards supported)

---

## Key Features

* **Frequency Extension:** Expanded tuning range from **47.5 MHz to 6 GHz**.
* **Seamless Input Switching:** Easily switch between RX1/RX2 and TX1/TX2.
* **Extended Bandwidth:** Complex 8-bit mode unlocks stable streaming up to **14 MHz over USB** and **45 MHz over GbE network**.
* **Risk-Free Booting:** Built-in **SD Card boot support** for effortless updates with zero risk of bricking your flash memory.
* **Integrated Apps:** Includes Maia-SDR transparently, fast sweep, and MQTT status publishing and more.
* **Remote Access:** Built-in WireGuard VPN, configured from the Dashboard by pasting a `wg-quick` config — no SSH/CLI needed.
* **Signal Classifier (experimental):** Onboard PSD spectral-shape matching identifies signal types live, overlaid right on the Dashboard's spectrum view. Work in progress — not yet validated on real hardware.

---

## Support the Project

This firmware is developed entirely in my free time. Maintaining multiple boards, buying hardware for testing, and adding features takes significant time and resources. If **tezuka** supercharges your SDR experience, please consider supporting the project!

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=for-the-badge&logo=github-sponsors)](https://github.com/sponsors/F5OEO)
[![PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal)](https://paypal.me/f5oeodev)

*No funds? You can still support by **starring the repository** or helping improve the documentation!*

---

## Hardware Matrix

| Device Platform | Architecture | SD card | Gbe | DATV | USB Type | GPIO | Trusted vendors |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| PlutoSDR | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | micro | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [digikey](https://www.digikey.com/) [mouser](https://mouser.com/)|
| PlutoPlus | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | micro | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [OpenSdrLab](https://opensourcesdrlab.com/products/opensourcesdr-lab-pluto-sdr-ad9363-2t2r-radio-sdr-transceiver-radio-70mhz-6ghz-software-defined-radio?DIST=RkVFGVU%3D)|
| PlutoPlus (plutoplus_udp) | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> SD のみ (SD only) | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> ¹ | micro | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | PlutoPlus と同じ (same as PlutoPlus) |
| Antsdr E200 | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [CrowdSupply](https://www.crowdsupply.com/microphase-technology/antsdr-e200)|
| Antsdr E310 | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [Microphase](https://www.microphase.cn/)|
| Fishball/PlutoSky | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [OpenSDRLab obsolete -> 7020](https://opensourcesdrlab.com/products/new-7020-ad9363-plutosdr?DIST=RkVFGVU%3D) [OpenSDRLab with box](https://opensourcesdrlab.com/products/opensourcesdrlab-new-7020-sdr-ad9363-for-pluto-software-defined-radio-without-pa?DIST=RkVFGVU%3D)|
| Fishball/PlutoSky | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [OpenSDRLab](https://opensourcesdrlab.com/products/new-7020-ad9363-plutosdr?DIST=RkVFGVU%3D) [OpenSDRLab with box](https://opensourcesdrlab.com/products/opensourcesdrlab-new-7020-sdr-ad9363-for-pluto-software-defined-radio-without-pa?DIST=RkVFGVU%3D) |
| SignalSDRPro | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-3 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [CrowdSupply](https://www.crowdsupply.com/signalens/signalsdr-pro)|
| LibreSDR/ZynqSDR | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [OpenSDRLab](https://opensourcesdrlab.com/products/libresdr-zynqsdr-ad9363-zynq7020?DIST=RkVFGVU%3D)|
| PlutoSky R2 | 7020 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | [OpenSDRLab](https://opensourcesdrlab.com/products/plutosky-r2?DIST=RkVFGVU%3D)|
| Pluto Nano | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | AliExpress HamGeek ?|
| PCIe SDR 7010 | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | Via PCIe <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | [OpenSDRLab](https://opensourcesdrlab.com/products/opensourcesdrlab-pcie-version-plutosdr-ad9363-xc7z010?DIST=RkVFGVU%3D)|
| OpenSDRLab 7010 Mini | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | usb-c | <span><img src="https://img.shields.io/badge/-%E2%9C%97-red" alt="No"></span> | [OpenSDRLab](https://opensourcesdrlab.com/products/7010-ad9363-sdr-mini?DIST=RkVFGVU%3D)|

¹ `plutoplus_udp`(このリポジトリ): DATV の変調は FPGA の DVB 回路ではなくソフトで行う。UDP 送信アプリ(UDP 8282、`save.php`/`pluto.php`)の TS を `pluto_dvb` と TSDuck の `tsp` で送信する。SD カード起動専用(イメージが QSPI のファーム領域に入らない)。詳しくは [board/tezuka/plutoplus_udp_fpga/README.md](board/tezuka/plutoplus_udp_fpga/README.md)。

¹ `plutoplus_udp` (this repository): DATV modulation is done in software rather than the FPGA DVB chain. TS from the UDP sender app (UDP 8282, `save.php`/`pluto.php`) is transmitted with `pluto_dvb` and TSDuck's `tsp`. SD card boot only (the image does not fit in the QSPI firmware area). See [board/tezuka/plutoplus_udp_fpga/README.md](board/tezuka/plutoplus_udp_fpga/README.md).


---

## Installation : Use the SD boot mode 

 **CRITICAL: DO NOT use the standard `frm` flashing method. To prevent bricking, always boot via SD card mode unless you know what you are doing.**

1. Go to the [Releases Section](https://github.com/F5OEO/tezuka_fw/releases).
2. Download and unzip the specific package matching your hardware configuration.
3. Format a fresh SD Card to **FAT32**.
4. Copy the entire contents of the **`sdimg`** folder onto the root of the SD Card.
5. Insert into your board and power on.

***Only for original PlutoSDR (No SD Slot):*** Follow the [official ADI flashing procedure](https://wiki.analog.com/university/tools/pluto/users/firmware) using the `pluto.frm` file.

---

## Configuration & Software

Once booted, the firmware exposes a USB drive containing `config.txt`. Modify this file to tweak your settings (based on standard [ADI customization parameters](https://wiki.analog.com/university/tools/pluto/users/customizing)).

### Compatible Software
Enjoy extra features out-of-the-box with custom-tailored software branches:
* [SatDump](https://github.com/F5OEO/SatDump)
* [SDR++](https://github.com/F5OEO/SDRPlusPlus)
* [SoapyPlutoPAPR](https://github.com/F5OEO/SoapyPlutoPAPR)
*(Standard apps like SDRConsole and SDRAngel are also compatible).*

### Remote Access (WireGuard VPN)

Connect your board to a remote WireGuard server for secure remote access, configured entirely from the Dashboard — no SSH/CLI needed:

* Open the Dashboard's **Network** tab and find the **VPN (WireGuard)** card.
* Paste a complete `wg-quick`-style config (`[Interface]`/`[Peer]` blocks, private key included) into the text box and click **Save & apply**.
* Toggle **Enabled** to bring the tunnel up. Live status (handshake time, transfer, peer public key) is shown on the same card.
* Routing follows whatever `AllowedIPs` your config specifies — a scoped value gives split-tunnel access to just that network, while `0.0.0.0/0` routes all device traffic through the tunnel.

**Security note:** the pasted config is sent once and never redisplayed or echoed back over MQTT. That said, the Dashboard's default MQTT channel (port 9001) is unauthenticated on the local network by design, same as every other Dashboard control — treat the WireGuard private key like any other credential on an open network segment, and avoid exposing the device's management interface to untrusted networks.

### Signal Classifier (experimental, work in progress)

> **Status:** experimental. The pipeline is cross-compiled and exercised under `qemu-arm-static`, and the correlation math is unit-tested directly, but it has not yet been run end-to-end against a real signal on real hardware — see [Known limitations](#known-limitations) below before relying on it for anything.

Onboard PSD spectral-shape matching — identifies signal *types* (OFDM, FSK, chirp, CW, etc.) live and overlays a label on the spectrum, right on the device, no host-side processing required.

**How it works:** a small daemon (`app/classifier/classifier.c`) connects as a WebSocket client to `maia-httpd`'s existing `/waterfall` feed — the same live FFT the Spectrum and Radio Astronomy pages already consume — and correlates each frame against a set of loaded templates roughly once a second, publishing the best match over MQTT. It never touches the raw-IQ path (`iio_ws_proxy`), so it adds no new consumer of the ADC and never competes with IQ Tape or the Signal Generator. This is spectral-*shape* matching (magnitude/PSD cosine similarity), not true cyclostationary SCF — it separates signal families well but won't reliably distinguish modulation order within a family (e.g. BPSK vs. QPSK), since that distinction lives in phase information this feed doesn't carry.

**Sample rate:** no special sample rate is required — the daemon adapts to whatever bin count `/waterfall` is currently emitting. One real caveat: matching is relative-bin shape correlation, not Hz-normalized, so a template captured (or synthesized) at one span will transfer poorly to classifying live at a very different span. Build templates at roughly the span you plan to classify at.

**Using it:**

* Open the Dashboard's **Signal Classifier** page (under RF) and toggle **Enabled** — it runs as a background service from then on.
* A matched signal gets a label chip (e.g. "OFDM · 92%") overlaid on its own live spectrum view, plus a "Reference match" panel and a scrolling log of recent classifications. Below the confidence threshold, or with no templates loaded, it reports "unknown" rather than forcing a guess.
* Ships with a small starter set out of the box (FM broadcast, DAB+, CW/beacon — synthesized canonical shapes, seeded on first boot) so there's something to test against immediately. Build your own with `tools/classifier_templates/` — either `capture_from_device.py` (pulls a shape straight off a live device, no GNU Radio/TorchSig required) or `synthesize_template.py` (idealized canonical shapes for classes you can't easily capture yet) — and push the result the same way a WireGuard config is sent: base64 over MQTT (`cmd/classifier/templates`), which replaces the starter set permanently.

The same page also shows a **band plan** — a color-coded strip under the spectrum marking known allocations (broadcast, cellular, aviation, maritime, etc.), independent of whether the classifier has actually matched anything there. Click a swatch (or a row in the editable table below it) to tune to that frequency. Entries are stored on the device (`/mnt/jffs2/bandplan.json`, seeded from a starting reference table) and edited directly from the Dashboard — add, edit, or remove entries and hit **Save**.

#### Known limitations

* **Not yet validated on real hardware.** Everything so far is cross-compiled and run under `qemu-arm-static`, plus unit tests on the correlation math — the full `/waterfall` → correlate → MQTT → Dashboard path hasn't had a live-signal pass yet.
* The "Reference match" panel currently shows the live captured shape only, labeled with the matched template's name — it doesn't overlay the stored template curve itself, since the raw template data lives only in the daemon's binary file and isn't published to the Dashboard.
* PSD shape matching won't distinguish modulation order within a family (see above).

---

## For Developers

### Setup Environment (Debian/Ubuntu)
```bash
# Install mandatory dependencies
sudo apt install pkg-config libssl-dev libclang-dev jq

# Clone the repository & pull Buildroot
git clone [https://github.com/F5OEO/tezuka_fw](https://github.com/F5OEO/tezuka_fw)
cd tezuka_fw
./getbuildroot.sh


```
### Build
```bash
# Build a single board (each board gets its own output directory):
./build.sh fishball

# Build multiple boards:
./build.sh pluto plutoplus fishball

# Build all boards:
./build.sh all

# Build with parallel jobs and clean output first:
./build.sh -j8 -c fishball
```

Or build manually using Buildroot directly:
```bash
source sourceme.first
cd buildroot
make pluto_maiasdr_defconfig && make
```

For a list all supported boards run:
```bash
./build.sh -h
```

### Building on WSL2 
Buildroot does not allow whitespaces in the PATH environment variable. On WSL several paths with whitespaces are added. The following script can be used to remove any path with whitespaces. It also deletes any leftover ':' at the end:
```bash
export PATH=$(echo $PATH | tr ':' '\n' | grep -v ' ' | tr '\n' ':' | sed 's/:$//')
```
### Compatibility with older build scripts

If you encounter errors related to CMAKE policy version, it's because newer versions of CMAKE (3.27+) have stricter policy requirements. Setting CMAKE_POLICY_VERSION_MINIMUM=3.5 tells CMAKE to use policies from version 3.5 or newer, which helps maintain compatibility with older build scripts and dependencies that may not be fully compatible with the latest CMAKE policies. This is particularly important when building packages that haven't been updated to support newer CMAKE versions.

Run the build with:

```bash
CMAKE_POLICY_VERSION_MINIMUM=3.5 make
```

### Result
All materials are in buildroot/output/images

# Credits
- Daniel Estévez for incredible maia-sdr project (https://maia-sdr.org/)
- Gwenhael Goavec-Merou for inspiration https://github.com/oscimp/PlutoSDR
- LamaBleu for helping me with buildroot and introduce me Plutosdr
- https://github.com/hz12opensource/libresdr for overclock and fpga inspiration
- UDP 版の謝辞は [board/tezuka/plutoplus_udp_fpga/README.md](board/tezuka/plutoplus_udp_fpga/README.md) を参照 / See that file for the acknowledgements of the UDP edition
- All the opensource community !

---

## License

ライセンス(詳しくは [board/tezuka/plutoplus_udp_fpga/LICENSE.md](board/tezuka/plutoplus_udp_fpga/LICENSE.md))

* **tezuka ファーム**(F5OEO ほか): [GNU General Public License v3.0](LICENSE)
* **plutoplus_udp で足したもの**(`configs/plutoplus_udp_fpga_defconfig`、`board/tezuka/plutoplus_udp_fpga/`、`board/tezuka/plutoplus_dvb/`、CI の変更): GPL-3.0、Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)
* **ファームに入るパッケージ**(Linux、U-Boot、BusyBox、PHP、lighttpd、FFmpeg ほか): それぞれのライセンス。全パッケージのライセンス文と SBOM は Buildroot の `legal-info` で集め、各リリースの `plutoplus_udp_fpga-licenses.zip` に付けている
* **同梱しているサードパーティのファイル**: TSDuck(BSD-2-Clause)、jQuery・Chart.js・chartjs-plugin-labels・Socket.IO・js-cookie(MIT)
* **FPGA 版(plutoplus_udp_fpga)**: pluto_stream(GPL-2.0+)、ビットストリームは maia-hdl(MIT)・ADI HDL(各ライセンス)・dvb_fpga(CERN-OHL-W v2。ハードウェアを作るときはソースの場所を外装に書く)の組み合わせ
* **F5OEO/datvplutofrm から持ってきた DATV の部品**(`udpts.sh`、`rtmppluto.sh`、PHP の Web 画面、`pluto_dvb` の実行ファイル): 元のリポジトリにライセンスの明記はないが、作者 F5OEO 氏から公開の許可をいただいている

Licenses (details in [board/tezuka/plutoplus_udp_fpga/LICENSE.md](board/tezuka/plutoplus_udp_fpga/LICENSE.md))

* **tezuka firmware** (F5OEO and others): [GNU General Public License v3.0](LICENSE)
* **What plutoplus_udp adds** (`configs/plutoplus_udp_fpga_defconfig`, `board/tezuka/plutoplus_udp_fpga/`, `board/tezuka/plutoplus_dvb/`, CI changes): GPL-3.0, Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)
* **Packages in the firmware** (Linux, U-Boot, BusyBox, PHP, lighttpd, FFmpeg and others): their own licenses. License texts and the SBOM for all packages are collected by Buildroot's `legal-info` and attached to each release as `plutoplus_udp_fpga-licenses.zip`
* **Bundled third-party files**: TSDuck (BSD-2-Clause); jQuery, Chart.js, chartjs-plugin-labels, Socket.IO, js-cookie (MIT)
* **FPGA version (plutoplus_udp_fpga)**: pluto_stream (GPL-2.0+); the bitstream combines maia-hdl (MIT), ADI HDL (its licenses) and dvb_fpga (CERN-OHL-W v2; hardware built with it must show the source location on its exterior)
* **DATV components from F5OEO/datvplutofrm** (`udpts.sh`, `rtmppluto.sh`, the PHP web pages, the `pluto_dvb` executable): the original repository states no license; they are published with the permission of the author, F5OEO
