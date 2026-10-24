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
12. [ビルド履歴](#ビルド履歴)
13. [未確認](#未確認)
14. [ライセンス](#ライセンス)

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
   | `BOOT.bin` | FSBL + U-Boot |
   | `system_top.bin` | FPGA ビットストリーム(U-Boot が読み込む。`tezuka_top.bin` は同じもの、`system_top_top.bin` は別の候補) |
   | `uImage` | Linux カーネル |
   | `uramdisk.image.xz` | rootfs(起動時に RAM へ展開) |
   | `devicetree.dtb` | Pluto+ のデバイスツリー(model「Pluto+ (Z7010/AD9363)」) |
   | `uEnv.txt` | U-Boot の設定 |
   | `overclock/` | CPU・DDR のクロックを変えた BOOT.bin(使うときは `BOOT.bin` と差し替え) |

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
   | SD-H | **1V8** に接続(版によっては 3V3) | SD カードから起動する |
   | URST | **MIO46** に接続 | 内蔵 LAN(ギガビット)を使う。MIO52 は ADI 公式ファーム用 |
   | EXCLK | 外部基準クロックを使うときだけ GND | 普段は外す |

3. SD カードを挿し、電源を入れる(5V 2A 以上、micro USB)
4. 起動中は LED が点滅する。青 LED が消えて緑が点きっぱなしなら起動失敗(SD カードの中身・ジャンパを見直す)

## 起動後の確認

| 確認 | 方法 | 期待する結果 |
|---|---|---|
| ネットワーク | LAN(DHCP)または USB(Pluto 側 192.168.2.1、PC 側 192.168.2.10) | ping が返る。LAN の IP はルーターで確認。mDNS では `pluto.local` |
| DATV の Web 画面 | `http://<IP>/pluto.php` | Controller 画面が出る |
| tezuka のダッシュボード | `http://<IP>/` | maia-sdr / Tezuka Dashboard が出る(lighttpd 経由) |
| SSH | `ssh root@<IP>`(パスワード analog) | ログイン表示に `v…-shonan` の行(build2 は `v6822-shonan`) |
| iio | `iio_info -u ip:<IP>` | ad9361-phy などが見える |
| 版 | `cat /opt/VERSIONS` | `device-fw tezuka-…`、`buildroot 2026.05.2` |

LAN の固定 IP は tezuka の仕組み(USB ドライブの `config.txt` の `[USB_ETHERNET] ipaddr_eth` / `fw_setenv ipaddr_eth`)で設定する。

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
- tezuka 本家の更新を取り込むとき: `git fetch upstream && git merge upstream/main`(shonan ブランチで)

## ビルド履歴

| 版 | コミット | 日付 | 結果 |
|---|---|---|---|
| plutoplus_shonan-build2 | 6822(shonan) | 2026-10-24 | ビルド成功(2h39m、zip 33.5MB、uramdisk 26MB)。rootfs の中身を確認、SD カード(32GB)へ書き込み済み。実機起動は未確認 |

## 未確認

- 実機での起動・送信・各 PHP ページ
- lighttpd 経由での tezuka ダッシュボード(WebSocket を含む)
- maia-sdr の受信と pluto_dvb の送信を同時に使ったときの動き
- Pluto+ の PTT(GPIO0/MIO0)と、requests.php の PTT ボタン(AD9361 の GPO を操作する)の対応
- Shonan_Lite 各版・Portsdown 4 からの接続

## ライセンス

詳しくは [LICENSE.md](LICENSE.md)。

- tezuka_fw とこのリポジトリで足した設定・スクリプト・文書: GPL-3.0(リポジトリ直下の [LICENSE](../../../LICENSE))
- ファームに入る各 OSS パッケージ: それぞれのライセンス。ライセンス文と SBOM はプレリリースの `plutoplus_shonan-licenses.zip`
- TSDuck: BSD-2-Clause、jQuery・Chart.js・Socket.IO など Web 画面のライブラリ: MIT
- datvplutofrm から持ってきた DATV の部品(udpts.sh・PHP ページ・pluto_dvb など): 元の F5OEO/datvplutofrm に
  ライセンスの明記が無い。**公開・配布する前に作者(F5OEO)の許可かライセンスの確認が必要**
