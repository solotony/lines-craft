# Stage 3 — Pixel Text Rendering and Palette

## Goal
Working `GamePalette` (16 colors) and `PixelTextRenderer` with nearest-neighbor upscale.

## Tasks
- Implement palette from `docs/visual-reference.md`
- Embed 8×8 DOS-style bitmap font
- Raster text + integer nearest-neighbor scale
- Color-count verification test
- Optional diagnostic text on skeleton screen

## Acceptance
- Text has no anti-aliased outlines
- Scaling uses nearest-neighbor
- Text colors from shared palette
- Test frame ≤ 16 unique colors
