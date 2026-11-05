# OpticRCWAFDTD — RCWA, FDTD and mode solvers for MATLAB

**English and 繁體中文 side by side · 中英對照**

Rigorous electromagnetic solvers written in MATLAB, with ready-made design
flows for **metalenses** and **silicon-photonics fiber couplers (CPO)**.

以 MATLAB 實作的嚴格電磁數值求解器，內建 **超穎透鏡（metalens）** 與
**矽光子光纖耦合（CPO）** 設計流程。

## Features · 功能

- **TMM** – thin-film stacks
  <br>薄膜堆疊
- **RCWA** – 1D and 2D (crossed) gratings, Li factorization rules, stable
  S-matrices, batched unit-cell sweeps, automatic mirror-symmetry reduction,
  field reconstruction inside the structure
  <br>一維與二維（交叉）光柵、Li 傅立葉分解規則、穩定的 S 矩陣、單元批次掃描、
  自動鏡像對稱加速、結構內部場分佈重建
- **FDTD** – 2D (TE/TM) and 3D, CPML, unidirectional mode sources, plane
  DFT monitors, subpixel averaging, optional GPU (single precision)
  <br>二維（TE/TM）與三維、CPML 吸收邊界、單向模態光源、平面 DFT 監測、
  次像素平均、可選用 GPU（單精度）
- **Mode solvers** – 1D slab (TE/TM) and full-vector 2D cross-section
  <br>**模態求解器**：一維平板波導（TE/TM）與二維截面全向量模態
- **Applications** – metalens phase library → layout → focal spot, full-wave
  3D check of the local periodic approximation; SOI grating coupler with
  fiber overlap, apodization and optimisation
  <br>**應用流程**：超穎透鏡相位庫 → 排列 → 焦點，並以三維全波模擬驗證局部週期近似；
  SOI 光柵耦合器，含光纖模態重疊、漸變（apodization）與最佳化
- **Materials** – SiO2, Si, Si3N4, TiO2, Al2O3 from published dispersion
  data; Tauc–Lorentz model for amorphous films (a-Si) from ellipsometry
  <br>**材料**：SiO2、Si、Si3N4、TiO2、Al2O3 採用文獻色散資料；
  非晶薄膜（a-Si）可用橢偏儀量得的 Tauc–Lorentz 參數
- **Apps** – `orf.MetalensDesigner` and `orf.GratingCouplerDesigner`: set
  the parameters, run with a cancellable progress bar, plot, export GDSII
  <br>**圖形介面**：填參數、執行（進度條可取消）、看圖、輸出 GDSII
- **Geometry** – rectangles, circles, polygons; sloped sidewalls
  (`orf.slantedLayers`, cones in 3D FDTD, trapezoidal grating grooves)
  <br>**幾何**：矩形、圓、多邊形；斜側壁（`orf.slantedLayers`、三維 FDTD 圓錐、梯形光柵溝槽）
- **Run control** – progress callbacks with cancel, time and memory
  estimates calibrated on your machine, automatic RCWA convergence
  <br>**執行控制**：進度回呼與取消、依本機實測校正的時間與記憶體估算、RCWA 自動收斂
- **Design files** – `orf.saveDesign` / `orf.loadDesign`: structures,
  materials and parameters in readable JSON, reloaded ready to simulate
  <br>**設計檔**：結構、材料與參數存成可讀的 JSON，讀回即可直接模擬
- **Layout** – GDSII export (metalens pillar arrays, grating couplers) and
  import (`orf.gdsRead`, references flattened) – no external tools needed
  <br>**佈局**：GDSII 輸出（超穎透鏡柱陣列、光柵耦合器）與匯入（`orf.gdsRead`，
  自動展開參照），不需外部工具

All functions live in the `orf` namespace: `orf.rcwa2D`, `orf.fdtd3D`, `orf.tmm`, …
<br>所有函式都在 `orf` 命名空間下，例如 `orf.rcwa2D`、`orf.fdtd3D`、`orf.tmm`。

## Validation · 驗證

Every solver is checked against an exact reference; 114 automated tests ship
with the toolbox (`runAllTests`).

每個求解器都對照精確參考值驗證；toolbox 附 114 項自動測試（`runAllTests`）。

