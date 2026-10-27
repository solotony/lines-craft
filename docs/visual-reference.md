# Visual Reference — Gamos Color Lines (1992)

Canonical resolution: **640 × 480** virtual pixels.  
Primary sources: `docs/images/640x480/1176-lines_001.png` … `1176-lines_009.png`.  
Secondary (distorted proportions — do not use for layout): `docs/images/640x350/`.

Measurements below are approximate integer pixel coordinates taken from indexed screenshots. Capture noise and watermark overlays may shift edges by ±1 px; prefer the values here as the implementation baseline and refine in Stage 8 against side-by-side comparison.

---

## 1. Overall composition

| Region | Approx. rect (x, y, w, h) | Notes |
| --- | --- | --- |
| Full canvas | 0, 0, 640, 480 | Black outside chrome |
| Top chrome / score bar | 0, 0, 640, ~42 | Beveled gray panel |
| Playfield gap | below top bar to bottom bar | Black background |
| Bottom command bar | 0, ~423, 640, ~57 | Beveled gray; F-keys |
| Board (outer) | ~150, ~70, ~340, ~321 | Includes outer black/gray frame |
| King / Handicap column | ~20–120 × ~80–360 | Tall pedestal |
| Pretender column | ~520–620 × ~100–360 | Shorter pedestal |

Layout rhythm: left character | board | right character; scores and “Next” on top; commands on bottom. Do not rearrange for modern responsive HUD patterns.

---

## 2. Game board geometry

Grid lines (black separators) observed on `1176-lines_002.png`:

- **Vertical separators (x):** 170, 204, 238, 272, 306, 340, 374, 408, 442, 476  
  → pitch **34** px → 9 columns
- **Horizontal separators (y):** 82, 115, 148, 181, 214, 247, 280, 313, 346, 379  
  → pitch **33** px → 9 rows

**Implementation baseline**

| Parameter | Value |
| --- | --- |
| Board origin (cell 0,0 top-left of first cell interior) | `boardOrigin = (171, 83)` |
| Cell pitch X | 34 |
| Cell pitch Y | 33 |
| Cell interior size | ~32 × 31 (pitch minus 1 px groove) |
| Columns × rows | 9 × 9 |

Each empty cell is a recessed DOS bevel: dark floor, light top/left edge, dark bottom/right edge. No grid bitmap.

**Selected cell:** highlight with a palette-only bright border or inset frame; exact original selection chrome is uncertain — use a 1–2 px white/yellow outline inside the cell if references are ambiguous.

---

## 3. Top bar

| Element | Approx. position | Content |
| --- | --- | --- |
| Left score box | ~left of top bar | King’s / Handicap high score (green digits on black) |
| Center “Next” | mid top bar | Label + 3 small ball preview cells |
| Right score box | ~right of top bar | Player score (“Colors”) green digits on black |

Digit color in references is bright green on black. Labels use yellow/gothic styling for character names; HUD labels may use the pixel monospace font.

---

## 4. Characters and pedestals

Permitted raster sprites (copy into `assets/images/` in later stages):

| File | Size | Role |
| --- | --- | --- |
| `docs/images/king.png` | 70 × 90 | King / Handicap idle |
| `docs/images/king-lose.png` | 61 × 81 | King when player beats record |
| `docs/images/pretender.png` | 67 × 78 | Pretender idle |
| `docs/images/pretender-wins.png` | 66 × 82 | Pretender when beating King |

Place on gray cylindrical pedestals drawn programmatically. Left pedestal taller than right (see references). Labels under pedestals: “Handicap” / player name / “Pretender” in yellow decorative style; for MVP, pixel text in `labelYellow` is acceptable if a gothic face is not bundled.

Sprites must be quantized to the 16-color palette before final frames (Stage 5/8).

---

## 5. Bottom command bar

Observed labels (left → right after GAMOS mark):

- **F1 HELP**
- **F2 SOUND** (active state uses green label tint)
- **F3 NEXT**
- **F4 RESTART**

GAMOS mark: draw a simple programmatic badge/text; do not paste screenshot logo art.

---

## 6. Balls

- Seven playable colors (see palette ball slots below).
- Drawn programmatically: base disc + bright highlight quadrant + dark shade; hard pixel edges; no anti-aliasing.
- Centered in cell; diameter ≈ 22–26 px (leave visible gap to cell bevel). Leave exact diameter for Stage 5 comparison.
- Next-preview balls use the same renderer at a smaller diameter (~14–16 px).

---

## 7. Footprints

