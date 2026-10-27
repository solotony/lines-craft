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
  persistence/  # HighScoreStore (shared_preferences)
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

Placeholder WAV files in `assets/sounds/`. Original Gamos samples are unknown; title and fanfare are separate assets. Fanfare plays once when the player first exceeds the King score.