| Check · 驗證項目 | Reference · 參考 | Agreement · 誤差 |
|---|---|---|
| TMM | Fresnel, Airy, Bragg mirror<br>Fresnel、Airy、布拉格反射鏡 | ≤ 1e-12 |
| RCWA, uniform layers<br>RCWA 均勻層 | TMM | ~1e-16 |
| **RCWA vs RETICOLO V10** (1D/2D, oblique, metal, phase library)<br>**RCWA 對 RETICOLO V10**（1D/2D、斜入射、金屬、相位庫） | external code, same harmonics<br>外部程式、相同階數 | ≤ 1e-12 |
| RCWA, Granet metallic and Lalanne–Hugonin dielectric gratings<br>RCWA：Granet 金屬光柵、Lalanne–Hugonin 介電光柵 | published converged values<br>文獻收斂值 | 1e-6 – 2e-5 |
| RCWA, sub-wavelength grating<br>RCWA 次波長光柵 | effective-medium film<br>等效介質薄膜 | TE 8e-7, TM 1.2e-4 |
| **RCWA ↔ FDTD, 2D grating** (TE, TM, ±1 orders)<br>**RCWA ↔ FDTD 二維光柵**（TE、TM、±1 階） | independent solvers<br>獨立求解器互相對照 | < 2e-3 |
| **RCWA ↔ FDTD, 3D pillar array**<br>**RCWA ↔ FDTD 三維柱陣列** | independent solvers<br>獨立求解器互相對照 | 3e-4 |
| FDTD guided-mode index<br>FDTD 導模有效折射率 | exact Yee-grid dispersion<br>Yee 網格精確色散 | 2D 2e-6, 3D < 1e-4 |
| RCWA fields<br>RCWA 場分佈 | analytic slab; flux = T at every depth<br>解析平板；各深度能流等於 T | 1e-15; 1e-10 |
| 2D mode solver, SOI 500×220 nm strip<br>二維模態求解器，SOI 500×220 nm 條狀波導 | literature (~2.44–2.45)<br>文獻值（約 2.44–2.45） | TE0 = 2.4464 |

## Requirements · 系統需求

- MATLAB **R2023a or newer**
  <br>MATLAB **R2023a 以上**
- Optional: Parallel Computing Toolbox and a supported NVIDIA GPU for FDTD
  (`sim.useGPU = true`). RCWA runs on the CPU.
  <br>選配：Parallel Computing Toolbox 與支援的 NVIDIA GPU，用於 FDTD
  （`sim.useGPU = true`）。RCWA 在 CPU 上執行。

Run `orf.checkEnvironment` to see what your installation supports.
<br>執行 `orf.checkEnvironment` 查看目前環境支援哪些功能。

## Install · 安裝

- **Add-On Explorer / File Exchange**: search for *OpticRCWAFDTD* and click *Add*.
  <br>**附加元件瀏覽器 / File Exchange**：搜尋 *OpticRCWAFDTD*，按 *Add*。
- **Toolbox file**: double-click `OpticRCWAFDTD.mltbx`.
  <br>**Toolbox 安裝檔**：雙擊 `OpticRCWAFDTD.mltbx`。
- **From source**: clone this repository and run `setupPaths`.
  <br>**從原始碼**：clone 本 repo 後執行 `setupPaths`。

## Quick start · 快速開始

```matlab
% Reflectance of a quarter-wave anti-reflection coating on glass
% 玻璃上四分之一波長抗反射膜的反射率
lam = linspace(0.4, 0.8, 201).';
out = orf.tmm(lam, [1 sqrt(1.52) 1.52], 0.55/(4*sqrt(1.52)), 0, "s");
plot(lam, out.R)

% Transmission of a silicon grating with RCWA
% 用 RCWA 計算矽光柵的穿透率
air = orf.materialConst(1); glass = orf.materialConst(1.45); si = orf.materialConst(3.48);
g = orf.makeStructure([0.7 Inf], air, glass, ...
      {orf.makeLayer(0.5, air, {orf.shapeRect(0.35, Inf, si)})});
o = orf.rcwa1D(g, 1.55, 0, 0, "p", N=15);
fprintf('T = %.4f, R = %.4f\n', o.Ttot, o.Rtot)
```

Then open **`examples/GettingStarted.m`** (about 15 s): TMM, RCWA, a metalens
phase library and FDTD, each with a plot.
<br>接著打開 **`examples/GettingStarted.m`**（約 15 秒）：TMM、RCWA、超穎透鏡相位庫與 FDTD，各附一張圖。

Or start an app · 或直接開啟圖形介面：

