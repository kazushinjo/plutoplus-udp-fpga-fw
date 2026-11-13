# hdl/ — FPGA for plutoplus_udp_fpga

**English** | [日本語](README.ja.md)

The HDL for building the FPGA bitstream of the Pluto+ (Zynq-7010). It used to be the separate repository plutoplus-udp-fpga-firm (merged here on 2026-11-14).
The design contains only the **DVB-S2 transmit chain (dvb_fpga encoder + RRC), a TX FIR x8 interpolator, the AD9361 interface (1R1T) and DMA**.

> [!WARNING]
> **Maia-SDR is not supported.**
> The HDL is derived from F5OEO/maia-sdr, but the Maia-SDR logic and software have been removed.
> The following are **not available**:
>
> - The Maia-SDR web UI (spectrum and waterfall display)
> - IQ recording and IQEngine
> - Maia-SDR features of the tezuka dashboard (the top page is replaced by a status page for this FPGA build)
>
> The Zynq-7010 cannot hold both Maia-SDR and the DVB-S2 transmit chain, so the transmit chain was given priority.
> To use Maia-SDR, boot a firmware that includes it (such as the regular tezuka build). If it is in the internal flash, remove the SD card or the SD-H jumper to boot it.

The resulting `plutoplus_dvb.xsa` is used by `plutoplus_udp_fpga` in this repository (placed in [`board/tezuka/plutoplus_dvb/bitstream/`](../board/tezuka/plutoplus_dvb/bitstream/)).

> This repository is published with the permission of F5OEO.
>
> This is not an official Analog Devices firmware and is not supported by Analog Devices, nor an official firmware of the Pluto+ or other hardware makers. Analog Devices and ADALM-Pluto are trademarks of Analog Devices, Inc.

> [!IMPORTANT]
> **This is a UDP-only firmware.** It is not the analog-tuner firmware used with Portsdown 4.
> It is modified to receive an MPEG-TS over UDP (port 8282) from a UDP sender app on a PC or phone and transmit it as DVB-S2.

## Supported hardware (Zynq-7010 Pluto+ only)

**This bitstream and firmware are only for the Pluto+ whose FPGA (SoC) is a Zynq-7010 (`XC7Z010`).**

| Item | Details |
|---|---|
| FPGA (SoC) | **Xilinx/AMD Zynq-7010** (`xc7z010clg400-1`) |
| RF IC | AD9363 (as tested; used with the ad9364 frequency-range setting) |
| Tested board | Pluto+ (with SD card slot and Gigabit LAN) |

- It **does not work on boards with a different chip**, such as the Zynq-7020 (`XC7Z020`). A bitstream is built for one specific device and is not interchangeable
- The 7010 is too small to hold both Maia-SDR and the DVB-S2 transmit chain (about 67% LUT usage), which is why Maia-SDR is removed
- Check the chip on your board by the marking on the Zynq (`XC7Z010` or `XC7Z020`) or by the seller's specifications

## About the firmware

The firmware that includes this bitstream is `plutoplus_udp_fpga`.

- DVB-S2 modulation is done in the **FPGA** instead of ARM software
- **SD card boot only.** Nothing is written to the internal flash (QSPI), so removing the SD card brings back the original firmware
- UDP 8282, iiod and SSH work on the same ports and URLs as the regular build
- Maia-SDR (waterfall, IQ recording, IQEngine) is not included. One RX and one TX channel (1R1T)