| Assets | Size |
| --- | --- |
| `docs/images/footprints/footprint1-{up,down,left,right}.png` | 22 × 22 |
| `docs/images/footprints/footprint2-{up,down,left,right}.png` | 22 × 22 |

Used only for movement path visualization (Stage 7). Fade traversed footprints; clear after move completes.

---

## 8. Fixed 16-color palette

Screenshots are indexed with ~60–64 entries due to capture/dithering. The game uses a **designed** 16-color table (VGA-faithful, not a dump of every captured shade).

| Index | Name | RGB | Hex | Usage |
| ---: | --- | --- | --- | --- |
| 0 | black | 0, 0, 0 | `#000000` | Background, grooves |
| 1 | white | 254, 254, 254 | `#FEFEFE` | Highlights, bevel light |
| 2 | panelGray | 170, 170, 170 | `#AAAAAA` | Panel faces, cell fill |
| 3 | shadowGray | 85, 85, 85 | `#555555` | Bevel shadow |
| 4 | darkGray | 58, 58, 58 | `#3A3A3A` | Deep recess, pedestals |
| 5 | ballRed | 254, 0, 0 | `#FE0000` | Ball / King accents |
| 6 | ballRedDark | 167, 0, 0 | `#A70000` | Red shade |
| 7 | ballMagenta | 254, 0, 254 | `#FE00FE` | Ball / Pretender |
| 8 | ballMagentaDark | 172, 0, 172 | `#AC00AC` | Magenta shade |
| 9 | ballYellow | 254, 254, 0 | `#FEFE00` | Ball |
| 10 | ballOrange | 254, 168, 0 | `#FEA800` | 7th ball / gold accents |
| 11 | ballGreen | 0, 173, 0 | `#00AD00` | Ball / score text |
| 12 | ballBlue | 0, 0, 174 | `#0000AE` | Ball |
| 13 | ballCyan | 0, 251, 254 | `#00FBFE` | Ball |
| 14 | labelYellow | 254, 233, 1 | `#FEE901` | Character name labels |
| 15 | midGray | 118, 118, 118 | `#767676` | Secondary bevel / chrome |

**Ball color enum mapping (7 colors):**  
`red→5/6`, `magenta→7/8`, `yellow→9` (+ orange shade from 10), `orange→10` (+ darkGray shade), `green→11`, `blue→12`, `cyan→13`.

No colors outside this table in programmatic graphics. Character/footprint rasters are remapped onto this table.

---

## 9. Pixel text

| Decision | Choice |
| --- | --- |
| Font | Embedded **8×8 DOS-style bitmap** glyph table in code (`PixelFont8`), covering digits, A–Z, space, and HUD punctuation |
| Optional later | Bundle a licensed bitmap TTF if needed for gothic name labels |
| Pipeline | Render glyphs into a small `Image` / buffer at 1× → enlarge by integer factor with **nearest neighbor** |
| Default HUD scale | 2× (8×8 → 16×16 virtual px per glyph) for scores; 1× or 2× for F-key labels after visual check |
| Colors | Foreground/background only from `GamePalette` |
| Forbidden | Flutter `Text` as final on-screen glyphs; bilinear/bicubic upscaling |

---

## 10. Animation / sound (visual notes)

From `docs/sound-animation.md` and `docs/mechanics.md` (implement in Stages 7–8):

- Selected ball: continuous squash-and-stretch bounce in cell
- Move: bounce cell-to-cell; footprints along path fade behind the ball
- Land SFX aligned with squash frame; fanfare once when score first exceeds King’s record

---

## 11. Uncertainties (conservative defaults)

| Topic | Default until verified |
| --- | --- |
| Exact Gamos 1992 scoring table | Provisional Lines 98 table in `docs/counting.md` |
| Exact selection highlight chrome | 2 px `white` inset border |
| Gothic “Handicap”/“Pretender” typeface | Pixel 8×8 in `labelYellow` for MVP |
| Original PCM/MIDI audio | Placeholder WAV tones in `assets/sounds/` (not original Gamos recordings); title melody and fanfare are separate assets as required |
| Title-screen cityscape art | Out of MVP raster budget; start in gameplay or simple pixel title |

---

## 12. Source image index

| Image | State shown |
| --- | --- |
| `640x480/1176-lines_001.png` | Title screen |
| `640x480/1176-lines_002.png` … `007.png` | Gameplay with balls |
| `640x480/1176-lines_008.png` | Top Ten / name entry |
| `640x480/1176-lines_009.png` | Early game / fewer balls |
| `king*.png`, `pretender*.png` | Character sprites |
| `footprints/*` | Path markers |
