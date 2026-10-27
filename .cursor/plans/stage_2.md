# Stage 2 — Application Skeleton

## Goal
Runnable Flutter desktop app with module structure and 640×480 virtual canvas scaling.

## Tasks
- `flutter create` in repo root (preserve `docs/`)
- Create `lib/game/{model,logic,rendering,ui,persistence}` stubs
- Implement letterboxed 640×480 `GameScreen` with integer nearest-neighbor scale
- Smoke test

## Acceptance
- App runs locally offline
- Virtual area preserves 4:3 proportions
- `flutter test` runs
