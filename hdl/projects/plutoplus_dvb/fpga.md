# plutoplus_dvb の FPGA に組み込んだ機能

対象: Pluto+ (Zynq-7010 `xc7z010clg400-1`)、ブランチ `main`(RRC ×2)。

DVB-S2 の送信処理を FPGA で行う構成です。受信側の信号処理はなく、受信 IQ はそのまま DMA で ARM へ渡します。

## 構成

```
送信 (ARM → RF)
  DMA ─▶ switchsrc ─┬─▶ DVB-S2 エンコーダ ─▶ switchfir ─┬─▶ RRC ×2 ─▶ switchdest
                    └────────── (IQ 直送) ──▶           └──────────▶
  switchdest ─▶ upack ─▶ TX FIR ×8(任意) ─▶ AD9364 インターフェース

受信 (RF → ARM)
  AD9364 インターフェース ─▶ cpack ─▶ DMA
```

## 組み込んだ機能

| 機能 | 内容 | 定義 |
|---|---|---|
| DVB-S2 エンコーダ | `dvb_fpga`(OpenResearchInstitute)+ `hdl/patches/dvb_fpga`。BCH、LDPC、インターリーブ、マッピング、PL フレーム化 | `common/dvb.tcl` |
| RRC 補間フィルタ | ×2、65 タップ × 係数 2 セット(切替可) | `common/dvb.tcl`、`common/rrc_interp_firwin2.coe` |
| TX FIR 補間 | ×8、低いサンプルレートの送信用(有効/無効を切替) | `common/txfir.tcl`、`common/interpolator_x8.coe` |
| 信号経路スイッチ | AXI4-Stream スイッチ 3 個。DVB-S2 / IQ 直送(RRC あり・なし)を選択 | `common/dvb.tcl` |
| AD9364 インターフェース | `axi_ad9361`、1R1T(`mode1r1t`) | `common/xilinx_ad9361.tcl` |
| DMA | 送受信とも `axi_dmac`、`S_AXI_HP2` 経由 | `common/dma.tcl` |

対応する方式(エンコーダの仕様): QPSK / 8PSK / 16APSK / 32APSK、符号化率 1/4〜9/10、ノーマル / ショートフレーム、パイロットあり / なし。

サンプルレートはシンボルレートの 2 倍です。AD936x の送受信は同じレートなので、受信も 2 倍で開けます。

## 組み込んでいないもの

- Maia-SDR(ウォーターフォール、録音)
- DDS(テストトーン)
- スイープ、8 ビット受信変換
- 受信のデシメーション、DVB-S2 の復調
- 2R2T(送受信 2 系統)

## レジスタ

| アドレス | 内容 |
|---|---|
| `0x43C03000` | `switchsrc` |
| `0x43C02000` | `switchfir` |
| `0x43C01000` | `switchdest` |
| `0x43C10000` | `dvbs2_encoder_wrapper_0` |
| `0x790240BC` | AD9361 DAC GPIO(下記) |

`0x790240BC` のビット(`axi_ad9361/up_dac_gpio_out`):

| ビット | 内容 |
|---|---|
| 0 | TX FIR ×8 の有効 / 無効 |
| 1 | DVB-S2 エンコーダのリセット(0 でリセット、1 で動作) |
| 2 | RRC 係数セットの選択 |
| 3 | RRC 係数セットの設定有効 |

## リソース(Vivado 2025.2.1)

| 項目 | 使用 | 上限 | 使用率 |
|---|---|---|---|
| Slice LUTs | 11,774 | 17,600 | 66.90% |
| Slice Registers | 16,347 | 35,200 | 46.44% |
| Block RAM Tile | 25.5 | 60 | 42.50% |
| DSPs | 54 | 80 | 67.50% |

タイミング(`postroute_physopted`): WNS +0.152 ns、WHS +0.025 ns、制約達成。

## 実機での確認状況

| 項目 | 状態 |
|---|---|
| RRC ×2 版、500 kS/s、元のアプリでのロック | 確認済み(build11) |
| RRC ×2 版の 4 方式のヘッダー解読、1000 kS/s | 未確認 |
| パイロットあり | 確認済み(QPSK 3/5) |
| ショートフレーム | 未確認 |
| 帯域外の不要輻射 | 未測定 |

## 注意点

- RRC のロールオフは FPGA の係数で決まります。`-r` などのソフトの指定は効きません。係数の測定では 2 セットとも 0.2 前後で、`PLUTOPLUS_DVB.md` の「0.35 固定」とは一致していません。
- シンボルレート 260 kS/s 未満(サンプルレートが 520 kS/s 未満)は TX FIR ×8 の経路に入ります。この場合、同じ Pluto で受信を開くとレートが衝突します。

---

# FPGA functions in plutoplus_dvb

Target: Pluto+ (Zynq-7010 `xc7z010clg400-1`), branch `main` (RRC x2).

The DVB-S2 transmit processing runs in the FPGA. There is no receive signal processing: RX IQ goes straight to the ARM through DMA.

| Function | Details | Defined in |
|---|---|---|
| DVB-S2 encoder | `dvb_fpga` plus `hdl/patches/dvb_fpga`: BCH, LDPC, interleaving, mapping, PL framing | `common/dvb.tcl` |
| RRC interpolator | x2, 65 taps, 2 selectable coefficient sets | `common/dvb.tcl`, `common/rrc_interp_firwin2.coe` |
| TX FIR interpolator | x8, optional, for low sample rates | `common/txfir.tcl`, `common/interpolator_x8.coe` |
| Path switches | 3 AXI4-Stream switches: DVB-S2 or direct IQ (with or without RRC) | `common/dvb.tcl` |
| AD9364 interface | `axi_ad9361`, 1R1T (`mode1r1t`) | `common/xilinx_ad9361.tcl` |
| DMA | `axi_dmac` for TX and RX through `S_AXI_HP2` | `common/dma.tcl` |

The sample rate is twice the symbol rate. The AD936x shares it between TX and RX, so RX can be opened at 2x the symbol rate.

Not included: Maia-SDR, DDS, sweeper, 8-bit RX conversion, RX decimation, DVB-S2 demodulation, 2R2T.

The register map, resource use and verification status are in the Japanese section above.
