# Pluto+ Shonan_Lite 版(plutoplus_shonan)

tezuka の Pluto+ 用ファーム(`configs/plutoplus_maiasdr_defconfig`)に、
Shonan_Lite と Portsdown 4 が使う DATV 送信の部品(kazushinjo/datvplutofrm の v0.39-shonan ブランチ)を足したもの。
tezuka の機能(maia-sdr、IQEngine、ダッシュボード、MQTT など)はすべて残している。

イメージが QSPI のファーム領域(0x1E00000 = 31,457,280 バイト)に入らないため、**SD カード起動専用**。
`pluto.frm` / `pluto.dfu` は作らない(zip の `flash/` は空)。

## 目次

1. [元にしたもの](#元にしたもの)
2. [ビルド(GitHub Actions)](#ビルドgithub-actions)
3. [SD カードの作り方(Mac)](#sd-カードの作り方mac)
4. [Pluto+ の準備と起動](#pluto-の準備と起動)
5. [起動後の確認](#起動後の確認)
6. [使い方(ポート・URL)](#使い方ポートurl)
7. [SD カードの中身を更新する](#sd-カードの中身を更新する)
8. [足したもの](#足したもの)
9. [Portsdown 4 から使う機能](#portsdown-4-から使う機能)
10. [datvplutofrm から持ってこなかったもの](#datvplutofrm-から持ってこなかったもの)
11. [リポジトリと CI の注意](#リポジトリと-ci-の注意)
12. [SD 起動しなかった件(2026-10-24)](#sd-起動しなかった件2026-10-24)
12. [ビルド履歴](#ビルド履歴)
13. [未確認](#未確認)
14. [FPGA 版(plutoplus_shonan_dvb)](#fpga-版plutoplus_shonan_dvb)
15. [ライセンス](#ライセンス)

## 元にしたもの

| もの | 版 |
|---|---|
| tezuka_fw(F5OEO) | github.com/F5OEO/tezuka_fw `a304a1f`(v0.3.24、2026-10-17) |
| Buildroot | 2026.05.2(`buildroot.version`) |
| Linux | ADI linux `bf1d49f`(adi-6.12.y)、glibc 2.40、Bootlin ツールチェーン |
| DATV 送信の部品 | kazushinjo/datvplutofrm `v0.39-shonan`(build10 = 2649143 と同じ内容) |
| Portsdown 4 | BritishAmateurTelevisionClub/portsdown4 `0b886da`(2026-10-18)のソースで利用機能を確認 |

Pluto+ は無印 Pluto と同じ Zynq-7010(Cortex-A9 2 コア)・RAM 512MB。FPGA とデバイスツリーは機種専用だが、
ARM 側の実行ファイルは共通なので `pluto_dvb` と `tsp` はビルド済みのものをそのまま使っている
(必要なライブラリ libiio.so.0(0.26)・libstdc++ などは tezuka 側に全部ある)。

## ビルド(GitHub Actions)

Mac ではビルドできない(Buildroot は x86_64 Linux が必要)。GitHub Actions で作る。

```
gh workflow run main.yml --repo kazushinjo/plutoplus_fw-shonan --ref shonan -f boards=plutoplus_shonan
gh run list --repo kazushinjo/plutoplus_fw-shonan --workflow main.yml --limit 3
```

- できた zip はプレリリース `plutoplus_shonan-build<実行番号>` に付く(Artifacts は容量上限のため当てにしない)。
- 所要時間: キャッシュの無い初回で約 2 時間 40 分(U-Boot 36 分・カーネル 46 分・rootfs 68 分)。
  2 回目からはキャッシュが効く。非公開リポジトリなので Actions の無料枠(月 2000 分)を使う。
- Linux 機で手元ビルドする場合:

```
./getbuildroot.sh
./build.sh plutoplus_shonan
```

できたものは `build/plutoplus_shonan.zip`。

## SD カードの作り方(Mac)

使った SD カード: 32GB(31.0GB と表示)。32GB 以下・FAT32 にする。

1. プレリリースから zip を取ってきて展開する

   ```
   gh release download plutoplus_shonan-build2 --repo kazushinjo/plutoplus_fw-shonan --dir ~/Downloads/plutoplus
   cd ~/Downloads/plutoplus && unzip plutoplus_shonan.zip
   ```

2. SD カードを挿し、ディスク番号を確かめる(**間違えると別のディスクを消すので必ず確認**)

   ```
   diskutil list external physical
   ```

   外付け・取り外し可能・容量が SD カードと同じもの(例: `/dev/disk4`、31.0 GB)。

3. MBR・FAT32 で初期化する(中身は全部消える)

   ```
   diskutil eraseDisk FAT32 PLUTOPLUS MBRFormat /dev/disk4
   ```

4. `sdimg/` の**中身**を SD カードの一番上にコピーする(`sdimg` フォルダごとではない)

   ```
   mdutil -i off /Volumes/PLUTOPLUS
   COPYFILE_DISABLE=1 cp -R sdimg/ /Volumes/PLUTOPLUS/
   dot_clean -m /Volumes/PLUTOPLUS
   ```

   SD カードの一番上がこうなっていればよい:

   | ファイル | 中身 |
   |---|---|
   | `BOOT.bin` | **tezuka 0.2.4 の BOOT.bin**(FSBL + 0.2.4 のビットストリーム + U-Boot 2016.07)。今の tezuka の U-Boot 2025.01 はこの Pluto+ で SD 起動しないため(下の「SD 起動しなかった件」) |
   | `system_top.bin` | FPGA ビットストリーム(U-Boot が読み込む。`tezuka_top.bin` は同じもの、`system_top_top.bin` は別の候補) |
   | `uImage` | Linux カーネル(**無圧縮**。U-Boot 2016.07 が LZMA を開けないため) |
   | `uramdisk.image.xz` | rootfs(起動時に RAM へ展開) |
   | `devicetree.dtb` | Pluto+ のデバイスツリー(model「Pluto+ (Z7010/AD9363)」) |
   | `uEnv.txt` | U-Boot の設定 |

   macOS が作る `.fseventsd`・`.Spotlight-V100` は消せないことがあるが、起動には影響しない。

5. 照合して取り出す

   ```
   for f in BOOT.bin devicetree.dtb system_top.bin uEnv.txt uImage uramdisk.image.xz; do
     [ "$(md5 -q sdimg/$f)" = "$(md5 -q /Volumes/PLUTOPLUS/$f)" ] && echo "一致 $f" || echo "不一致 $f"
   done
   diskutil eject /dev/disk4
   ```

## Pluto+ の準備と起動

1. 電源とケーブルを全部外し、上ぶたのネジ 4 本を外す
2. ジャンパを設定する(ジャンパの位置は基板のシルク参照、IO は 1.8V)

   | ジャンパ | 設定 | 理由 |
   |---|---|---|
   | SD-H | **1V8** または **3V3** に接続(基板のシルクにある方。この Pluto+ は **3V3**) | SD カードから起動する。修理記事では v1 基板は 1.8V |
   | URST | **MIO46** に接続 | 内蔵 LAN(ギガビット)を使う。MIO52 は ADI 公式ファーム用 |
   | EXCLK | 外部基準クロックを使うときだけ GND | 普段は外す |

3. SD カードを挿し、電源を入れる(5V 2A 以上、micro USB)
4. LED: 緑と青が点けば FPGA まで進んでいる(青は FPGA の DONE)。20〜40 秒で Linux が起動し、USB ドライブ(`TEZUKA`)が出る。
   **緑だけが点きっぱなし(青が消えている)なら起動失敗**(FSBL か U-Boot で止まっている。SD カードの中身・ジャンパを見直す)
5. 元のファーム(内蔵フラッシュ)に戻すときは SD-H のジャンパを外す

## 起動後の確認

| 確認 | 方法 | 期待する結果 |
|---|---|---|
| ネットワーク | LAN(DHCP)または USB(Pluto 側 192.168.2.1、PC 側 192.168.2.10) | ping が返る。LAN の IP はルーターで確認。mDNS では `pluto.local` |
| DATV の Web 画面 | `http://<IP>/pluto.php` | Controller 画面が出る |
| tezuka のダッシュボード | `http://<IP>/` | maia-sdr / Tezuka Dashboard が出る(lighttpd 経由) |
| SSH | `ssh root@<IP>`(パスワード analog) | ログイン表示に `Version ShonanLite-Portsdown4_v1.0-…`・`Shonan_Lite / Portsdown 4 edition for Pluto+`・`v1.0-ShonanLite-Portsdown4-…` の行(build5 までは `v6822-shonan` など) |
| iio | `iio_info -u ip:<IP>` | ad9361-phy などが見える |
| 版 | `cat /opt/VERSIONS` | `device-fw ShonanLite-Portsdown4_v1.0-<コミット>`、`base tezuka-<コミット>`、`buildroot 2026.05.2`(build5 までは `device-fw tezuka-…`) |

LAN の固定 IP は tezuka の仕組み(USB ドライブの `config.txt` の `[USB_ETHERNET] ipaddr_eth` / `fw_setenv ipaddr_eth`)で設定する。

### 設定についての注意

- 設定(u-boot の環境変数)は **内蔵フラッシュ(QSPI)に保存**される。SD 起動でも内蔵フラッシュのファームと同じ設定を使う。
  `fw_setenv` や USB ドライブの `config.txt`(書き換えてドライブを取り出すと保存、`SUCCESS_ENV_UPDATE` が出る)で変える
- **USB ネットワーク**: 内蔵フラッシュに `usb_ethernet_mode = rndis` が入っていると、このビルドの既定(NCM)より優先される。
  Mac で使うには `config.txt` の `usb_ethernet_mode = ncm` にして取り出し、再起動する(この Pluto+ は 2026-10-24 に ncm に変更済み)
- **周波数範囲**: 内蔵フラッシュの 0.2.4 の設定は `attr_val=ad9363a`。tezuka のカーネルは ad9363a のままでも 46.875MHz〜6GHz を受け付けたが、
  今までの Pluto と同じにするため `fw_setenv attr_val ad9364`(`attr_name=compatible`)にして再起動した。
  起動ログが `ad9361_probe : enter (ad9364)` になる。`mode=1r1t`(受信 1・送信 1)
- **起動直後の UDP 8282**: `settings.txt` が無い間は udpts.sh が空の設定で待つ(datvplutofrm v0.39 と同じ)。
  Shonan_Lite から設定を保存(save.php)すると待ち受けを始める
- **SSH のホスト鍵**: build2 では ed25519・rsa の鍵が内蔵フラッシュに保存されず、再起動のたびに変わっていた
  (下の「SD 起動しなかった件」の後の修正を参照)。この Pluto+ では 2026-10-24 に手で 3 種類とも保存済み

## 使い方(ポート・URL)

| ポート / URL | 使うもの | 中身 |
|---|---|---|
| UDP 8282 | Shonan_Lite 全版 | TS を受けて tsp → pluto_dvb で送信(設定は `/www/settings.txt`) |
| `http://<IP>/save.php`・`/pluto.php` | Shonan_Lite | 送信設定の保存・再起動(lighttpd + php-cgi) |
| rtmp 7272 | Portsdown 4 | `rtmp://<IP>:7272/,周波数,…,/コール,` → rtmppluto.sh → ffmpeg → tsp → pluto_dvb |
| iiod(TCP 30431) | Shonan_Lite の受信・RSSI、Langstone、Portsdown 4 | libiio |
| SSH 22 | Shonan_Lite、Portsdown 4 | root / analog |
| `http://<IP>/`(80) | ブラウザ | tezuka ダッシュボード(maia-httpd 127.0.0.1:8000 へ中継、WebSocket も) |
| 443 | ブラウザ | maia-httpd の HTTPS(tezuka のまま) |
| MQTT 1883 / WebSocket 9001 | tezuka ダッシュボード | mosquitto(tezuka のまま) |

USB ネットワークは CDC-NCM が既定(macOS・Windows 10 2004 以降はドライバ不要)。
RNDIS にしたいときは `fw_setenv usb_ethernet_mode rndis` して再起動。

## SD カードの中身を更新する

起動中の Pluto+ では SD カードの FAT 領域が `/boot` にマウントされているので、カードを抜かずに更新できる。

```
scp sdimg/{BOOT.bin,uImage,uramdisk.image.xz,devicetree.dtb,uEnv.txt,system_top.bin} root@<IP>:/boot/
ssh root@<IP> "sync; reboot"
```

## 版の名前

tezuka の正式版と間違えないよう、build6 から独自の名前にしている(`post-build.sh`)。

| 版 | 名前の例 |
|---|---|
| plutoplus_shonan | `ShonanLite-Portsdown4_v1.0-e019` |
| plutoplus_shonan_dvb(FPGA 版) | `ShonanLite-Portsdown4-FPGA_v1.0-e019` |

- `v1.0` は `board/tezuka/shonan/VERSION` の数字。版を上げるときはこのファイルを書き換える。最後はこのリポジトリのコミット番号(4 桁)
- 出る場所: `/opt/VERSIONS` の `device-fw`、USB ドライブの `info.html` の Build、iiod の `fw_version`(Shonan_Lite の「Pluto 情報」・tezuka ダッシュボード)、
  SSH のログイン表示、U-Boot の起動表示(シリアル)
- 元にした tezuka の版は `board/tezuka/shonan/TEZUKA_BASE`(今は `tezuka-v0.3.24-a304a1f`)に書いておき、`/opt/VERSIONS` の `base` とログイン表示の `(base …)` に出す。
  本家 tezuka を取り込んだら、このファイルも書き換える
- Portsdown 4 は SSH の出力のうち `v` で始まる行を版として表示する → `v1.0-ShonanLite-Portsdown4-e019`
- USB ドライブの名前(`TEZUKA`)とログイン表示の tezuka のロゴ・「By F5OEO and contributors」は、元の作者の表示としてそのまま

## 足したもの

| 部品 | 内容 |
|---|---|
| `overlay/root/pluto_dvb`, `udpts.sh`, `rtmppluto.sh` ほか | UDP 8282 → tsp → pluto_dvb、rtmp 7272 → ffmpeg → tsp → pluto_dvb(datvplutofrm と同じもの。pluto_dvb と tsp はビルド済みの実行ファイル) |
| `overlay/usr/bin/tsp`, `overlay/usr/lib/ts*` | TSDuck(プラグインは ip・file・sdt・analyze・pcrextract の 5 個) |
| `overlay/www/` | save.php・pluto.php など DATV の Web 画面 |
| `overlay/etc/lighttpd/lighttpd.conf` | ポート 80。DATV の PHP ページと `img/`・`lib/` などだけ自分で返し、それ以外は maia-httpd(127.0.0.1:8000)へ中継する(WebSocket も) |
| `overlay/etc/php.ini` | datvplutofrm と同じ(`cgi.force_redirect = 0`、`post_max_size = 30M`) |
| `overlay/etc/init.d/S90datv` | 起動時に udpts.sh・rtmppluto.sh・watchudp.sh を起動 |
| `overlay/etc/init.d/S89patchfirm`, `overlay/usr/sbin/device_persistent_keys` | SSH のホスト鍵(ecdsa・ed25519・rsa)を起動時に作って保存する。電源断の後も鍵が変わらない。`/mnt/jffs2/patch.zip` があれば展開 |
| `post-build.sh` | maia-httpd を 127.0.0.1:8000 へ移す、USB ネットワークの既定を NCM にする、ログイン表示に `v…-shonan` 行、fwversion.txt・releasenote.txt 作成 |
| defconfig | lighttpd(pcre)、PHP 8.5(cgi・cli・session・sockets)、bc、ffmpeg 6.1.5(datvplutofrm v0.39-shonan と同じ最小構成)。ホスト名は Langstone の既定に合わせて `pluto`。`postimage-qspi.sh` を外し SD カード用だけ作る |
| `.github/workflows/main.yml` | 手動ビルドで zip をプレリリースに付ける、非公開リポジトリでは attest を飛ばし Artifacts の保存失敗で止まらない |

## Portsdown 4 から使う機能

BritishAmateurTelevisionClub/portsdown4(0b886da、2026-10-18)のソースで確認したもの。

| Portsdown 4 が使うもの | この版での扱い |
|---|---|
| `rtmp://<pluto>:7272/,周波数,…,/コール,`(DVB-S/S2 送信) | rtmppluto.sh → ffmpeg → tsp → pluto_dvb。ffmpeg 6.1.5 にも rtmppluto.sh が読む「App field don't match up」「Unexpected stream」の表示がある |
| DVB-T 送信・バンドビューアなど(Pi から libiio で IQ をやりとり) | tezuka の iiod |
| SSH(root/analog)の reboot・`cat /proc/cpuinfo` | tezuka のまま |
| `fw_setenv attr_name compatible` / `attr_val ad9364`、`maxcpus`、`xo_correction` | tezuka の u-boot(adi_config_devicetree)と S21misc が同じ変数を読む |
| 版の表示(`ssh root@<pluto>` の出力から `^v` の行を拾う) | tezuka のログイン表示には無いので、post-build.sh で `v…-shonan` の行を足した |

Portsdown 4 の設定(`plutoip`)は Pluto+ の LAN の IP にする。

## datvplutofrm から持ってこなかったもの

- S94pluto-mods(70〜6000MHz 化・2 コア化): tezuka の Pluto+ はデバイスツリーが最初から `adi,ad9361`、`maxcpus=2` なので不要
- S45msd の修正: tezuka の S45msd は `/www` を USB ドライブへコピーしないので不要
- busybox httpd の設定、readsettings.sh(OpenWebRX 用)、motd、wpa_supplicant: tezuka 側のものを使う

## リポジトリと CI の注意

- リポジトリ: kazushinjo/plutoplus_fw-shonan(非公開)。既定ブランチ `shonan`、`main` は tezuka の元のまま。
  手元の作業場所は `~/AppDev/tezuka_fw-shonan`(remote: `origin` = このリポジトリ、`upstream` = F5OEO/tezuka_fw)。
- tezuka のタグ(`v0.3.x`)は push しない。タグを push すると全機種のリリースビルドが動く。
  そのため版の表示はタグでなくコミット番号になる(例: `v6822-shonan`)。
- GitHub は、履歴ごとまとめて push した最初の分からはワークフローを登録しなかった。
  `main.yml` を変更するコミットを push したら登録された。
- Artifacts の容量が上限(Artifact storage quota has been hit)のため、zip はプレリリースで受け取る。
- tezuka の CLAUDE.md に合わせ、コミットメッセージは ASCII のみ。
- FPGA 版の HDL は別の非公開リポジトリ kazushinjo/maia-sdr-plutoplus-dvb(Actions は無効)。詳しくは「FPGA 版」の節。
- tezuka 本家の更新を取り込むとき: `git fetch upstream && git merge upstream/main`(shonan ブランチで)

## SD 起動しなかった件(2026-10-24)

### 症状

build2 の SD カード(SD-H=3V3)で電源を入れると、**緑 LED だけが点きっぱなし**(青が点かない)で、Mac に USB 機器が何も出なかった。
SD-H を外すと内蔵フラッシュ(tezuka 0.2.4)は今までどおり起動した(ケーブル・基板は正常)。

### 切り分け

| 試したこと | 結果 | 分かったこと |
|---|---|---|
| 本家 tezuka 0.2.4 の `plutoplus.zip` の `sdimg/` を SD に | **起動した** | 基板・SD-H=3V3・SD カード(32GB、MBR/FAT32)は問題ない |
| build2 の BOOT.bin と本家 v0.3.24 の BOOT.bin を比較 | 版の文字の 8 バイトだけ違う | 本家の最新版もこの Pluto+ では SD 起動しない見込み |
| 0.2.4 の BOOT.bin + build2 の残り | 緑と青(FPGA まで)。USB は出ない | 0.2.4 の FSBL・U-Boot は動く。Linux まで行かない |
| FSBL を 0.2.4 時代(3355a86)に戻してビルド(ブランチ test-oldfsbl、build4) | 書き込み前に中身を比較して不要と判断 | 新旧 fsbl.elf の**書き込まれる中身は同じ**(違いは ELF の付属情報だけ)。FSBL は原因でない |
| U-Boot の版 | 0.2.4 は **U-Boot 2016.07**、今の tezuka は **U-Boot 2025.01** | 新しい U-Boot がこの基板の SD 起動で動かない(シリアルが無いので詳しい原因は未確認) |
| カーネルの形式 | 0.2.4 は無圧縮(zImage)、今は **LZMA 圧縮**の uImage | 0.2.4 の U-Boot は LZMA を開けない(3 行目で Linux まで行かなかった理由) |
| **0.2.4 の BOOT.bin + build2 のカーネルを無圧縮の uImage に作り直したもの + build2 の残り** | **起動した** | 版 `tezuka-6822`・`v6822-shonan`、全プロセスと全ポート、pluto.php・ダッシュボードを確認 |

### 対処(ビルドに反映)

- `postimage-legacy-sd.sh`(新規、両方の defconfig の post-image に追加): SD 用の BOOT.bin を `legacy-boot/plutoplus-0.2.4-BOOT.bin` にし、
  カーネルを無圧縮の uImage(load/entry 0x8000)にする。`overclock/`(新しい U-Boot 入り)は作らない
- 0.2.4 の U-Boot は SD の `uEnv.txt`(このビルドのもの)を読み込み、このビルドのビットストリーム・デバイスツリー・ramdisk で起動する
- `device_persistent_keys`: 保存済みの `keys.md5`(ecdsa だけ)に対する `md5sum -c` が通ってしまい、ed25519・rsa が保存されていなかった。
  3 種類の鍵の md5 一式を比べるように直した
- CI: 出力キャッシュを使うと `images/system_top.bit` が無くて BOOT.bin が作れなかった(postimage-sd.sh が古い `system_top.xsa` の処理で
  同じ名前のファイルを消すため)。イメージ組み立ての前に `board-fpga-reinstall` するようにした

## ビルド履歴

| 版 | コミット | 日付 | 結果 |
|---|---|---|---|
| plutoplus_shonan-build2 | 6822(shonan) | 2026-10-24 | ビルド成功(2h39m、zip 33.5MB、uramdisk 26MB)。**そのままでは SD 起動しない**(U-Boot 2025.01)。0.2.4 の BOOT.bin と無圧縮カーネルに手で入れ替えて起動・動作確認(上の「SD 起動しなかった件」) |
| plutoplus_shonan-build4 | test-oldfsbl | 2026-10-24 | FSBL を戻した試験。FSBL は原因でないと分かったので使っていない(ブランチは削除) |
| plutoplus_shonan-build5 | e0191b1(shonan) | 2026-10-24 | SD 用 BOOT.bin が 0.2.4 のもの(md5 a6ce0ad4…)・カーネル無圧縮(0x8000)・overclock なし・鍵保存の修正入りを確認。版の表示はまだ `tezuka-e019`。実機は未書込み |
| plutoplus_shonan-build6 | 8c48a34(shonan) | 2026-10-28 | 版の名前 `ShonanLite-Portsdown4_v1.0-8c48` を確認。`base` が `tezuka-8c48`(このリポジトリのコミット)になっていたので TEZUKA_BASE で直した |
| plutoplus_shonan_dvb | — | — | 未ビルド(FPGA の tezuka.xsa 待ち) |

## 未確認

- 実機での送信(Shonan_Lite・Portsdown 4 から)。起動・Web(pluto.php・pluto_temp.php・ダッシュボードの表示)・iiod・SSH は確認済み
- lighttpd 経由での tezuka ダッシュボードの WebSocket(ウォーターフォールなど)
- U-Boot 2025.01 が SD 起動しない詳しい原因(シリアルコンソールで確認したい)
- maia-sdr の受信と pluto_dvb の送信を同時に使ったときの動き
- Pluto+ の PTT(GPIO0/MIO0)と、requests.php の PTT ボタン(AD9361 の GPO を操作する)の対応
- Shonan_Lite 各版・Portsdown 4 からの接続

## FPGA 版(plutoplus_shonan_dvb)

DVB-S2 の変調を ARM のソフト(pluto_dvb)ではなく **FPGA の DVB-S2 送信回路**で行う版。
Pluto+ の 7010 には Maia-SDR と DVB-S2 送信回路の両方は入らないので、**Maia-SDR を外して**いる。

| 項目 | plutoplus_shonan | plutoplus_shonan_dvb |
|---|---|---|
| FPGA | tezuka 本家の plutoplus(Maia-SDR 入り、2R2T) | plutoplus_dvb(DVB-S2 エンコーダ + RRC ×4 + TX FIR ×8、1R1T、Maia-SDR なし) |
| DATV の変調 | ARM のソフト(pluto_dvb) | FPGA(pluto_stream が操作) |
| Maia-SDR・IQEngine・ウォーターフォール | あり | なし |
| tezuka ダッシュボード | maia-httpd 経由 | lighttpd が `/root` をそのまま返す(MQTT の操作は使える。スペクトル表示などは使えない) |
| Shonan_Lite(UDP 8282)・Portsdown 4(rtmp 7272)・iiod・SSH | 使える | 使える(同じ URL・ポート) |

### なぜ Maia-SDR を外すか

- tezuka 本家では、FPGA の DVB-S2 送信回路(`dvbs2_encoder_wrapper`)は 7020 の機種(E200・E310・LibreSDR・Fishball 7020・
  PlutoSky R2・SignalSDR Pro)にしか入っていない。Pluto+ と無印 Pluto(7010)のビットストリームには無い
  (各機種の `bitstream/tezuka.xsa` の中の hwh で確認)
- 7010 の資源は LUT 17,600 / DSP 80 / BRAM36 60。F5OEO の実測(tezuka_fw `doc/fpga_usage.md`、plutoskyr2)では
  全部入りで LUT 23,005・DSP 106。DDS を外し 1R1T にして LUT 17,388・DSP 88 まで減らしても DSP が上限を超える
- さらに Maia-SDR(LUT 3,414・DSP 18・BRAM36 21 + BRAM18 16)を外すと、LUT 約 14,000・DSP 約 70・BRAM36 約 27 の見込みで収まる
  (見積もり。実際の値は Vivado のレポートで確かめる)

### FPGA の設計(HDL)

- リポジトリ: **kazushinjo/maia-sdr-plutoplus-dvb**(非公開)、ブランチ `plutoplus-dvb`
  - 元: F5OEO/maia-sdr の `refactor` ブランチ `5f28808`(2026-10-20)。tezuka 用の FPGA プロジェクト `maia-hdl/projects/tezuka` が入っている
  - 変更: `6f37fcd`(plutoplus_dvb の追加)、`95c0f68`(手順書 `maia-hdl/projects/tezuka/PLUTOPLUS_DVB.md`)
  - 手元の作業場所: `~/AppDev/maia-sdr-dvb`(remote: `origin` = このリポジトリ、`upstream` = F5OEO/maia-sdr)
  - 元の maia-sdr の GitHub Actions(maia-hdl・maia-httpd など)が push で動いたので、全部取り消し、このリポジトリの Actions は無効にした
- プロジェクト `plutoplus_dvb`(`maia-hdl/projects/tezuka/system_bd.tcl`): `nomaia`・`mode1r1t`・`txfir`・`dvb`

| ファイル | 変更 |
|---|---|
| `tezuka/system_bd.tcl` | `plutoplus_dvb` の設定。`nomaia` のとき maia.tcl・maiafirtoiq.tcl・sweeper.tcl・cs12_cs8.tcl を読まない(どれも Maia-SDR の経路に依存) |
| `tezuka/system_project.tcl` | `plutoplus_dvb` のデバイス `xc7z010clg400-1` |
| `common/nomaia.tcl`(新規) | ADC/DAC の DMA を HP2 へ(maia.tcl がしていたこと)、HP1 を無効に |
| `common/xilinx_ad9361.tcl` | `mode1r1t` のとき `MODE_1R1T 1`(F5OEO が plutoskyr2 で試した変更と同じ考え方。refactor ブランチには未反映だった) |
| `tezuka/Makefile` | `SKIP_IP_CORES=1` で Maia-SDR の IP 生成(Python/Amaranth・Yosys)を飛ばす |
| `boards/plutoplus_dvb/` | `boards/plutoplus/` へのシンボリックリンク(基板は同じ) |
| `tezuka/build_plutoplus_dvb.sh` | Linux 用のビルドスクリプト。サブモジュール(adi-hdl・dvb_fpga とその third_party)の取得 → `make SKIP_IP_CORES=1 plutoplus_dvb.sdk/system_top.xsa` → `make install`、レポートをコピー |

- DVB-S2 送信回路は `maia-hdl/dvb_fpga` サブモジュール(OpenResearchInstitute/dvb_fpga、CERN-OHL-W v2)
- FPGA 側の DVB 回路のつながり(`common/dvb.tcl`): DAC DMA → switchsrc → エンコーダ → switchfir → RRC ×4 → switchdest → upack → AD9361。
  スイッチ・エンコーダのレジスタ(0x43C01000〜0x43C10000)は pluto_stream が `/dev/mem` で直接操作する(デバイスツリーの追加は不要)
- このスイッチは起動直後どこにもつながっていないため、FPGA 版ではソフトの pluto_dvb(DMA で IQ を送る)では電波が出ない。
  そのため送信は pluto_stream 経由にした(下の「仕組み」)

### 仕組み

- `/root/pluto_dvb` を差し替えスクリプト(`overlay_dvb/root/pluto_dvb.fpga`)にした。udpts.sh・rtmppluto.sh は変えていない
  - 同じオプション(`-m -c -s -f -t -g -p -v -i`)を受け取り、MQTT で設定を送る
    - pluto_stream へ: `cmd/pluto/<call>/tx/stream/mode`(dvbs2-ts / dvbs)、`tx/dvbs2/constellation`・`fec`・`frame`・`pilots`・`sr`、
      `tx/dvbs2/tssourceaddress`(127.0.0.1:1314)、`tx/stream/run`
    - pluto_mqtt_ctrl へ: `tx/frequency`(Hz)、`tx/gain`、`tx/mute`
    - `<call>` は `fw_printenv call`(無ければ `nocall`)。pluto_stream と同じ決め方
  - **最初の TS パケットが届いてから**設定と送信開始を送る(起動直後に電波を出さない)。入力が終わると `tx/mute 1`
  - TS は `tsp -O ip 127.0.0.1:1314` で pluto_stream の UDP 入力へ
  - `-d`(TS レートの計算)は元のソフト版(`/root/pluto_dvb.sw`)が答える
  - ロールオフ(`-r`)は FPGA 側で変えられないので無視
- pluto_stream・pluto_mqtt_ctrl は tezuka の `package/pluto_stream`(F5OEO/pluto-ori-ps `tezukadvb`、GPL-2.0+)。起動は S96plutostream
- デバイスツリーは `board/tezuka/plutoplus_dvb/kernel-dts`(Maia-SDR 用の maiasdr.dtsi を読まない。予約メモリ 128MB も無くなる)

### 作り方

1. FPGA: Linux PC(Vivado 2025.2)で kazushinjo/maia-sdr-plutoplus-dvb をビルドし `tezuka.xsa` を作る
   (詳しい手順はそのリポジトリの `maia-hdl/projects/tezuka/PLUTOPLUS_DVB.md`)
   1. Ubuntu 22.04 / 24.04(x86_64、空き 100GB 前後、メモリ 16GB 以上)に必要なものを入れる

      ```
      sudo apt install -y git make build-essential python3 libtinfo-dev libncurses-dev locales gh
      ```

   2. Vivado 2025.2 を入れる: AMD のダウンロードページから「AMD Unified Installer for FPGAs & Adaptive SoCs 2025.2:
      Linux Self Extracting Web Installer」(AMD のアカウントが必要)。製品 Vivado、エディション **Vivado ML Standard**(無料)、
      デバイスは **Zynq-7000 だけ**、インストール先は既定の `/tools/Xilinx`
   3. リポジトリを取ってくる

      ```
      gh auth login
      gh repo clone kazushinjo/maia-sdr-plutoplus-dvb -- -b plutoplus-dvb
      cd maia-sdr-plutoplus-dvb
      ```

   4. ビルド(1〜2 時間の見込み)

      ```
      VIVADO_SETTINGS=/tools/Xilinx/2025.2/Vivado/settings64.sh \
        maia-hdl/projects/tezuka/build_plutoplus_dvb.sh ~/plutoplus_dvb_out
      ```

   5. `~/plutoplus_dvb_out/` の `tezuka.xsa`・`system_top_utilization_placed.rpt`・`system_top_timing_summary_routed.rpt` を Mac へ持ってくる
      (資源が収まっているか、タイミング(WNS・WHS)が負になっていないかを確認)
2. `tezuka.xsa` を `board/tezuka/plutoplus_dvb/bitstream/` に置いてコミット
3. ファーム: `gh workflow run main.yml --repo kazushinjo/plutoplus_fw-shonan --ref shonan -f boards=plutoplus_shonan_dvb`
   → プレリリース `plutoplus_shonan_dvb-build<番号>`
4. SD カードの作り方は plutoplus_shonan と同じ(zip の `sdimg/` の中身をコピー)

### tezuka.xsa ができた後(Mac)

Linux から持ってきたファイルが `~/Downloads/plutoplus_dvb_out/` にある前提。

1. 中身を確かめる(DVB-S2 エンコーダが入り、Maia-SDR が入っていないこと)

   ```
   cd ~/Downloads/plutoplus_dvb_out
   unzip -l tezuka.xsa | grep -E "system_top.bit|\.hwh"
   unzip -p tezuka.xsa '*.hwh' | grep -c dvbs2_encoder_wrapper     # 1 以上
   unzip -p tezuka.xsa '*.hwh' | grep -c maia_sdr                   # 0
   grep -E "^\| (Slice LUTs|Block RAM Tile|DSPs) " system_top_utilization_placed.rpt
   grep "timing constraints are" system_top_timing_summary_routed.rpt   # All ... are met.
   ```

2. リポジトリに置いてコミット・push(レポートも一緒に残す)

   ```
   cd ~/AppDev/tezuka_fw-shonan
   B=board/tezuka/plutoplus_dvb/bitstream
   cp ~/Downloads/plutoplus_dvb_out/tezuka.xsa $B/
   mkdir -p $B/reports && cp ~/Downloads/plutoplus_dvb_out/*.rpt $B/reports/
   git add $B && git commit -m "plutoplus_dvb: add bitstream built with Vivado 2025.2" && git push origin shonan
   ```

3. ファームをビルドする(GitHub Actions)

   ```
   gh workflow run main.yml --repo kazushinjo/plutoplus_fw-shonan --ref shonan -f boards=plutoplus_shonan_dvb
   gh run list --repo kazushinjo/plutoplus_fw-shonan --workflow main.yml --limit 3
   gh run watch <run の番号> --repo kazushinjo/plutoplus_fw-shonan
   ```

   キャッシュが効くので plutoplus_shonan の初回(2 時間 40 分)より短い見込み。pluto_stream などが増えるので rootfs は少し長くなる。

4. プレリリースから取ってくる

   ```
   gh release list --repo kazushinjo/plutoplus_fw-shonan --limit 5
   gh release download plutoplus_shonan_dvb-build<番号> --repo kazushinjo/plutoplus_fw-shonan --dir ~/Downloads/plutoplus_dvb
   cd ~/Downloads/plutoplus_dvb && unzip plutoplus_shonan_dvb.zip
   ```

5. SD カードへ書き込む: 上の「SD カードの作り方(Mac)」の 2〜5 と同じ(`sdimg/` の中身をコピー、照合、取り出し)。
   **plutoplus_shonan の SD カードは残しておき、別の SD カードを使う**と、元に戻すのが楽

### 実機での確かめ方(FPGA 版)

起動・ネットワーク・SSH は「起動後の確認」と同じ。そのあと Pluto+ に SSH で入って確かめる。

1. 動いているもの

   ```
   cat /opt/VERSIONS
   ps | grep -E "pluto_stream|pluto_mqtt_ctrl|udpts|rtmppluto|lighttpd|mosquitto" | grep -v grep
   ls -l /root/pluto_dvb /root/pluto_dvb.sw     # pluto_dvb はスクリプト、pluto_dvb.sw は元のソフト版
   ```

2. MQTT の様子を見ておく(別の SSH 画面で)

   ```
   mosquitto_sub -h 127.0.0.1 -t 'dt/pluto/#' -t 'cmd/pluto/#' -v
   ```

3. 送信する
   - まず **アッテネーター(40dB など)とダミーロード/受信機をつなぐ**
   - Shonan_Lite から送信する(いつもどおり UDP 8282)。または、ブラウザで `http://<IP>/pluto.php` を開いて設定を保存し、
     Mac から試験映像を送る(Mac に ffmpeg が要る):

     ```
     ffmpeg -re -f lavfi -i testsrc=size=640x360:rate=25 -f lavfi -i sine=frequency=1000 \
       -c:v libx264 -b:v 300k -g 50 -c:a aac -b:a 64k -f mpegts "udp://<IP>:8282?pkt_size=1316"
     ```

   - 2 の画面に `cmd/pluto/<call>/tx/dvbs2/...`・`tx/frequency`・`tx/mute 0`・`tx/stream/run 1` が流れればよい
   - 周波数・出力・LO の状態

     ```
     iio_attr -c ad9361-phy altvoltage1 frequency    # 送信周波数(Hz)
     iio_attr -c ad9361-phy altvoltage1 powerdown    # 0 なら LO オン
     iio_attr -c -o ad9361-phy voltage0 hardwaregain # 送信ゲイン(dB)
     ```

   - 受信側(MiniTiouner、Shonan_Lite の受信など)でロックし、MER・映像・音声を見る。スペクトラムアナライザーがあれば帯域と肩も見る
   - 送るのをやめると、2 の画面に `tx/stream/run 0`・`tx/mute 1` が出る
4. 受信まわり: Shonan_Lite の RSSI 測定、Langstone が今までどおり動くか
5. うまくいかないとき: pluto_stream のメッセージを見る(S96plutostream は出力を捨てているので、手で起動し直す)

   ```
   killall pluto_stream; pluto_stream 2>&1 | tee /tmp/pluto_stream.log &
   ```

### 元に戻す方法

FPGA 版は SD カードにしか入っていない。QSPI(内蔵フラッシュ)には触れていない。

- **SD カードを差し替える**: plutoplus_shonan(build2)の SD カードに戻して電源を入れ直す
- **同じ SD カードを書き戻す**: Mac で build2 の `sdimg/` の中身を上書きコピー(「SD カードの作り方(Mac)」の 4〜5)。
  `overclock/`・`system_top_top.bin`・`tezuka_top.bin` も上書きされる
- **SD カードを抜かずに戻す**(Pluto+ が起動していてネットワークが使えるとき)

  ```
  cd ~/Downloads/plutoplus/sdimg      # build2 を展開した場所
  scp -r * root@<IP>:/boot/
  ssh root@<IP> "sync; reboot"
  ```

- **SD カードから起動しないようにする**: SD-H ジャンパを外すと QSPI の元のファームで起動する

### 現状(2026-10-24)

| 作業 | 状態 |
|---|---|
| HDL の変更・ビルドスクリプト・手順書 | 済み(kazushinjo/maia-sdr-plutoplus-dvb に push)。**Vivado でのビルドはまだ** |
| Linux PC の準備(Vivado 2025.2) | まだ(ユーザーの Linux PC、Ubuntu。操作はユーザー) |
| ファーム側(`configs/plutoplus_shonan_dvb_defconfig`・`boards.json`・`board/tezuka/plutoplus_dvb/`・`shonan/overlay_dvb/`・`post-build.sh`) | 作成済み。`tezuka.xsa` が無いのでビルドはまだ |
| 差し替えスクリプト `pluto_dvb.fpga` | Mac 上で仮のコマンド(mosquitto_pub・tsp など)に置き換えて動作確認済み(DVB-S2・DVB-S・`-i` のファイル入力・入力なし) |
| 実機 | まだ |

### 未確認(FPGA 版)

- 7010 に収まるか・タイミングが合うか(Vivado のビルド前)
- 実機での送信(MER、スペクトラム、周波数・ゲイン・PTT の反映)
- pluto_stream の MQTT 項目の値の書式(ソースから読んだもの。実機では未確認)
- 受信(Shonan の RSSI、Langstone)が Maia-SDR なし・1R1T の FPGA で今までどおり動くか

## ライセンス

詳しくは [LICENSE.md](LICENSE.md)。

- tezuka_fw とこのリポジトリで足した設定・スクリプト・文書: GPL-3.0(リポジトリ直下の [LICENSE](../../../LICENSE))
- ファームに入る各 OSS パッケージ: それぞれのライセンス。ライセンス文と SBOM はプレリリースの `plutoplus_shonan-licenses.zip`
- TSDuck: BSD-2-Clause、jQuery・Chart.js・Socket.IO など Web 画面のライブラリ: MIT
- datvplutofrm から持ってきた DATV の部品(udpts.sh・PHP ページ・pluto_dvb など): 元の F5OEO/datvplutofrm に
  ライセンスの明記が無い。**公開・配布する前に作者(F5OEO)の許可かライセンスの確認が必要**
