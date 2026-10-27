# Architecture — Color Lines

Offline Flutter/Dart recreation of Gamos Color Lines (1992).

## Layers

```
lib/main.dart
lib/game/
  model/        # BoardState, GameState, BallColor, CellPosition
  logic/        # Movement (BFS), LineDetector, Scoring, Spawn, GameController
  rendering/    # Palette, pixel text, board/cell/ball/sprite painters, layout
  ui/           # GameScreen (scale), GameFrame (session), input, sound
  persistence/  # HighScoreStore (JSON file via dart:io, no plugins)
```

## Rules of separation

- Game logic has no Flutter Canvas dependency.
- Rendering never mutates game state.
- Input goes through `GameController`.
- Palette is centralized in `GamePalette` (exactly 16 colors).
- `SpawnService` accepts a fixed color sequence for deterministic tests.

## Virtual canvas

Composition is authored at **640×480**. `GameScreen` letterboxes with the largest integer scale and `FilterQuality.none`.

## Scoring

Provisional Lines 98 table (see `docs/counting.md`); not verified as exact Gamos 1992.

## Audio

No native audio plugins (so macOS runs without CocoaPods). Cues use Flutter `SystemSound`. Placeholder WAV files remain in `assets/sounds/` for a future optional player. Fanfare flag still fires once when beating the King score.

## Dependencies

Runtime depends only on the Flutter SDK — no pub plugins that need CocoaPods/Gradle.
