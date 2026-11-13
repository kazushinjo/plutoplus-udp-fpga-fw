# plutoplus_dvb ビルドの記録

**日本語** | [English](#english)

手順書 [PLUTOPLUS_DVB.md](PLUTOPLUS_DVB.md) に沿って、初めて `plutoplus_dvb.xsa` を作ったときの記録。
手順書どおりに進まなかった点と、その対処を残す。

## 2026-11-08〜09: 初回ビルド

### 環境

| 項目 | 内容 |
|---|---|
| OS | Ubuntu 25.10(手順書の対象 22.04 / 24.04 の外) |
| CPU・メモリ | 4 コア、9.1GB(目安の 16GB より少ない) |
| スワップ | 4GB + 追加 12GB(`/swap2.img`)= 16GB |
| Vivado | 2025.2.1 ML Standard(手順書は 2025.2)。`/tools/Xilinx/2025.2.1/` |
| インストールした部品 | Zynq-7000、DocNav、Vitis Model Composer(最後の 1 つは本来不要) |
| HDL | ブランチ `main`(当時の名前は `plutoplus-dvb`)の `bf8b7c0` |
| サブモジュール | `adi-hdl` `cf81ab15`、`dvb_fpga` `297a5b7` + `hdl/patches/dvb_fpga` の修正 2 つ |

`/swap2.img` は `/etc/fstab` に入れていないので、再起動すると無効になる。

### 経過(時刻は JST)

| 時刻 | 出来事 |
|---|---|
| 11-08 19:23 | Vivado のバッチインストール開始(ダウンロードは全体で 18GB) |
| 11-08 23:12 | インストーラーの後処理 `xlpartinfo.tcl` で停止。CPU をほとんど使わないまま 3 時間以上動かず |
| 11-09 02:33 頃 | 停止した Vivado を `sudo kill`。次の後処理 `xmcGenBoardParts.tcl` でも同じ症状 |
| 11-09 02:36 | 原因を `libncurses.so.5` の不足と特定し、リンクを作成。再度 `sudo kill` |
| 11-09 02:37 | インストール完了(`/tools/Xilinx` は 57GB) |
| 11-09 02:38 | `build_plutoplus_dvb.sh` でビルド開始 |
| 11-09 03:29 | 合成・配置配線・ビットストリーム生成・`.xsa` 出力が完了 |
| 11-09 03:30 | 最後の `make install` で失敗(下記)。`.xsa` は無事で、手動でコピー |
| 11-09 05:04 頃 | `.xsa` を `plutoplus-udp-fpga_fw` の作業ブランチへ push(`47b6b55`、当時は `b5f024c`)。GitHub Actions で `plutoplus_udp_fpga` のビルドを開始(run 42518291674) |
| 11-09 05:18 頃 | ブランチ `plutoplus-dvb` を `main` に改名し、既定のブランチも `main` に変更 |
| 11-09 06:16 | `plutoplus_udp_fpga` の Actions ビルド(run 42518291674)が約 71 分で失敗。U-Boot・カーネル・rootfs は成功し、最後の Assemble image で停止(下記) |
| 11-09 07:51 | `package/pluto_stream/Config.in` を修正し(`e36fc49`、当時は `ea42271`)、Actions で再ビルド開始(run 42532282903) |
| 11-09 10:03 | 再ビルドが成功(約 2 時間 12 分)。プレリリース `plutoplus_udp_fpga-build10` を公開 |
| 11-09 10:07 頃 | ファーム側の履歴から共同作者の行を削除して force push。謝辞と FPGA リポジトリの `LICENSE` を追加 |

ビルド時間は約 52 分。この環境でメモリ不足は起きなかった。

### 結果

`plutoplus_dvb.xsa` の SHA-256: `40aebe151c2e73012922afec2b5b939bea0924dc325d6485ca2f7492860883d5`

`.xsa` の hwh には `dvbs2_encoder_wrapper` が 47 件あり、`maia_sdr` は 0 件。

| 資源 | 使用 | 上限 | 使用率 | 見積もり |
|---|---|---|---|---|
| Slice LUTs | 11,947 | 17,600 | 67.88% | 約 80% |
| Slice Registers | 17,730 | 35,200 | 50.37% | — |
| Block RAM Tile | 25.5 | 60 | 42.50% | 約 27 個 |
| DSPs | 70 | 80 | 87.50% | 約 88% |

| タイミング | WNS | WHS | 判定 |
|---|---|---|---|
| 最終(`postroute_physopted`) | +0.249 ns | +0.010 ns | All user specified timing constraints are met. |
| 参考: 再配線前(`routed`) | +0.164 ns | −0.081 ns | Timing constraints are not met. |

### ファームのビルド結果

| 項目 | 内容 |
|---|---|
| Actions | run 42532282903(`e36fc49`、当時は `ea42271`)。成功、約 2 時間 12 分 |
| 工程の時間 | U-Boot 約 32 分、カーネル 約 44 分、rootfs 約 48 分、Assemble image 約 1 分半 |
| プレリリース | `plutoplus_udp_fpga-build10`(タグは書き換え前の `ea42271` を指す。中身は同じ) |
| `plutoplus-udp-fpga-firm.zip` | 28,985,974 バイト、SHA-256 `30bc35e3c500eb425384a5abb3459192e350432fbd42b9688adf378c2c476685` |
| `sdimg/BOOT.bin` | md5 `a6ce0ad427d714ca554f8fe555d81b76`(tezuka 0.2.4 のものと一致) |
| `sdimg/system_top.bin` | `plutoplus_dvb.xsa` の `.bit` と同期ワード以降の 1,024,424 バイトが一致(`.bin` はバイト順が入れ替わり、末尾に 8 バイト多い) |

### 問題と対処

#### 1. インストーラーが後処理で止まる(Ubuntu 25.10)

バッチモードの Vivado が次のエラーで Tcl の初期化に失敗し、インストーラーの後処理が終わらなくなっていた。
`vivado -version` はこのエラーの影響を受けないので、それだけでは気づけない。

```
couldn't load file "libxv_commontasks.so": libncurses.so.5: cannot open shared object file
```

対処: `libtinfo.so.5` と同じようにリンクを作る。手順書に追記済み。

```
sudo ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
```

止まっていた後処理はいずれも Model Composer 用で、`plutoplus_dvb` のビルドには使わない。

#### 2. `make install` が失敗する

`make install DEST=...` とコマンドライン引数で渡すと、ADI の `project-xilinx.mk` がその変数を `PROJECT_NAME` に混ぜ込み、
`.xsa` のパスが壊れて `cp` が失敗していた。

対処: `DEST` を環境変数で渡すように `build_plutoplus_dvb.sh` を修正(`6ee7818`)。

#### 3. 手順書のタイミングレポートでは違反に見える

`system_top_timing_summary_routed.rpt` は `hold_fix.tcl` の再配線より前に書かれるので、`rx_clk` のホールド違反(6 箇所、WHS −0.081 ns)が出る。
ビットストリームはその後の状態から作られていて、最終レポートでは違反が消えている。

対処: 判定には `system_top_timing_summary_postroute_physopted.rpt` を使う。スクリプトと手順書を修正(`6ee7818`)。

#### 4. 警告で確認したもの

`[Vivado 12-1411] Cannot set LOC property of ports` が 16 件出る。すべて `fixed_io_mio` の PS 側 MIO ピンで、チップ内で配線が固定されているため影響なしと判断した。

#### 5. ファームのリポジトリへの push

- `gh auth login` だけでは git の push に認証情報が渡らない。`gh auth setup-git` を実行するか、`git -c credential.helper='!gh auth git-credential' push` を使う
- GitHub のメールアドレス保護で、個人のアドレスを作者にしたコミットは拒否される(`push declined due to email privacy restrictions`)。`4509400+kazushinjo@users.noreply.github.com` を使う
- push の失敗に気づかず Actions を起動した run 42518200488(`954f82b`、`.xsa` なし)は取り消した

#### 6. dvb_fpga の README と QPSK

`hdl/dvb_fpga/README.md` の対応変調の一覧は「8 PSK, 16 APSK and 32 APSK」で QPSK が書かれていないが、QPSK も実装されている(記載漏れと判断)。

- 回路: `rtl/dvbs2_encoder.vhd`・`rtl/axi_constellation_mapper.vhd` に QPSK の処理がある(MODCOD 1〜11)
- 試験: `run.py` に QPSK の全符号化率の定義があり、`dvbs2_encoder_tb`・`axi_constellation_mapper_tb` が QPSK を扱っている(今回シミュレーションは実行していない)

`dvb_fpga` は上流(OpenResearchInstitute)への push 権限がなく、README だけのためのパッチも足していない。

#### 7. ファームのビルドが Assemble image で失敗する(解決)

run 42518291674(`47b6b55`、当時は `b5f024c`)は次のエラーで止まった。`plutoplus_dvb.xsa` の展開は成功していて、FPGA の問題ではない。

```
Makefile:593: *** ne10 is in the dependency chain of pluto_stream that has added it to its _DEPENDENCIES variable without selecting it or depending on it from Config.in.  Stop.
```

- `package/pluto_stream/pluto-stream.mk` の `PLUTO_STREAM_DEPENDENCIES` に `ne10` があるが、`package/pluto_stream/Config.in` は `ne10` を選択していない
- defconfig に `BR2_PACKAGE_NE10=y` はあるが、エラーの内容からは設定に残っていない。同じ `ne10` を使う `package/DATV/Config.in` は `BR2_PACKAGE_NE10_ARCH_SUPPORTS` と `BR2_PACKAGE_NE10` の両方を `select` している
- Build rootfs(`target-finalize`)では `ne10`・`pluto_stream` を含めてビルドが通っていて、最後の `make` で依存チェックに掛かった

修正(`e36fc49`、当時は `ea42271`): `package/pluto_stream/Config.in` に次の 2 行を足した。再ビルドは Assemble image を通過して成功した。

```
	select BR2_PACKAGE_NE10_ARCH_SUPPORTS
	select BR2_PACKAGE_NE10
```

### 検討だけしたこと: 2R2T にできるか(未実施)

可能性の確認のみで、設定の変更も試しのビルドもしていない。下の影響は机上の見立てで、実測ではない。

結論: 可能性はあるが、資源に収まるかはビルドしないと分からない。2R2T にしても DVB-S2 を 2 系統同時に送信することはできない。

- 基板は対応している(本家の `plutoplus` は 2R2T)
- 変更箇所は主に `system_bd.tcl` の `mode1r1t` を外すことと、デバイスツリーの設定
- 現在の余裕は DSP 10 個(70 / 80)、LUT 5,653(11,947 / 17,600)。2 系統目の補正回路で DSP が増える
- TX FIR ×8 は 1 系統分。2 系統目にも通すなら FIR も 2 倍近く必要で、DSP が足りない可能性が高い
- DVB-S2 のエンコーダと RRC は 1 ストリーム分。2 系統同時に送るにはエンコーダがもう 1 つ必要で、7010 には入らない
- AD9361 の上限は、2R2T だと 1 チャンネルあたり 30.72 MS/s(1R1T は 61.44 MS/s)
- 資源の使用率が上がるので、タイミングは今より厳しくなる

現実的なのは、受信だけ 2 系統にして(2R)、送信は DVB-S2 の 1 系統のままにする形。確かめるには設定を変えて試しにビルドする(今回の環境で 1 回 1 時間弱)。

### 補足: 確認・検討した内容

#### 文書の日英併記

このプロジェクトで書いた日本語の文書 9 ファイルに英語版を追加した。
日本語の本文は残し、先頭に `日本語 | English` のリンクを置いて後ろに英語版を続けた(直下の `README.md` は該当箇所のすぐ後に英語を入れた)。
もとの tezuka や ADI の英語文書と、コード・スクリプトのコメントは対象外。`LICENSE.md` の英語は参考訳。

#### SD カードの容量

手順書の条件は 32GB 以下・MBR・FAT32 で、起動を確認しているのも 32GB のカードだけ。64GB のカードは試していないので推奨しない。

- 64GB のカードは SDXC で、32GB までの SDHC とは規格が違う。Zynq の起動処理が SDXC に対応していない可能性がある(資料では未確認の見立て)
- 64GB のカードは通常 exFAT で売られている。FAT32 にしてもカードの規格は SDXC のまま
- 起動しなかったときに原因を切り分けにくくなるので、最初の確認は 32GB 以下のカードで行う

#### ビルドする場所

ファームのビルド(Buildroot)は x86_64 Linux が前提で、FPGA のビルド(Vivado)も x86_64 Linux 専用。Mac では直接ビルドできない。
Intel Mac の Linux 仮想マシンは可能性があるが未検証。Apple Silicon では x86_64 のエミュレーションになり現実的でない。
Mac で必要なのは、できた zip を SD カードに書き込む作業だけ。

#### FPGA 版と従来版の違い

| 項目 | 従来(ソフト変調版) | FPGA 版(`plutoplus_udp_fpga`) |
|---|---|---|
| DATV の変調 | Pluto+ の ARM のソフト(`pluto_dvb`) | Pluto+ の FPGA(`pluto_stream` が操作) |
| AD9361 | 2R2T | 1R1T |
| Maia-SDR(ウォーターフォール、IQ 録音、IQEngine) | あり | なし |
| tezuka ダッシュボード | `maia-httpd` 経由 | `lighttpd` で配信。MQTT の操作は可、スペクトル表示などは不可 |
| UDP 8282、iiod、SSH | 使える | 同じ URL・ポートで使える |
| 予約メモリ | Maia-SDR 用に 128MB | なし |
| ロールオフ | `-r` で指定 | 0.35 固定(`-r` は無視) |

FPGA に移る処理は、DVB-S2 エンコード(BCH・LDPC、インターリーブ、マッピング、フレーム化)、RRC ×2 補間、TX FIR ×8 補間。
対応は QPSK・8PSK・16APSK・32APSK、符号化率 1/4〜9/10、ノーマル・ショートフレーム。
期待できる効果は、ARM の負荷の低下と、より高いシンボルレートや計算量の多い方式への余裕。**いずれも設計上の見込みで、実測はまだない。**

#### Raspberry Pi 5 の負荷

FPGA 版にしても、Pi 5 の負荷はほとんど変わらない見込み(Raspberry Pi 5 版の送信アプリのソースで処理の分担を確認。負荷は未測定)。

| 処理 | 従来 | FPGA 版 |
|---|---|---|
| 映像のエンコードと TS の作成(ffmpeg) | Pi 5 | Pi 5 |
| DVB-S2 の受信・復調(GNU Radio / gr-dvbs2rx) | Pi 5 | Pi 5 |
| 画面表示(GUI) | Pi 5 | Pi 5 |
| DVB-S2 の変調 | Pluto+ の ARM | Pluto+ の FPGA |

軽くなるのは Pluto+ の ARM の負荷。Pi 5 の負荷を下げるなら、映像のエンコードや受信の復調処理の見直しが効く。

### 未確認のこと

- ファーム(`plutoplus_udp_fpga-build10`)の確認は、zip の中身の照合まで
- SD カードの作成と、Pluto+ 実機での起動・DVB-S2 送信の確認はまだ

---

# English

## plutoplus_dvb build history

A record of the first build of `plutoplus_dvb.xsa` following [PLUTOPLUS_DVB.md](PLUTOPLUS_DVB.md).
It keeps the places where the guide did not work as written, and what was done about them.

### 2026-11-08 to 09: first build

#### Environment

| Item | Details |
|---|---|
| OS | Ubuntu 25.10 (outside the guide's target of 22.04 / 24.04) |
| CPU, memory | 4 cores, 9.1 GB (below the recommended 16 GB) |
| Swap | 4 GB + an added 12 GB (`/swap2.img`) = 16 GB |
| Vivado | 2025.2.1 ML Standard (the guide says 2025.2). `/tools/Xilinx/2025.2.1/` |
| Installed components | Zynq-7000, DocNav, Vitis Model Composer (the last one is not actually needed) |
| HDL | `bf8b7c0` on the branch `main` (then named `plutoplus-dvb`) |
| Submodules | `adi-hdl` `cf81ab15`, `dvb_fpga` `297a5b7` + the two patches in `hdl/patches/dvb_fpga` |

`/swap2.img` is not in `/etc/fstab`, so it is disabled after a reboot.

#### Timeline (JST)

| Time | Event |
|---|---|
| 11-08 19:23 | Started the Vivado batch installation (18 GB download in total) |
| 11-08 23:12 | The installer stopped in the post-install step `xlpartinfo.tcl`, with almost no CPU use for over 3 hours |
| 11-09 around 02:33 | Stopped the hung Vivado with `sudo kill`. The next post-install step `xmcGenBoardParts.tcl` showed the same symptom |
| 11-09 02:36 | Identified the cause as the missing `libncurses.so.5` and created the link. Ran `sudo kill` again |
| 11-09 02:37 | Installation finished (`/tools/Xilinx` is 57 GB) |
| 11-09 02:38 | Started the build with `build_plutoplus_dvb.sh` |
| 11-09 03:29 | Synthesis, place and route, bitstream generation and `.xsa` export finished |
| 11-09 03:30 | The final `make install` failed (see below). The `.xsa` was intact and was copied by hand |
| 11-09 around 05:04 | Pushed the `.xsa` to the working branch of `plutoplus-udp-fpga_fw` (`47b6b55`, then `b5f024c`). Started the `plutoplus_udp_fpga` build on GitHub Actions (run 42518291674) |
| 11-09 around 05:18 | Renamed the branch `plutoplus-dvb` to `main` and made `main` the default branch |
| 11-09 06:16 | The `plutoplus_udp_fpga` Actions build (run 42518291674) failed after about 71 minutes. U-Boot, kernel and rootfs succeeded; it stopped in the final Assemble image step (see below) |
| 11-09 07:51 | Fixed `package/pluto_stream/Config.in` (`e36fc49`, then `ea42271`) and started a new Actions build (run 42532282903) |
| 11-09 10:03 | The new build succeeded (about 2 h 12 min). Published the prerelease `plutoplus_udp_fpga-build10` |
| 11-09 around 10:07 | Removed the co-author lines from the firmware history and force-pushed. Added acknowledgements and the FPGA repository `LICENSE` |

The build took about 52 minutes. Memory did not run out in this environment.

#### Results

SHA-256 of `plutoplus_dvb.xsa`: `40aebe151c2e73012922afec2b5b939bea0924dc325d6485ca2f7492860883d5`

The hwh in the `.xsa` has 47 occurrences of `dvbs2_encoder_wrapper` and 0 of `maia_sdr`.

| Resource | Used | Available | Utilization | Estimate |
|---|---|---|---|---|
| Slice LUTs | 11,947 | 17,600 | 67.88% | about 80% |
| Slice Registers | 17,730 | 35,200 | 50.37% | — |
| Block RAM Tile | 25.5 | 60 | 42.50% | about 27 |
| DSPs | 70 | 80 | 87.50% | about 88% |

| Timing | WNS | WHS | Result |
|---|---|---|---|
| Final (`postroute_physopted`) | +0.249 ns | +0.010 ns | All user specified timing constraints are met. |
| Reference: before reroute (`routed`) | +0.164 ns | −0.081 ns | Timing constraints are not met. |

#### Firmware build result

| Item | Details |
|---|---|
| Actions | Run 42532282903 (`e36fc49`, then `ea42271`). Succeeded in about 2 h 12 min |
| Step times | U-Boot about 32 min, kernel about 44 min, rootfs about 48 min, Assemble image about 1.5 min |
| Prerelease | `plutoplus_udp_fpga-build10` (the tag points to `ea42271` from before the rewrite; the contents are the same) |
| `plutoplus-udp-fpga-firm.zip` | 28,985,974 bytes, SHA-256 `30bc35e3c500eb425384a5abb3459192e350432fbd42b9688adf378c2c476685` |
| `sdimg/BOOT.bin` | md5 `a6ce0ad427d714ca554f8fe555d81b76` (matches the one from tezuka 0.2.4) |
| `sdimg/system_top.bin` | Matches the `.bit` in `plutoplus_dvb.xsa` over the 1,024,424 bytes from the sync word (the `.bin` is byte-swapped and has 8 more bytes at the end) |

#### Problems and fixes

##### 1. The installer hangs in post-install steps (Ubuntu 25.10)

Batch-mode Vivado failed Tcl initialization with the error below, so the installer's post-install steps never finished.
`vivado -version` is not affected by this error, so it alone does not reveal the problem.

```
couldn't load file "libxv_commontasks.so": libncurses.so.5: cannot open shared object file
```

Fix: create a link, as for `libtinfo.so.5`. Added to the guide.

```
sudo ln -s /lib/x86_64-linux-gnu/libncurses.so.6 /lib/x86_64-linux-gnu/libncurses.so.5
```

The steps that hung are all for Model Composer and are not used to build `plutoplus_dvb`.

##### 2. `make install` fails

With `make install DEST=...` on the command line, ADI's `project-xilinx.mk` folded the variable into `PROJECT_NAME`,
which corrupted the `.xsa` path and made `cp` fail.

Fix: `build_plutoplus_dvb.sh` now passes `DEST` through the environment (`6ee7818`).

##### 3. The timing report named in the guide shows a violation

`system_top_timing_summary_routed.rpt` is written before the `hold_fix.tcl` reroute, so it shows a hold violation on `rx_clk` (6 endpoints, WHS −0.081 ns).
The bitstream comes from the later state, and the violation is gone in the final report.

Fix: use `system_top_timing_summary_postroute_physopted.rpt` to judge timing. Script and guide updated (`6ee7818`).

##### 4. Warnings that were reviewed

There are 16 `[Vivado 12-1411] Cannot set LOC property of ports` warnings. All are PS-side MIO pins in `fixed_io_mio`, which are wired inside the chip, so they were judged to have no effect.

##### 5. Pushing to the firmware repository

- `gh auth login` alone does not give git credentials for push. Run `gh auth setup-git`, or use `git -c credential.helper='!gh auth git-credential' push`
- GitHub's email privacy protection rejects commits authored with a personal address (`push declined due to email privacy restrictions`). Use `4509400+kazushinjo@users.noreply.github.com`
- Run 42518200488 (`954f82b`, no `.xsa`), started without noticing that the push had failed, was cancelled

##### 6. The dvb_fpga README and QPSK

The list of constellations in `hdl/dvb_fpga/README.md` says "8 PSK, 16 APSK and 32 APSK" and omits QPSK, but QPSK is implemented (judged to be an omission).

- RTL: `rtl/dvbs2_encoder.vhd` and `rtl/axi_constellation_mapper.vhd` handle QPSK (MODCOD 1 to 11)
- Tests: `run.py` defines all QPSK code rates, and `dvbs2_encoder_tb` and `axi_constellation_mapper_tb` cover QPSK (the simulations were not run this time)

There is no push access to upstream `dvb_fpga` (OpenResearchInstitute), and no patch was added just for the README.

##### 7. The firmware build fails in Assemble image (resolved)

Run 42518291674 (`47b6b55`, then `b5f024c`) stopped with the error below. Extracting `plutoplus_dvb.xsa` succeeded, so this is not an FPGA problem.

```
Makefile:593: *** ne10 is in the dependency chain of pluto_stream that has added it to its _DEPENDENCIES variable without selecting it or depending on it from Config.in.  Stop.
```

- `PLUTO_STREAM_DEPENDENCIES` in `package/pluto_stream/pluto-stream.mk` lists `ne10`, but `package/pluto_stream/Config.in` does not select it
- The defconfig has `BR2_PACKAGE_NE10=y`, but judging from the error it does not stay in the configuration. `package/DATV/Config.in`, which also uses `ne10`, selects both `BR2_PACKAGE_NE10_ARCH_SUPPORTS` and `BR2_PACKAGE_NE10`
- Build rootfs (`target-finalize`) built everything including `ne10` and `pluto_stream`; the dependency check failed in the final `make`

Fix (`e36fc49`, then `ea42271`): added these two lines to `package/pluto_stream/Config.in`. The rebuild passed Assemble image and succeeded.

```
	select BR2_PACKAGE_NE10_ARCH_SUPPORTS
	select BR2_PACKAGE_NE10
```

#### Studied only: is 2R2T possible? (not done)

A feasibility check only. No settings were changed and no trial build was run. The effects below are a desk estimate, not measurements.

Conclusion: it may be possible, but whether it fits can only be known by building. Even with 2R2T, two simultaneous DVB-S2 transmissions are not possible.

- The board supports it (the original `plutoplus` is 2R2T)
- The main changes are removing `mode1r1t` in `system_bd.tcl` and the device tree settings
- The current margin is 10 DSPs (70 / 80) and 5,653 LUTs (11,947 / 17,600). The correction logic for a second channel adds DSPs
- TX FIR x8 is for one channel. Feeding a second channel through it needs nearly twice the FIR, and DSPs are likely to run out
- The DVB-S2 encoder and RRC handle one stream. Two simultaneous streams need a second encoder, which does not fit in the 7010
- The AD9361 limit in 2R2T is 30.72 MS/s per channel (61.44 MS/s in 1R1T)
- Higher utilization makes timing tighter than it is now

The realistic form is two receive channels (2R) with a single DVB-S2 transmit channel. To confirm, change the settings and run a trial build (just under an hour per build in this environment).

#### Supplementary notes: items checked and studied

##### Bilingual documents

English versions were added to the 9 Japanese documents written for this project.
The Japanese text is kept, with a `日本語 | English` link at the top and the English version after it (in the root `README.md`, the English follows each Japanese passage).
Upstream tezuka and ADI English documents and comments in code and scripts are out of scope. The English in `LICENSE.md` is a translation for convenience.

##### SD card capacity

The guide requires 32 GB or smaller, MBR and FAT32, and only a 32 GB card has been confirmed to boot. A 64 GB card has not been tried and is not recommended.

- A 64 GB card is SDXC, a different standard from the SDHC used up to 32 GB. The Zynq boot process may not support SDXC (an estimate not confirmed from documentation)
- 64 GB cards are normally sold formatted as exFAT. Reformatting to FAT32 leaves the card itself SDXC
- It makes a boot failure harder to isolate, so do the first check with a card of 32 GB or smaller

##### Where it can be built

The firmware build (Buildroot) needs x86_64 Linux, and the FPGA build (Vivado) is x86_64 Linux only. Neither can be built directly on a Mac.
A Linux virtual machine on an Intel Mac may work but is untested. On Apple Silicon it would need x86_64 emulation and is not practical.
The only step needed on the Mac is writing the finished zip to the SD card.

##### Differences between the FPGA version and the normal version

| Item | Normal (software modulation) | FPGA version (`plutoplus_udp_fpga`) |
|---|---|---|
| DATV modulation | Software on the Pluto+ ARM (`pluto_dvb`) | Pluto+ FPGA (controlled by `pluto_stream`) |
| AD9361 | 2R2T | 1R1T |
| Maia-SDR (waterfall, IQ recording, IQEngine) | Yes | No |
| tezuka dashboard | Through `maia-httpd` | Served by `lighttpd`. MQTT controls work; the spectrum display and so on do not |
| UDP 8282, iiod, SSH | Available | Available (same URLs and ports) |
| Reserved memory | 128 MB for Maia-SDR | None |
| Roll-off | Set with `-r` | Fixed at 0.35 (`-r` is ignored) |

The processing moved to the FPGA is DVB-S2 encoding (BCH, LDPC, interleaving, mapping, framing), RRC x2 interpolation and TX FIR x8 interpolation.
It supports QPSK, 8PSK, 16APSK and 32APSK, code rates 1/4 to 9/10, and normal and short frames.
The expected benefits are lower ARM load and headroom for higher symbol rates and more demanding modes. **These are design expectations and have not been measured.**

##### Raspberry Pi 5 load

The Pi 5 load is expected to stay almost the same with the FPGA version (the division of work was confirmed from the source of the Raspberry Pi 5 sender app; the load has not been measured).

| Processing | Normal | FPGA version |
|---|---|---|
| Video encoding and TS creation (ffmpeg) | Pi 5 | Pi 5 |
| DVB-S2 reception and demodulation (GNU Radio / gr-dvbs2rx) | Pi 5 | Pi 5 |
| Display (GUI) | Pi 5 | Pi 5 |
| DVB-S2 modulation | Pluto+ ARM | Pluto+ FPGA |

The load that drops is on the Pluto+ ARM. To reduce the Pi 5 load, look at video encoding and the receive demodulation instead.

#### Not yet confirmed

- The firmware (`plutoplus_udp_fpga-build10`) has only been checked by inspecting the zip contents
- The SD card and the boot and DVB-S2 transmit checks on the Pluto+ are still to be done
