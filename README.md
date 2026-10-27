# Color Lines (Gamos 1992 recreation)

Native Flutter desktop/web recreation of **Color Lines** by Gamos Ltd. (1992): programmatic DOS-style board and balls, 16-color palette, pixel text, King/Pretender sprites.

## Requirements

- Flutter SDK only (developed against Flutter 3.41 / Dart 3.11)
- **No CocoaPods / no third-party plugins** — sound uses `SystemSound`, scores use a local JSON file

## Run

```bash
flutter pub get
flutter run -d macos
```

Or:

```bash
flutter run -d chrome
```

## Controls

| Input | Action |
| --- | --- |
| Click ball | Select (bounce animation) |
| Click empty cell | Move if a clear orthogonal path exists |
| F1 | Help overlay |
| F2 | Toggle sound |
| F3 | Deselect |
| F4 | Restart / new game |

## Tests

```bash
flutter test
```

## Docs

- [docs/task.md](docs/task.md) — full technical specification
- [docs/mechanics.md](docs/mechanics.md) — gameplay rules
- [docs/visual-reference.md](docs/visual-reference.md) — geometry and palette
- [docs/architecture.md](docs/architecture.md) — module layout
- [docs/sound-animation.md](docs/sound-animation.md) — bounce / footprints / SFX notes
- [docs/counting.md](docs/counting.md) — provisional scoring table

## Known limitations

- Scoring uses a provisional Lines 98 table; exact 1992 Gamos formula is unverified.
- Audio uses system click sounds (no plugin); WAV placeholders are unused until a pure-Dart player is added.
- High score is stored in `~/.color_lines_highscore.json`.
- Decorative gothic character-name fonts are approximated with the 8×8 pixel font.
- Title-screen cityscape art is out of MVP scope (no screenshot cropping).
- Top Ten name-entry UI is not fully recreated; high score persists locally as the King record.