It is distributed as `plutoplus-udp-fpga-firm.zip`; the files for the SD card are in `sdimg/` inside the zip.
**Download it from the [Releases](https://github.com/kazushinjo/plutoplus-udp-fpga-fw/releases) of this repository** (`plutoplus-udp-fpga-firm-build<number>`). The license bundle (`plutoplus-udp-fpga-firm-licenses.zip`) and checksums (`SHA256SUMS.txt`) are there too.
The firmware source is the rest of this repository.

## Writing the SD card

### What you need

- SD card: **32 GB or smaller** (tested with 32 GB), formatted as **MBR + FAT32**
- If you already boot the regular firmware from an SD card, keep it and use a **separate SD card**, so going back is just a card swap

### Mac

1. Unpack the zip

   ```
   cd ~/Downloads/plutoplus_dvb && unzip plutoplus-udp-fpga-firm.zip
   ```

2. Insert the SD card and find its disk number (**double-check it: a wrong number erases another disk**)

   ```
   diskutil list external physical
   ```

   Look for the external disk with the SD card's capacity (e.g. `/dev/disk4`) and use it in place of `diskN` below.

3. Format it as MBR + FAT32 (**everything on the card is erased**)

   ```
   diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/diskN
   ```

4. Copy the **contents** of `sdimg/` to the top level of the card (not the `sdimg` folder itself)

   ```
   mdutil -i off /Volumes/PLUTOPLUS
   COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/
   dot_clean -m /Volumes/PLUTOPLUS
   ```

5. Verify and eject

   ```
   for f in BOOT.bin devicetree.dtb system_top.bin uEnv.txt uImage uramdisk.image.xz; do
     [ "$(md5 -q sdimg/$f)" = "$(md5 -q /Volumes/PLUTOPLUS/$f)" ] && echo "OK $f" || echo "MISMATCH $f"
   done
   diskutil eject /dev/diskN
   ```

macOS may leave `.fseventsd` and `.Spotlight-V100` on the card; they do not affect booting.

### Windows / Linux

1. Format the SD card as **MBR (one partition) + FAT32**
   (Windows' built-in format cannot choose FAT32 for cards over 32 GB, so use a 32 GB or smaller card)
2. Unpack the zip and copy the **contents** of `sdimg/` to the top level of the card
3. Eject the card safely

### Files at the top level of the card

| File | Contents |
|---|---|
| `BOOT.bin` | FSBL + U-Boot 2016.07 (from tezuka 0.2.4; see "Important" below) |
| `system_top.bin` | FPGA bitstream (built from this repository) |
| `uImage` | Linux kernel (**uncompressed**; U-Boot 2016.07 cannot open LZMA) |
| `uramdisk.image.xz` | rootfs (unpacked into RAM at boot) |
| `devicetree.dtb` | Pluto+ device tree |
| `uEnv.txt` | U-Boot settings |

### Important: SD boot needs the old U-Boot (2016.07)

This Pluto+ **cannot boot from the SD card with the current tezuka U-Boot (2025.01)**
(only the green LED stays on; blue never lights). The BOOT.bin from the latest upstream tezuka release behaves the same.
The only U-Boot that boots from SD is **U-Boot 2016.07, found in the tezuka 0.2.4 BOOT.bin**.

The firmware therefore does the following (automatically at build time):

- The SD card `BOOT.bin` is **the one from tezuka 0.2.4** (FSBL + U-Boot 2016.07)
- U-Boot 2016.07 cannot open an LZMA-compressed kernel, so `uImage` is **uncompressed**
- The 0.2.4 U-Boot reads `uEnv.txt` from the SD card and boots this firmware's bitstream, device tree and rootfs

**Caution:**

- If you replace `BOOT.bin` with one from a newer tezuka (with U-Boot 2025.01), the board will no longer boot from SD
- If you put a compressed `uImage` on the card, the board reaches the FPGA stage (green and blue) but Linux does not start
- The FSBL is identical between old and new builds and is not the cause. There is no serial console, so the exact reason the new U-Boot fails has not been found

### Updating without removing the card

While the Pluto+ is running, the SD card is mounted at `/boot`, so you can replace the files over the network.

```
cd sdimg
scp BOOT.bin uImage uramdisk.image.xz devicetree.dtb uEnv.txt system_top.bin root@<IP>:/boot/
ssh root@<IP> "sync; reboot"
```

## Usage

### Booting

1. Disconnect power and cables, open the top cover and set the jumpers (see the board silkscreen for their positions)

   | Jumper | Setting | Why |
   |---|---|---|
   | SD-H | **1V8** or **3V3** (whichever the silkscreen shows) | Boot from the SD card |
   | URST | **MIO46** | Use the on-board Gigabit LAN |
   | EXCLK | GND only when using an external reference clock | Normally open |

2. Insert the SD card and power on (5 V, 2 A or more)
3. LEDs: green and blue on means the FPGA is loaded (blue is FPGA DONE). Linux boots in 20–40 s and the `TEZUKA` USB drive appears.
   **If only green stays on (blue off), the boot failed.** Check the SD card contents and the jumpers

### Connecting and checking

| Check | How | Expected result |
|---|---|---|
| Network | LAN (DHCP) or USB (Pluto side 192.168.2.1) | ping answers. Find the LAN IP on your router; mDNS name `pluto.local` |
| Status page | Open `http://<IP>/` in a browser | Shows the version, serial number and TX state |
| DATV settings | `http://<IP>/pluto.php` | The TX settings page appears |
| SSH | `ssh root@<IP>` (password `analog`) | You can log in |
| Version | `cat /opt/VERSIONS` over SSH | `device-fw plutoplus-udp-fpga-firm_v1.0-…` |

USB networking uses CDC-NCM (no driver needed on macOS or Windows 10 2004 and later).
Settings are stored in the internal flash; edit `config.txt` on the `TEZUKA` USB drive and eject it to apply them (static IP: `ipaddr_eth`).

### Ports and URLs

| Port / URL | Used by | What it does |
|---|---|---|
| UDP 8282 | UDP 送信アプリ | Receives a TS and transmits it as DVB-S2 from the FPGA |
| `http://<IP>/save.php`, `/pluto.php` | UDP sender app, browser | Saves the TX settings |
| iiod (TCP 30431) | Sender app RX and RSSI, Langstone | libiio |
| SSH 22 | UDP 送信アプリ | root / analog |
| `http://<IP>/` (80) | Browser | Status page |
| MQTT 1883 / WebSocket 9001 | Status page, `mosquitto_sub` etc. | TX settings and state (`cmd/pluto/#`, `dt/pluto/#`) |

### Transmitting

**Always connect an attenuator (e.g. 40 dB) and a dummy load or receiver before transmitting.**

- **From a UDP sender app:** transmit as usual (UDP 8282). Choose the modulation (QPSK/8PSK/16APSK/32APSK), FEC and symbol rate in the app
- **Test with a browser and ffmpeg:** save the settings at `http://<IP>/pluto.php`, then send a test stream from your PC

  ```
  ffmpeg -re -f lavfi -i testsrc=size=640x360:rate=25 -f lavfi -i sine=frequency=1000 \
    -c:v libx264 -b:v 300k -g 50 -c:a aac -b:a 64k -f mpegts "udp://<IP>:8282?pkt_size=1316"
  ```

- To check that the settings arrive, watch MQTT over SSH

  ```
  mosquitto_sub -h 127.0.0.1 -t 'cmd/pluto/#' -t 'dt/pluto/#' -v
  ```

  You should see `tx/dvbs2/constel`, `fec`, `sr`, `tx/frequency`, `tx/mute 0` and `tx/stream/run 1`

### Notes

- **Stopping the TS does not stop the transmitter automatically.** Use the app's stop button or another way to stop transmitting
- The roll-off is fixed at 0.35
- Maia-SDR features (waterfall, IQ recording, IQEngine) are not available
- When transmitting and receiving on the same Pluto, use USB or wired LAN, since the RX IQ data rate is high
- If something does not work, restart pluto_stream by hand over SSH and read its messages

  ```
  killall pluto_stream; pluto_stream 2>&1 | tee /tmp/pluto_stream.log &
  ```

### Going back

The FPGA build lives only on the SD card (the internal flash is not touched).

- **Remove the SD-H jumper** or **remove the SD card** to boot the original firmware from the internal flash
- Or swap in the SD card with the regular firmware and power-cycle

## Building it yourself

### Guides

| Guide | Scope |
|---|---|
| [`board/tezuka/plutoplus_udp_fpga/FPGA作成.md`](../board/tezuka/plutoplus_udp_fpga/FPGA%E4%BD%9C%E6%88%90.md) in this repository | The whole process (Vivado setup → FPGA → firmware → SD card → hardware checks). **Follow this one step by step** |
| [`hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md`](projects/plutoplus_dvb/PLUTOPLUS_DVB.md) in this repository | Details of the FPGA part (installing Vivado, building, reading the reports, moving files to the Mac) |

### Build (Linux PC, Vivado 2025.2)

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-fw.git
cd plutoplus-udp-fpga-fw
VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

### Contents

```
hdl/
  adi-hdl/              submodule (Analog Devices HDL)
  dvb_fpga/             submodule (DVB-S2 encoder)
  patches/dvb_fpga/     patches for dvb_fpga (applied automatically by the build script)
  projects/
    plutoplus_dvb/      build script, Makefile, project settings, guides
    boards/plutoplus_dvb/  Pluto+ board definition
    common/             block designs for the AD9361, DMA, TX FIR and DVB-S2 chain
```

## Origin

Extracted from the tezuka FPGA project on the `refactor` branch (5f28808) of [F5OEO/maia-sdr](https://github.com/F5OEO/maia-sdr), keeping only the parts used for transmit.
For the state before this cleanup (unchanged, including other boards and Maia-SDR itself), see the `refactor` branch of F5OEO/maia-sdr.

## Credits

This repository is built on the work of the following people and projects. Many thanks to all of them.

| Credit | Contribution | Links |
|---|---|---|
| **F5OEO** and contributors | The tezuka firmware and the FPGA project integrating the DVB-S2 chain (`refactor` branch of F5OEO/maia-sdr), which this repository is derived from. **Kindly gave permission to publish this repository** | https://github.com/F5OEO/maia-sdr<br>https://github.com/F5OEO/tezuka_fw |
| Daniel Estévez | Maia-SDR (the project this HDL originates from) | https://github.com/maia-sdr/maia-sdr<br>https://maia-sdr.org/ |
| Analog Devices | HDL for the AD9361, DMA and more (adi-hdl) | https://github.com/analogdevicesinc/hdl |
| Suoto and Open Research Institute | The dvb_fpga DVB-S2 encoder | https://github.com/OpenResearchInstitute/dvb_fpga |
| AMD engineer chaowen | The Vivado 2025 hold-violation workaround (`hold_fix.tcl`) | — |

Modified and maintained by Kazu Shinjo (JA6FUF/JH1XHX)

## License

Different parts are under different licenses. Follow the terms of each part when you use it.

| Part | License | Copyright | File |
|---|---|---|---|
| Changes and additions made to `hdl/` | MIT | Copyright (c) 2026 Kazu Shinjo (JA6FUF/JH1XHX) | [`hdl/LICENSE-modifications`](LICENSE-modifications) |
| `hdl/` (from F5OEO/maia-sdr and Maia-SDR) | MIT | Copyright (c) 2022-2024 Daniel Estévez | [`hdl/LICENSE`](LICENSE) |
| `hdl/adi-hdl` (submodule) | ADI's licenses, per file (BSD-style, GPL and others) | Analog Devices, Inc. | `LICENSE*` files in adi-hdl |
| `hdl/dvb_fpga` (submodule) | CERN-OHL-W v2 | Suoto / Open Research Institute | `LICENSE` in dvb_fpga |

**Note on dvb_fpga:** under section 4.1 of CERN-OHL-W v2, if you distribute hardware built with it (for example a device loaded with this bitstream),
you must show the source location https://github.com/phase4ground/dvb_fpga visibly on the product's exterior.

The MIT-licensed parts come with no warranty. See each `LICENSE` file for the full terms.
