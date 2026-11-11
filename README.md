# plutoplus_fw-shonan

[tezuka](https://github.com/F5OEO/tezuka_fw)(F5OEO 氏)をもとにした、**Zynq-7010 の Pluto+ 用の SD カード起動ファーム**です。
Shonan_Lite と Portsdown 4 で DATV(DVB-S2)送信ができるようにしてあります。
A **SD card boot firmware for the Zynq-7010 Pluto+**, based on [tezuka](https://github.com/F5OEO/tezuka_fw) by F5OEO, with DATV (DVB-S2) transmit support for Shonan_Lite and Portsdown 4.

> このリポジトリは F5OEO 氏の許可を得て公開しています。 / Published with the permission of F5OEO.

> [!IMPORTANT]
> **UDP 用に変更したファームです。** Shonan_Lite などから UDP(ポート 8282)で送られる MPEG-TS を受け取り、DVB-S/S2 で送信する用途に合わせて変更しています(Portsdown 4 の rtmp 7272 も使えます)。
> **アナログチューナー用(アナログテレビ・FM-TV の送信)には使えません。** デジタル(DVB-S/S2)専用です。

> [!IMPORTANT]
> **This firmware is modified for UDP use.** It receives an MPEG-TS over UDP (port 8282) from Shonan_Lite and similar apps and transmits it as DVB-S/S2 (Portsdown 4 over rtmp 7272 also works).
> **It cannot be used for analog tuners (analog TV / FM-TV transmission).** It is digital (DVB-S/S2) only.

| 版 / Variant | DVB-S2 の変調 / Modulation | Maia-SDR | 説明 / Details |
|---|---|---|---|
| `plutoplus_shonan` | ARM のソフト(pluto_dvb) / ARM software | あり / Yes | [board/tezuka/shonan/README.md](board/tezuka/shonan/README.md) |
| `plutoplus_shonan_dvb`(FPGA 版 / FPGA build) | FPGA | **なし / Not supported** | [Plutoplus-FPGA-firm](https://github.com/kazushinjo/Plutoplus-FPGA-firm)、[FPGA作成.md](board/tezuka/shonan/FPGA作成.md) |

**ダウンロード / Download:** [Releases](https://github.com/kazushinjo/plutoplus_fw-shonan/releases)(`plutoplus_shonan-build<番号>`・`plutoplus_shonan_dvb-build<番号>`)。
FPGA 版は [Plutoplus-FPGA-firm の Releases](https://github.com/kazushinjo/Plutoplus-FPGA-firm/releases) にも置いています。 / The FPGA build is also on the Releases of Plutoplus-FPGA-firm.

**注意 / Notes**

- **Zynq-7010(`XC7Z010`)の Pluto+ 専用**。Zynq-7020 などの基板では動きません。 / **Zynq-7010 Pluto+ only**; it does not work on Zynq-7020 or other boards.
- **SD カード起動専用**(内蔵フラッシュには書き込みません)。32GB 以下・MBR・FAT32 のカードに zip の `sdimg/` の中身をコピーします。 / **SD card boot only** (the internal flash is not written). Copy the contents of `sdimg/` to a 32 GB or smaller MBR + FAT32 card.
- **SD 起動には古い U-Boot 2016.07(tezuka 0.2.4 の BOOT.bin)が必要**です。今の tezuka の U-Boot 2025.01 ではこの Pluto+ は SD 起動しません。そのため `BOOT.bin` は 0.2.4 のもの、`uImage` は無圧縮にしてあります。`BOOT.bin` を入れ替えないでください。 / **SD boot needs the old U-Boot 2016.07 (tezuka 0.2.4 BOOT.bin)**; the current U-Boot 2025.01 does not boot this Pluto+ from SD. `BOOT.bin` is therefore the 0.2.4 one and `uImage` is uncompressed. Do not replace `BOOT.bin`.
- FPGA 版は **Maia-SDR に対応していません**(Zynq-7010 に両方は入らないため)。 / The FPGA build **does not support Maia-SDR** (the Zynq-7010 cannot hold both).
- 送信の試験では必ずアッテネーターとダミーロードを使ってください。 / Always use an attenuator and a dummy load when testing transmission.
- クレジットとライセンスは [下の節](#license) と [board/tezuka/shonan/LICENSE.md](board/tezuka/shonan/LICENSE.md) を参照。 / See [License](#license) and [board/tezuka/shonan/LICENSE.md](board/tezuka/shonan/LICENSE.md) for credits and licenses.

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
| PlutoPlus (plutoplus_shonan) | 7010 | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> SD のみ (SD only) | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> ¹ | micro | <span><img src="https://img.shields.io/badge/-%E2%9C%93-green" alt="Yes"></span> | PlutoPlus と同じ (same as PlutoPlus) |
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

¹ `plutoplus_shonan`(このリポジトリ): DATV の変調は FPGA の DVB 回路ではなくソフトで行う。Shonan_Lite(UDP 8282、`save.php`/`pluto.php`)と Portsdown 4(rtmp 7272)の TS を `pluto_dvb` と TSDuck の `tsp` で送信する。SD カード起動専用(イメージが QSPI のファーム領域に入らない)。詳しくは [board/tezuka/shonan/README.md](board/tezuka/shonan/README.md)。

¹ `plutoplus_shonan` (this repository): DATV modulation is done in software rather than the FPGA DVB chain. TS from Shonan_Lite (UDP 8282, `save.php`/`pluto.php`) and Portsdown 4 (rtmp 7272) is transmitted with `pluto_dvb` and TSDuck's `tsp`. SD card boot only (the image does not fit in the QSPI firmware area). See [board/tezuka/shonan/README.md](board/tezuka/shonan/README.md).


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
- Shonan 版の謝辞は [board/tezuka/shonan/README.md](board/tezuka/shonan/README.md) を参照 / See that file for the acknowledgements of the Shonan edition
- All the opensource community !

---

## License

ライセンス(詳しくは [board/tezuka/shonan/LICENSE.md](board/tezuka/shonan/LICENSE.md))

* **tezuka ファーム**(F5OEO ほか): [GNU General Public License v3.0](LICENSE)
* **plutoplus_shonan で足したもの**(`configs/plutoplus_shonan*_defconfig`、`board/tezuka/shonan/`、`board/tezuka/plutoplus_dvb/`、CI の変更): GPL-3.0、Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)
* **ファームに入るパッケージ**(Linux、U-Boot、BusyBox、PHP、lighttpd、FFmpeg ほか): それぞれのライセンス。全パッケージのライセンス文と SBOM は Buildroot の `legal-info` で集め、各リリースの `plutoplus_shonan-licenses.zip`・`plutoplus_shonan_dvb-licenses.zip` に付けている
* **同梱しているサードパーティのファイル**: TSDuck(BSD-2-Clause)、jQuery・Chart.js・chartjs-plugin-labels・Socket.IO・js-cookie(MIT)
* **FPGA 版(plutoplus_shonan_dvb)**: pluto_stream(GPL-2.0+)、ビットストリームは maia-hdl(MIT)・ADI HDL(各ライセンス)・dvb_fpga(CERN-OHL-W v2。ハードウェアを作るときはソースの場所を外装に書く)の組み合わせ
* **F5OEO/datvplutofrm から持ってきた DATV の部品**(`udpts.sh`、`rtmppluto.sh`、PHP の Web 画面、`pluto_dvb` の実行ファイル): 元のリポジトリにライセンスの明記はないが、作者 F5OEO 氏から公開の許可をいただいている

Licenses (details in [board/tezuka/shonan/LICENSE.md](board/tezuka/shonan/LICENSE.md))

* **tezuka firmware** (F5OEO and others): [GNU General Public License v3.0](LICENSE)
* **What plutoplus_shonan adds** (`configs/plutoplus_shonan*_defconfig`, `board/tezuka/shonan/`, `board/tezuka/plutoplus_dvb/`, CI changes): GPL-3.0, Copyright (C) 2026 Kazu Shinjo (JA6FUF/JH1XHX)
* **Packages in the firmware** (Linux, U-Boot, BusyBox, PHP, lighttpd, FFmpeg and others): their own licenses. License texts and the SBOM for all packages are collected by Buildroot's `legal-info` and attached to each release as `plutoplus_shonan-licenses.zip` / `plutoplus_shonan_dvb-licenses.zip`
* **Bundled third-party files**: TSDuck (BSD-2-Clause); jQuery, Chart.js, chartjs-plugin-labels, Socket.IO, js-cookie (MIT)
* **FPGA version (plutoplus_shonan_dvb)**: pluto_stream (GPL-2.0+); the bitstream combines maia-hdl (MIT), ADI HDL (its licenses) and dvb_fpga (CERN-OHL-W v2; hardware built with it must show the source location on its exterior)
* **DATV components from F5OEO/datvplutofrm** (`udpts.sh`, `rtmppluto.sh`, the PHP web pages, the `pluto_dvb` executable): the original repository states no license; they are published with the permission of the author, F5OEO
