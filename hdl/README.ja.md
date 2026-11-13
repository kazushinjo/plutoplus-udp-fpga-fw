# hdl/ — plutoplus_udp_fpga の FPGA

[English](README.md) | **日本語**

Pluto+(Zynq-7010)用の FPGA(ビットストリーム)を作るためのリポジトリ。
入っている回路は **DVB-S2 送信回路(dvb_fpga エンコーダ + RRC)・TX FIR ×8・AD9361 インターフェース(1R1T)・DMA** だけ。

> [!WARNING]
> **Maia-SDR には対応していません。**
> 元になった F5OEO/maia-sdr から HDL を引き継いでいますが、Maia-SDR の回路とソフトは取り除いています。
> 次のものは**使えません**:
>
> - Maia-SDR の Web 画面(スペクトラム・ウォーターフォール表示)
> - IQ 録音、IQEngine
> - tezuka ダッシュボードの Maia-SDR に関する機能(トップページは FPGA 版専用の状態ページに置き換えています)
>
> Zynq-7010 には Maia-SDR と DVB-S2 送信回路の両方は入らないため、送信回路を優先しました。
> Maia-SDR を使うときは、Maia-SDR 入りのファーム(tezuka の通常版など)で起動してください。内蔵フラッシュに入っていれば、SD カードを抜くか SD-H ジャンパを外すとそちらで起動します。

できた `plutoplus_dvb.xsa` は、このリポジトリの `plutoplus_udp_fpga` で使う([`board/tezuka/plutoplus_dvb/bitstream/`](../board/tezuka/plutoplus_dvb/bitstream/) に置く)。以前は別リポジトリ plutoplus-udp-fpga-firm だったものを、2026-11-14 にここへ統合した。

> このリポジトリは F5OEO 氏の許可を得て公開しています。
>
> これは Analog Devices の公式ファームではなく、Analog Devices のサポート対象外です。Pluto+ などの機器メーカーの公式ファームでもありません。Analog Devices・ADALM-Pluto は Analog Devices, Inc. の商標です。

> [!IMPORTANT]
> **UDP 専用のファームです。** Portsdown 4 で使っているアナログチューナー用のファームではありません。
> PC・スマホの UDP 送信アプリから UDP(ポート 8282)で送られる MPEG-TS を受け取り、DVB-S2 で送信する用途に変更しています。

## 対応機種(Zynq-7010 の Pluto+ だけ)

**このビットストリームとファームは、FPGA(SoC)が Zynq-7010(`XC7Z010`)の Pluto+ 専用です。**

| 項目 | 内容 |
|---|---|
| FPGA(SoC) | **Xilinx/AMD Zynq-7010**(`xc7z010clg400-1`) |
| RF IC | AD9363(動作確認したもの。周波数範囲は ad9364 設定で使用) |
| 確認した基板 | Pluto+(SD カードスロット・ギガビット LAN 付き) |

- Zynq-7020(`XC7Z020`)など、**ほかの IC を載せた基板では動きません**。ビットストリームは IC ごとに別のもので、互換性はありません
- 7010 は回路の容量が小さいため、Maia-SDR と DVB-S2 送信回路の両方は入りません(LUT 使用率 約 67%)。そのため Maia-SDR を外しています
- 手持ちの基板の IC は、基板上の Zynq の刻印(`XC7Z010` か `XC7Z020` か)や、購入時の仕様で確かめてください

## ファームウェアについて

このビットストリームを組み込んだファームが `plutoplus_udp_fpga` です。

- DVB-S2 の変調を ARM のソフトではなく **FPGA** で行う
- **SD カード起動専用**。内蔵フラッシュ(QSPI)には書き込まないので、SD カードを抜けば元のファームで起動する
- UDP 8282・iiod・SSH は通常版と同じポート・URL で使える
- Maia-SDR(ウォーターフォール・IQ 録音・IQEngine)は入っていない。送受信は 1 系統ずつ(1R1T)