```matlab
orf.MetalensDesigner        % unit-cell library -> layout -> focal spot -> GDSII
                            % 單元相位庫 -> 排列 -> 焦點 -> GDSII
orf.GratingCouplerDesigner  % SOI grating coupler: spectrum, power budget, GDSII
                            % SOI 光柵耦合器：耦合頻譜、功率收支、GDSII
```

## Examples · 範例

| Script · 腳本 | What it does · 內容 | Time* · 時間* |
|---|---|---|
| `GettingStarted.m` | Tour of all solvers<br>所有求解器導覽 | 15 s |
| `metalens_unitcell_940nm.m` | a-Si pillar phase library with convergence check<br>a-Si 柱相位庫與收斂檢查 | ~3 min |
| `metalens_demo_940nm.m` | 40 µm metalens: library, layout, focal spot<br>40 µm 超穎透鏡：相位庫、排列、焦點 | ~3 min |
| `metalens_fullwave_3d.m` | 3D FDTD of a metalens vs RCWA + LPA<br>超穎透鏡三維 FDTD 對照 RCWA + 局部週期近似 | 5 min (GPU) |
| `cpo_grating_coupler_1550.m` | SOI grating coupler to SMF-28<br>SOI 光柵耦合器到 SMF-28 光纖 | 1–3 min |
| `cpo_grating_optimize.m` | Apodized coupler optimisation<br>漸變光柵耦合器最佳化 | ~1.5 h |
| `cpo_box_scan.m` | Coupling vs buried-oxide thickness<br>耦合效率對 BOX 厚度 | ~20 min |
| `export_gds.m` | Metalens and grating coupler to GDSII<br>超穎透鏡與光柵耦合器輸出 GDSII | ~5 s |
| `rcwa_fields_pillar.m` | Field inside a metalens unit cell<br>超穎透鏡單元內的場分佈 | ~2 s |

\*12-thread laptop CPU with an entry-level GPU.
<br>\*12 執行緒筆電 CPU，搭配入門級 GPU。

## Conventions · 慣例

The same in every solver: time dependence **exp(−iωt)**, lengths in **µm**,
z is the stacking/propagation direction, lossy materials have **Im(n) > 0**.
See `docs/CONVENTIONS.md`.

所有求解器一致：時間相依 **exp(−iωt)**、長度單位 **µm**、z 為堆疊／傳播方向、
有損材料 **Im(n) > 0**。詳見 `docs/CONVENTIONS.md`。

## Known limitations (v0.1) · 已知限制（v0.1）

- Materials: built-in SiO2, Si (> 1.2 um), Si3N4, TiO2 (rutile), Al2O3; amorphous
  films via `orf.materialTaucLorentz`; anything else via `orf.materialTable`.
  No metals yet, and FDTD has no dispersive (Drude/Lorentz) media.
  <br>材料：內建 SiO2、Si（> 1.2 µm）、Si3N4、TiO2（金紅石）、Al2O3；非晶薄膜用
  `orf.materialTaucLorentz`；其他材料用 `orf.materialTable` 匯入 n,k 表。
  尚無內建金屬，FDTD 尚不支援色散介質（Drude/Lorentz）。
- Geometry: rectangles, circles and polygons (RCWA); boxes, cylinders, cones,
  polygon prisms and pillar lattices (3D FDTD). GDSII import reads polygons and
  references (PATH elements are skipped); layer numbers must be set to your PDK.
  <br>幾何：RCWA 支援矩形、圓、多邊形；三維 FDTD 支援方塊、圓柱、圓錐、多邊形柱與柱陣列。
  GDSII 匯入讀取多邊形與參照（PATH 元素略過）；圖層編號需依你的 PDK 設定。
- Grating couplers are 2D; 3D couplers need a large GPU.
  <br>光柵耦合器目前為二維模擬；三維耦合器需要大記憶體 GPU。
- RCWA agrees with RETICOLO to round-off; FDTD is checked against this
  toolbox's RCWA and exact references; comparisons with Meep are in progress.
  <br>RCWA 與 RETICOLO 吻合到數值捨入誤差；FDTD 已對照本 toolbox 的 RCWA 與精確參考值；
  與 Meep 的對照進行中。

## License · 授權

Free to use, including commercially. Files distributed as source (`.m`) may
be modified; protected files (`.p`) may not be decompiled or reverse
engineered. See `LICENSE.txt`.

可免費使用，包含商業用途。以原始碼（`.m`）發布的檔案可以修改；受保護檔案（`.p`）
不得反編譯或逆向工程。詳見 `LICENSE.txt`。
