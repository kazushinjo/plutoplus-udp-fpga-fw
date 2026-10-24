# Pluto+ Shonan_Lite 版(plutoplus_shonan)

tezuka の Pluto+ 用ファーム(`configs/plutoplus_maiasdr_defconfig`)に、
Shonan_Lite と Portsdown 4 が使う DATV 送信の部品(kazushinjo/datvplutofrm の v0.39-shonan ブランチ)を足したもの。
tezuka の機能(maia-sdr、IQEngine、ダッシュボード、MQTT など)はすべて残している。

イメージが QSPI のファーム領域(0x1E00000)に入らないため、**SD カード起動専用**。
`pluto.frm` / `pluto.dfu` は作らない。

## ビルド

```
./getbuildroot.sh
./build.sh plutoplus_shonan
```

できたものは `build/plutoplus_shonan.zip`(中の `sdimg/` が SD カード用)。

## SD カードの作り方

1. SD カード(32GB 以下)を FAT32 でフォーマットする
2. zip の `sdimg/` の**中身**を SD カードの一番上にコピーする(フォルダごとではない)
3. Pluto+ の基板で SD-H を 1V8(版によっては 3V3)につなぐ。内蔵 LAN を使うので URST は MIO46 側
4. SD カードを差して電源を入れる

## 足したもの

| 部品 | 内容 |
|---|---|
| `overlay/root/pluto_dvb`, `udpts.sh`, `rtmppluto.sh` ほか | UDP 8282 → tsp → pluto_dvb、rtmp 7272 → ffmpeg → tsp → pluto_dvb(datvplutofrm と同じもの。pluto_dvb と tsp はビルド済みの実行ファイル) |
| `overlay/usr/bin/tsp`, `overlay/usr/lib/ts*` | TSDuck(プラグインは ip・file・sdt・analyze・pcrextract の 5 個) |
| `overlay/www/` | save.php・pluto.php など DATV の Web 画面 |
| `overlay/etc/lighttpd/lighttpd.conf` | ポート 80。DATV の PHP ページだけ自分で返し、それ以外は maia-httpd(127.0.0.1:8000)へ中継する(WebSocket も) |
| `overlay/etc/init.d/S90datv` | 起動時に udpts.sh・rtmppluto.sh・watchudp.sh を起動 |
| `overlay/etc/init.d/S89patchfirm`, `overlay/usr/sbin/device_persistent_keys` | SSH のホスト鍵(ecdsa・ed25519・rsa)を起動時に作って保存する。電源断の後も鍵が変わらない |
| `post-build.sh` | maia-httpd を 8000 番へ移す、USB ネットワークの既定を NCM にする(u-boot env の usb_ethernet_mode で変更可)、fwversion.txt 作成 |
| defconfig | lighttpd(pcre)、PHP(cgi・cli・session・sockets)、bc、ffmpeg(datvplutofrm v0.39-shonan と同じ最小構成)。ホスト名は Langstone の既定に合わせて `pluto` |

## Portsdown 4 から使う機能

BritishAmateurTelevisionClub/portsdown4(0b886da、2026-10-18)のソースで確認したもの。

| Portsdown 4 が使うもの | この版での扱い |
|---|---|
| `rtmp://<pluto>:7272/,周波数,…,/コール,`(DVB-S/S2 送信) | rtmppluto.sh → ffmpeg → tsp → pluto_dvb。ffmpeg 6.1.5 にも rtmppluto.sh が読む「App field don't match up」「Unexpected stream」の表示がある |
| DVB-T 送信・バンドビューアなど(Pi から libiio で IQ をやりとり) | tezuka の iiod |
| SSH(root/analog)の reboot・`cat /proc/cpuinfo` | tezuka のまま |
| `fw_setenv attr_name compatible` / `attr_val ad9364`、`maxcpus`、`xo_correction` | tezuka の u-boot(adi_config_devicetree)と S21misc が同じ変数を読む |
| 版の表示(`ssh root@<pluto>` の出力から `^v` の行を拾う) | tezuka のログイン表示には無いので、post-build.sh で `v…-shonan` の行を足した |

## datvplutofrm から持ってこなかったもの

- S94pluto-mods(70〜6000MHz 化・2 コア化): tezuka の Pluto+ はデバイスツリーが最初から `adi,ad9361`、`maxcpus=2` なので不要
- S45msd の修正: tezuka の S45msd は `/www` を USB ドライブへコピーしないので不要
- busybox httpd の設定、readsettings.sh(OpenWebRX 用)、motd、wpa_supplicant: tezuka 側のものを使う

## 未確認

- 実機での起動・送信・各 PHP ページ
- maia-sdr の受信と pluto_dvb の送信を同時に使ったときの動き
- Pluto+ の PTT(GPIO0/MIO0)と、requests.php の PTT ボタン(AD9361 の GPO を操作する)の対応