配布物は `plutoplus-udp-fpga-firm.zip` で、SD カードに入れるファイルは zip の中の `sdimg/` にあります。
**このリポジトリの [リリース](https://github.com/kazushinjo/plutoplus-udp-fpga-fw/releases) 欄からダウンロードしてください**(`plutoplus-udp-fpga-firm-build<番号>`)。ライセンス文一式(`plutoplus-udp-fpga-firm-licenses.zip`)とチェックサム(`SHA256SUMS.txt`)も同じ所にあります。
ファームのソースは、このリポジトリのほかの部分です。

## SD カードへの書き込み

### 用意するもの

- SD カード: **32GB 以下**(32GB で動作確認)。**MBR・FAT32** で初期化する
- 通常版のファームを SD カードで使っている場合は、それを残しておき**別の SD カード**を使うと、元に戻すのが差し替えだけで済む

### Mac

1. zip を展開する

   ```
   cd ~/Downloads/plutoplus_dvb && unzip plutoplus-udp-fpga-firm.zip
   ```

2. SD カードを挿し、ディスク番号を確かめる(**間違えると別のディスクを消すので必ず確認**)

   ```
   diskutil list external physical
   ```

   外付け・容量が SD カードと同じもの(例: `/dev/disk4`)。以下の `diskN` をその番号に置き換える。

3. MBR・FAT32 で初期化する(**中身は全部消える**)

   ```
   diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/diskN
   ```

4. `sdimg/` の**中身**を SD カードの一番上にコピーする(`sdimg` フォルダごとではない)

   ```
   mdutil -i off /Volumes/PLUTOPLUS
   COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/
   dot_clean -m /Volumes/PLUTOPLUS
   ```

5. 照合して取り出す

   ```
   for f in BOOT.bin devicetree.dtb system_top.bin uEnv.txt uImage uramdisk.image.xz; do
     [ "$(md5 -q sdimg/$f)" = "$(md5 -q /Volumes/PLUTOPLUS/$f)" ] && echo "一致 $f" || echo "不一致 $f"
   done
   diskutil eject /dev/diskN
   ```

macOS が作る `.fseventsd`・`.Spotlight-V100` は消せないことがありますが、起動には影響しません。

### Windows・Linux

1. SD カードを **MBR(パーティション 1 つ)・FAT32** で初期化する
   (Windows で 32GB を超えるカードは標準の初期化で FAT32 を選べないので、32GB 以下のカードを使う)
2. zip を展開し、`sdimg/` の**中身**を SD カードの一番上にコピーする
3. 安全に取り外す

### SD カードの一番上の内容

| ファイル | 中身 |
|---|---|
| `BOOT.bin` | FSBL + U-Boot 2016.07(tezuka 0.2.4 のもの。下の「重要」を参照) |
| `system_top.bin` | FPGA ビットストリーム(このリポジトリで作ったもの) |
| `uImage` | Linux カーネル(**無圧縮**。U-Boot 2016.07 が LZMA を開けないため) |
| `uramdisk.image.xz` | rootfs(起動時に RAM へ展開) |
| `devicetree.dtb` | Pluto+ のデバイスツリー |
| `uEnv.txt` | U-Boot の設定 |

### 重要: SD 起動には古い U-Boot(2016.07)が必要

この Pluto+ は、**今の tezuka の U-Boot(2025.01)では SD カードから起動できません**
(緑 LED だけが点きっぱなしで、青が点かない)。本家 tezuka の最新版 BOOT.bin でも同じです。
SD 起動できるのは **tezuka 0.2.4 の BOOT.bin に入っている U-Boot 2016.07** だけでした。

そのため、このファームは次のようにしてあります(ビルド時に自動で行う)。

- SD 用の `BOOT.bin` を **tezuka 0.2.4 のもの**(FSBL + U-Boot 2016.07)にする
- U-Boot 2016.07 は LZMA 圧縮のカーネルを開けないので、`uImage` を**無圧縮**にする
- 0.2.4 の U-Boot が SD の `uEnv.txt` を読み、このファームのビットストリーム・デバイスツリー・rootfs で起動する

**注意:**

- `BOOT.bin` を新しい tezuka のもの(U-Boot 2025.01 入り)に入れ替えると SD 起動しなくなります
- 逆に、圧縮した `uImage` を入れると、FPGA まで進んで(緑と青)も Linux が起動しません
- FSBL は新旧で中身が同じで、原因ではありません。シリアルが無いため、新しい U-Boot が動かない詳しい原因は未確認です

### SD カードを抜かずに更新する

起動中の Pluto+ では SD カードが `/boot` にマウントされているので、ネットワーク経由で入れ替えられます。

```
cd sdimg
scp BOOT.bin uImage uramdisk.image.xz devicetree.dtb uEnv.txt system_top.bin root@<IP>:/boot/
ssh root@<IP> "sync; reboot"
```

## 使い方

### 起動

1. 電源とケーブルを外し、上ぶたを開けてジャンパを設定する(位置は基板のシルク参照)

   | ジャンパ | 設定 | 理由 |
   |---|---|---|
   | SD-H | **1V8** または **3V3**(基板のシルクにある方) | SD カードから起動する |
   | URST | **MIO46** | 内蔵 LAN(ギガビット)を使う |
   | EXCLK | 外部基準クロックを使うときだけ GND | 普段は外す |

2. SD カードを挿し、電源を入れる(5V 2A 以上)
3. LED: 緑と青が点けば FPGA まで進んでいる(青は FPGA の DONE)。20〜40 秒で Linux が起動し、USB ドライブ `TEZUKA` が出る。
   **緑だけが点きっぱなし(青が消えている)なら起動失敗**。SD カードの中身とジャンパを見直す

### 接続と確認

| 確認 | 方法 | 期待する結果 |
|---|---|---|
| ネットワーク | LAN(DHCP)または USB(Pluto 側 192.168.2.1) | ping が返る。LAN の IP はルーターで確認、mDNS では `pluto.local` |
| 状態ページ | ブラウザで `http://<IP>/` | 版名・シリアル・送信の状態が出る |
| DATV 設定 | `http://<IP>/pluto.php` | 送信設定の画面が出る |
| SSH | `ssh root@<IP>`(パスワード `analog`) | ログインできる |
| 版 | SSH で `cat /opt/VERSIONS` | `device-fw plutoplus-udp-fpga-firm_v1.0-…` |

USB ネットワークは CDC-NCM(macOS・Windows 10 2004 以降はドライバ不要)。
設定は内蔵フラッシュに保存され、USB ドライブ `TEZUKA` の `config.txt` を書き換えて取り出すと反映されます(固定 IP は `ipaddr_eth`)。

### ポート・URL

| ポート / URL | 使うもの | 中身 |
|---|---|---|
| UDP 8282 | UDP 送信アプリ | TS を受けて FPGA で DVB-S2 送信 |
| `http://<IP>/save.php`・`/pluto.php` | UDP 送信アプリ・ブラウザ | 送信設定の保存 |
| iiod(TCP 30431) | 送信アプリの受信・RSSI、Langstone | libiio |
| SSH 22 | UDP 送信アプリ | root / analog |
| `http://<IP>/`(80) | ブラウザ | 状態ページ |
| MQTT 1883 / WebSocket 9001 | 状態ページ、`mosquitto_sub` など | 送信の設定と状態(`cmd/pluto/#`・`dt/pluto/#`) |

### 送信する

**必ずアッテネーター(40dB など)とダミーロード/受信機をつないでから送信してください。**

- **UDP 送信アプリから**: いつもどおり送信する(UDP 8282)。変調(QPSK/8PSK/16APSK/32APSK)・FEC・シンボルレートはアプリで選ぶ
- **ブラウザと ffmpeg で試す**: `http://<IP>/pluto.php` で設定を保存し、PC から試験映像を送る

  ```
  ffmpeg -re -f lavfi -i testsrc=size=640x360:rate=25 -f lavfi -i sine=frequency=1000 \
    -c:v libx264 -b:v 300k -g 50 -c:a aac -b:a 64k -f mpegts "udp://<IP>:8282?pkt_size=1316"
  ```

- 設定が届いているかは SSH で MQTT を見て確かめる

  ```
  mosquitto_sub -h 127.0.0.1 -t 'cmd/pluto/#' -t 'dt/pluto/#' -v
  ```

  `tx/dvbs2/constel`・`fec`・`sr`・`tx/frequency`・`tx/mute 0`・`tx/stream/run 1` が流れればよい

### 注意

- **TS を止めても送信は自動では止まりません。** アプリの送信停止など、送信を止める操作をしてください
- ロールオフは 0.35 固定
- Maia-SDR の機能(ウォーターフォール・IQ 録音・IQEngine)は使えない
- 同じ Pluto で送受信するときは受信 IQ が多いので、USB か有線 LAN で接続する
- うまくいかないときは SSH で pluto_stream を手で起動し直し、メッセージを見る

  ```
  killall pluto_stream; pluto_stream 2>&1 | tee /tmp/pluto_stream.log &
  ```

### 元に戻す

FPGA 版は SD カードにしか入っていません(内蔵フラッシュには触れない)。

- **SD-H ジャンパを外す**か **SD カードを抜く**と、内蔵フラッシュの元のファームで起動する
- 通常版の SD カードに差し替えて電源を入れ直す

## 自分でビルドする

### 手順書

| 手順書 | 範囲 |
|---|---|
| このリポジトリの [`board/tezuka/plutoplus_udp_fpga/FPGA作成.md`](../board/tezuka/plutoplus_udp_fpga/FPGA%E4%BD%9C%E6%88%90.md) | 最初から最後まで(Vivado の準備 → FPGA → ファーム → SD カード → 実機確認)。**作業はこちらを順に** |
| このリポジトリの [`hdl/projects/plutoplus_dvb/PLUTOPLUS_DVB.md`](projects/plutoplus_dvb/PLUTOPLUS_DVB.md) | FPGA を作るところの詳しい説明(Vivado の入れ方、ビルド、レポートの見方、Mac への移し方) |

### ビルド(Linux PC、Vivado 2025.2)

```
git clone -b main https://github.com/kazushinjo/plutoplus-udp-fpga-fw.git
cd plutoplus-udp-fpga-fw
VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
  hdl/projects/plutoplus_dvb/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
```

### 中身

```
hdl/
  adi-hdl/              サブモジュール(Analog Devices の HDL)
  dvb_fpga/             サブモジュール(DVB-S2 エンコーダ)
  patches/dvb_fpga/     dvb_fpga に当てる修正(ビルド用スクリプトが自動で当てる)
  projects/
    plutoplus_dvb/      ビルド用スクリプト・Makefile・プロジェクト設定・手順書
    boards/plutoplus_dvb/  Pluto+ 基板の定義
    common/             AD9361・DMA・TX FIR・DVB-S2 送信回路のブロック設計
```

## 由来

[F5OEO/maia-sdr](https://github.com/F5OEO/maia-sdr) の `refactor` ブランチ(5f28808)にある tezuka 用 FPGA プロジェクトから、送信に使う部分だけを取り出したもの。
整理前(元のまま、ほかの基板や Maia-SDR 本体を含む)の状態は、元の F5OEO/maia-sdr の `refactor` ブランチを参照。

## クレジット

このリポジトリは、次の方々とプロジェクトの成果の上に作られています。心より感謝いたします。

| 提供元 | 内容 | リンク |
|---|---|---|
| **F5OEO 氏**と貢献者の方々 | tezuka ファームと、DVB-S2 送信回路を組み込んだ FPGA プロジェクト(F5OEO/maia-sdr の `refactor` ブランチ)。このリポジトリの元。**公開を許可していただきました** | https://github.com/F5OEO/maia-sdr<br>https://github.com/F5OEO/tezuka_fw |
| Daniel Estévez 氏 | Maia-SDR(HDL の元になったプロジェクト) | https://github.com/maia-sdr/maia-sdr<br>https://maia-sdr.org/ |
| Analog Devices | AD9361・DMA などの HDL(adi-hdl) | https://github.com/analogdevicesinc/hdl |
| Suoto 氏と Open Research Institute | DVB-S2 エンコーダ dvb_fpga | https://github.com/OpenResearchInstitute/dvb_fpga |
| AMD のエンジニア chaowen 氏 | Vivado 2025 のホールド違反の回避策(`hold_fix.tcl`) | — |

改造・整理: Kazu Shinjo (JA6FUF/JH1XHX)

## ライセンス

部分ごとにライセンスが違います。使うときはそれぞれの条件に従ってください。

| 部分 | ライセンス | 著作権者 | ファイル |
|---|---|---|---|
| `hdl/` に加えた変更・追加 | MIT | Copyright (c) 2026 Kazu Shinjo (JA6FUF/JH1XHX) | [`hdl/LICENSE-modifications`](LICENSE-modifications) |
| `hdl/`(F5OEO/maia-sdr・Maia-SDR 由来) | MIT | Copyright (c) 2022-2024 Daniel Estévez | [`hdl/LICENSE`](LICENSE) |
| `hdl/adi-hdl`(サブモジュール) | ADI の各ライセンス(BSD 系・GPL など、ファイルごと) | Analog Devices, Inc. | adi-hdl 内の `LICENSE*` |
| `hdl/dvb_fpga`(サブモジュール) | CERN-OHL-W v2 | Suoto / Open Research Institute | dvb_fpga 内の `LICENSE` |

**dvb_fpga についての注意:** CERN-OHL-W v2 の 4.1 項により、これを使ったハードウェア(このビットストリームを書き込んだ機器など)を配布するときは、
ソースの場所 https://github.com/phase4ground/dvb_fpga を製品の外装に見えるように書く必要があります。

MIT ライセンスの部分は無保証です。詳しくは各 `LICENSE` ファイルを見てください。
