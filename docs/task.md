Ниже — английская версия технического задания для Cursor. Я сохраняю исходную структуру, нумерацию разделов, требования, критерии приёмки и названия файлов, чтобы документ можно было использовать непосредственно в проекте.

# Technical Specification for Cursor: Gamos Color Lines (1992)

## 1. Project Objective

Create a native standalone game that closely reproduces the visual style and gameplay of the original **Color Lines by Gamos Ltd. (1992) for DOS**.

This is not a modern remake with a retro theme. It is a recreation of the original low-resolution graphical interface, including the game board geometry, three-dimensional cells, colored balls, character sprites, limited color palette, and pixelated typography.

The game must run locally without a server, user account, network connection, or external gaming services.

### Core Requirements

- Native standalone application built with Flutter/Dart.
- The game board, cells, balls, selection indicators, and game effects must be drawn programmatically.
- Raster images are permitted **only for the King and Pretender character sprites**.
- All game graphics must use a fixed palette of exactly 16 colors.
- Text must be rendered as pixel graphics and enlarged without smoothing.
- The interface and game board must scale as a whole, preserving their original proportions and pixel sharpness.
- Game rules must match the original Color Lines mechanics.
- Architecture and implementation must be divided into separate stages, each with clearly defined completion criteria.

## 2. Technologies and Constraints

### 2.1. Technology Stack

- Dart.
- Flutter.
- Flutter `CustomPainter` and Canvas for programmatic rendering.
- Local storage for high scores and settings.
- Automated tests for game rules and key scenarios.
- Offline operation.

Do not use HTML, WebView, browser-based game engines, or server-side architecture.

Do not introduce a full-fledged game engine when Flutter Canvas is sufficient.

### 2.2. Rendering Principles

All elements, except for the two character portraits, must be generated programmatically:

- Black background.
- Game board.
- Grid.
- Three-dimensional cells.
- Balls.
- Shadows and highlights.
- Selected cell.
- Movement animation.
- Score and auxiliary indicators.
- Panels and separators.
- Pixelated borders and decorative elements.

Do not use ready-made images of balls, cells, game panels, screenshots, or parts of the game interface.

Do not use raster images for logos, icons, backgrounds, buttons, fonts, or decorative elements.

The only permitted raster game images are:

1. King.
2. Pretender.
3. Footprint images used to indicate the movement path.

These images must be positioned in the interface according to the original game's visual references.

## 3. Visual Reference

The primary reference is the original 1992 DOS version of Gamos Color Lines.

Use the downloaded images in `docs/images`.

- **640 × 480** is the canonical resolution.
- **640 × 350** represents distorted proportions.

Before implementation begins, study the references and document the following:

- Game window dimensions and proportions.
- Position of the board and side panels.
- Cell dimensions and spacing.
- Shape and volume of the balls.
- Color combinations.
- Positions of the King and Pretender.
- Score display.
- Bottom command panel.
- Overall visual rhythm of the interface.

Save the selected references and their description in `docs/visual-reference.md`.

Use screenshots to understand different interface states, but do not assemble ready-made game elements from screenshots.

## 4. Resolution and Coordinate System

### 4.1. Base Resolution

Use a base virtual resolution of **640 × 480 pixels**, corresponding to a common image format for the original DOS version.

Design the entire game composition using these coordinates.

Element dimensions, spacing, and font sizes must be specified in virtual pixels, not Flutter logical pixels or physical screen pixels.

### 4.2. Scaling

Scale the entire game screen uniformly, preserving the 640 × 480 aspect ratio.

When enlarging:

- Use integer scaling whenever it allows the available area to be filled reasonably well.
- Disable smoothing.
- Preserve sharp pixel boundaries.
- Do not stretch the image independently along the horizontal and vertical axes.
- Do not change the relative sizes of interface elements.

If integer scaling cannot fit the available area, use the largest smaller integer scale and leave unused space around the image.

The outer application window may adapt, but the internal game geometry must not change.

Do not redesign the interface using modern responsive layouts that rearrange panels. The original composition must remain intact.

## 5. Restricted Palette: Exactly 16 Colors

### 5.1. Mandatory Requirement

All game graphics must use a fixed palette of exactly 16 colors.

This applies to:

- Background.
- Cells.
- Balls.
- Highlights.
- Shadows.
- Borders.
- Text.
- Selection indicators.
- Animations.
- Decorative elements.

Do not use arbitrary RGB colors, transparent gradients, or additional shades introduced by anti-aliasing.

Do not use transparency if compositing would introduce new colors.

### 5.2. Palette Definition

Create a single palette file or module, such as `GamePalette`.

Define exactly 16 colors based on references to the original game and its VGA palette.

The palette must include the colors required for the black background, neutral gray elements, bright highlights, white text, and colored balls.

Before rendering begins, create a palette table containing 16 unique RGB values.

Do not introduce colors outside this table in individual components.

If an original screenshot contains more colors because of screen capture, anti-aliasing, or image-processing artifacts, this does not mean all those colors belong in the palette.

The priority is visual fidelity to the original DOS graphics.

### 5.3. Verification

Add a test or diagnostic mode that verifies that the final game frame contains no more than 16 unique colors.

If an intermediate frame must be exported, inspect the final raster of the game area after rendering but before scaling and displaying it on screen.

CI must prevent the introduction of new colors caused by anti-aliasing.

## 6. Game Board

### 6.1. Geometry

The game board is a **9 × 9 grid**, containing 81 cells.

Position the board in the central area of the interface, as in the original game.

Define all cell dimensions, gaps, margins, and borders using virtual coordinates.

Do not use a ready-made grid image.

### 6.2. Cell Rendering

Draw every cell programmatically.

Each cell should look like a separate rectangular or nearly square recessed surface, with the characteristic three-dimensional appearance of early DOS graphics.

Implement:

- A dark inner surface.
- Light and dark borders.
- A recessed appearance.
- Sharp stepped lines.
- Identical geometry for all cells.

Use several colors from the approved palette to create the illusion of depth.

Do not use modern blurred shadows, gradients, translucent glows, or rounded cards.

### 6.3. Empty Cells

An empty cell must be visually distinguishable from a ball while keeping the grid clearly readable.

Do not overlay the board with textures or images containing a pre-rendered grid.

### 6.4. Cell Selection

When a ball is selected:

- Clearly highlight the selected cell.
- Preserve the pixel-art style.
- Use only colors from the approved palette.
- Do not alter the grid geometry.

Choose the highlighting method based on the references. If the original behavior cannot be established precisely, use the simplest solution consistent with the DOS aesthetic.

## 7. Balls

### 7.1. Programmatic Rendering

Render all balls using Canvas, geometric primitives, and discrete color regions.

Do not use PNG, SVG, photographs, ready-made sprites, or emoji.

Balls should appear three-dimensional but consist of clearly defined color regions without anti-aliasing.

Implement:

- Base color.
- Bright highlight.
- Darkened area.
- Optional outline or pixelated shadow.

Use a limited number of colors from the shared palette.

### 7.2. Ball Colors

Support the color variants corresponding to the original game.

Determine the exact number of game colors and their mapping to the palette from the references and the original game mechanics.

Each ball color must have a stable representation in both the game model and the renderer.

### 7.3. Size and Position

- Center each ball precisely within its cell.
- Determine its diameter relative to the cell size.
- Leave a clearly visible gap between the ball and the cell borders.
- Do not allow balls to overlap neighboring cells.
- Keep all balls the same size unless the original game specifies a different state or effect.

### 7.4. Animations

Implement animation for moving a ball between cells.

The animation must be short and pixel-sharp.

Subpixel blurring and anti-aliasing are prohibited during movement. Intermediate coordinates must be rounded to integer virtual pixels.

If animation reduces fidelity to the original or complicates correct gameplay, prioritize correct mechanics and crisp rendering.

## 8. Characters: King and Pretender

### 8.1. Use of Images

These are the only two game elements permitted to use ready-made raster images.

Use separate files:

- `docs/images/king.png`
- `docs/images/pretender.png`
- `docs/images/king-lose.png`
- `docs/images/pretender-wins.png`

### 8.2. Placement

Position the character sprites in the interface areas shown in the references.

Do not add any other illustrations or characters.

## 9. Text and Fonts: Low-Resolution Effect

### 9.1. Principle

Do not use ordinary Flutter `Text` widgets as the final method of displaying text on screen.

All game text must look like text from an old DOS game rendered at low resolution.

Use the following process:

1. Select a suitable monospaced or pixel-style font.
2. Render the text into a small source raster.
3. Convert the text into a pixel image.
4. Enlarge the raster by an integer factor without smoothing.
5. Place the resulting image in the virtual 640 × 480 composition.

Text must consist of crisp pixels rather than the smoothed outlines of modern fonts.

### 9.2. Font Selection

Choose a font resembling the original DOS interfaces of the early 1990s.

Acceptable options include:

- Bitmap or bitmap-style fonts.
- Monospaced fonts with clearly legible small characters.
- Fonts resembling classic VGA/DOS typefaces.

Prefer a font that looks good at small sizes and preserves the recognizability of digits.

The font must be available locally and bundled with the application, subject to its license.

### 9.3. Rendering

Create a separate module, such as `PixelTextRenderer`.

It must:

- Accept a string, character size, color, and alignment parameters.
- Generate a raster representation of the text.
- Use only colors from the approved palette.
- Enlarge the image using nearest-neighbor interpolation.
- Prohibit bilinear and bicubic interpolation.
- Ensure predictable text dimensions.
- Support all required characters and digits.

Prefer rendering text at its intended small size and then enlarging it by an integer factor.

Do not enlarge ordinary anti-aliased text, as this produces blurry outlines inconsistent with the required effect.

### 9.4. Integer Scaling

Example:

- Original text raster: 4 × 7 pixels per character.
- Scaling factor: 2×.
- Result: 8 × 14 virtual pixels per character.

This is an illustration of the method, not a mandatory character size. Select the actual font and scaling factor after visually comparing them with the references.

Every source pixel must become a rectangular block of the same color.

### 9.5. Text Elements

Implement pixel-text rendering for:

- Headings.
- Score.
- Next-ball preview.
- Numeric indicators.
- Command names.
- Hints.
- Button labels.
- Victory and game-over messages.

All text must use the same renderer.

Do not mix pixelated text with ordinary anti-aliased text in the game interface.

## 10. Interface

### 10.1. Overall Composition

Preserve the original interface structure:

- A 9 × 9 game board.
- Auxiliary areas displaying game information.
- King and Pretender character sprites.
- Current score.
- Upcoming-ball area.
- Bottom command or hint panel styled after the original DOS version.

Determine exact coordinates and dimensions from the screenshots.

Do not add a modern mobile HUD, cards, floating buttons, gradient panels, large headings, or excessive spacing.

### 10.2. Score

Display the score using pixel text.

Update it after every game action that affects the result.

Its size, alignment, and position must match the references.

### 10.3. Next Balls

Display upcoming balls in a separate interface area.

Render these balls programmatically using the same renderer as the balls on the game board.

Do not use separate images for the preview.

### 10.4. Bottom Panel

Preserve the command panel characteristic of old DOS games.

If the reference includes function-key labels, reproduce their visual arrangement.

Render all text using `PixelTextRenderer`.

Actual controls must correspond to implemented actions. Do not display function keys that do nothing.

### 10.5. Menus and States

Implement the following states:

- Game start.
- Active gameplay.
- Ball selected.
- Ball movement.
- Line completion processing.
- Game over.
- New game.

Do not add complex menus, networking, user profiles, or additional modes outside the MVP scope.

## 11. Game Rules

### 11.1. Core Mechanics

Implement the classic Color Lines rules:

- A 9 × 9 board.
- Five balls appear on the board at the start of the game.
- The player selects a ball.
- The player selects an empty destination cell.
- A ball may move only along an unobstructed path through empty cells.
- After a successful move, check for completed lines.
- If no line is formed, three new balls appear according to the original game's mechanics.
- If a line of the required length is formed, remove its balls and award points.
- The game ends when no more balls can be placed.

### 11.2. Line Formation

Check lines in four orientations:

- Horizontal.
- Vertical.
- Diagonal in one direction.
- Diagonal in the opposite direction.

The minimum line length is five balls of the same color.

When a qualifying line is formed, remove its balls and update the score.

Do not remove balls of different colors as part of the same line.

Correctly handle intersecting lines and situations in which multiple lines are formed simultaneously after one move.

Verify the exact scoring rules and the order in which intersections are processed against an available description or the original game's behavior. Do not invent additional bonuses without confirmation.

### 11.3. Path Availability

Before moving a ball, check whether a path exists from its source cell to its destination through empty cells.

If no path exists:

- Do not move the ball.
- Do not change the board state.
- Do not spawn new balls.
- Do not award points.

### 11.4. Selection and Cancellation

The player must be able to select a different ball before confirming a move.

Attempts to select an occupied destination cell must be handled predictably.

Invalid actions must not cause ball loss, score changes, or corruption of the game state.

### 11.5. Randomness

Keep the generator responsible for spawning new balls separate from rendering.

For automated tests, provide a way to set the initial board state and supply a fixed sequence of generated balls.

## 12. Application Architecture

Separate game mechanics, rendering, and user input.

Recommended structure:

```
lib/
  main.dart

  game/
    model/
      game_state.dart
      board_state.dart
      ball.dart
      cell_position.dart
      game_rules.dart

    logic/
      movement_service.dart
      line_detector.dart
      scoring_service.dart
      spawn_service.dart
      game_controller.dart

    rendering/
      game_renderer.dart
      board_renderer.dart
      cell_renderer.dart
      ball_renderer.dart
      pixel_text_renderer.dart
      palette.dart
      sprite_renderer.dart

    ui/
      game_screen.dart
      input_handler.dart

    persistence/
      high_score_store.dart

assets/
  fonts/
  images/
    leader.png
    pretender.png

test/
  game/
  rendering/
  integration/

docs/
  visual-reference.md
  architecture.md
```

The structure may be adjusted during implementation, but the entire game must not be combined into one large widget or a single `CustomPainter`.

### Core Architectural Rules

- Game logic must not depend on Flutter Canvas.
- Rendering must not modify game state.
- User input must be passed to the controller.
- Line detection and pathfinding must be testable without the UI.
- The palette must be maintained in one place.
- Raster text rendering must be centralized.
- Character images must be loaded separately from game objects.
- The random ball generator must be replaceable in tests.
- The entire game must operate without network dependencies.

## 13. Automated Testing

### 13.1. Unit Tests

The following cases must be covered:

- Creating an empty board.
- Initial placement of five balls.
- Ball selection.
- Moving a ball to an empty cell.
- Blocking an inaccessible path.
- Horizontal lines.
- Vertical lines.
- Diagonal lines in both directions.
- Lines of four balls.
- Lines of five balls.
- Lines longer than five balls.
- Intersecting lines.
- Score calculation.
- Spawning new balls.
- Game-over detection.
- Preventing state changes after invalid actions.

### 13.2. UI Tests

Verify:

- Game startup.
- Ball selection.
- Moving a ball by clicking the destination cell.
- Score updates.
- Display of upcoming balls.
- Starting a new game.
- Preservation of game-board proportions when the window size changes.

### 13.3. Visual Tests

Add golden tests for the following basic states:

- Empty game board.
- Board containing several balls.
- Selected ball.
- Upcoming-ball preview.
- Score display.
- King and Pretender sprites.
- Game-over state.

Golden tests must detect changes to geometry, palette, and pixel rendering.

Also verify separately that programmatic graphics do not use anti-aliasing.

Do not require every platform to produce absolutely identical screenshots without environment configuration. Fix the virtual frame dimensions and rendering parameters for comparisons.

## 14. Development Stages

Each stage must be executed independently. Cursor must complete the stage, verify its acceptance criteria, and only then proceed to the next one.

Save implementation plans in the repository under `.cursor/plans/`. Create a separate file for each stage, using sequential names such as `stage_1.md`, `stage_2.md`, and so on.

### Stage 1. Research and Visual Specification

**Deliverable:** A document defining the geometry and visual rules.

Tasks:

- Study the available screenshots.
- Record the window dimensions.
- Determine the positions of the board and panels.
- Determine the visual dimensions of cells and balls.
- Describe the character sprites.
- Select a font.
- Define a palette of 16 colors.
- Prepare `docs/visual-reference.md`.

Acceptance criteria:

- The document contains references to the source images.
- Interface geometry is documented.
- The palette contains exactly 16 unique colors.
- The pixel-text enlargement method is defined.
- Permitted raster assets are identified.

### Stage 2. Application Skeleton

**Deliverable:** A runnable standalone application with the basic project structure.

Tasks:

- Set up the Flutter project.
- Create the module structure.
- Configure local execution.
- Implement the basic game screen.
- Define a 640 × 480 virtual area.
- Implement uniform scaling.

Acceptance criteria:

- The application runs locally.
- The virtual area preserves its proportions.
- The application requires no server.
- Tests run using the standard Flutter command.

### Stage 3. Pixel Text Rendering and Palette

**Deliverable:** A working `PixelTextRenderer` and a unified color palette.

Tasks:

- Add the selected font.
- Implement raster text rendering.
- Enlarge text without smoothing.
- Implement the 16-color palette.
- Create a test screen displaying text at different sizes.
- Implement color-count verification.

Acceptance criteria:

- Text has no anti-aliased outlines.
- Scaling uses nearest-neighbor interpolation.
- Text colors come from the shared palette.
- The test frame contains no more than 16 colors.

### Stage 4. Game Board Rendering

**Deliverable:** A 9 × 9 grid visually similar to the original.

Tasks:

- Render the background.
- Render the cells.
- Implement three-dimensional borders.
- Match the correct dimensions and spacing.
- Add cell selection.
- Compare the result with the references.

Acceptance criteria:

- The board contains 81 cells.
- The grid is sharp and pixelated.
- No ready-made grid images are used.
- All colors belong to the approved palette.

### Stage 5. Ball and Character Rendering

**Deliverable:** A complete visual scene containing balls and both characters.

Tasks:

- Create a programmatic ball renderer.
- Implement color variants.
- Prepare transparent images of the King and Pretender.
- Position the characters.
- Implement the upcoming-ball preview.
- Verify visual scale and sharpness.

Acceptance criteria:

- Balls do not use ready-made images.
- Only the two character sprites are used as character images.
- Character backgrounds are transparent.
- Scaling preserves pixel boundaries.
- All graphics use the shared palette.

### Stage 6. Game Logic

**Deliverable:** A working game without final visual polish.

Tasks:

- Implement board state.
- Implement ball selection.
- Implement pathfinding.
- Implement movement.
- Implement line detection.
- Implement ball removal.
- Implement score calculation.
- Implement new-ball generation.
- Implement game-over detection.

Acceptance criteria:

- Game rules are covered by unit tests.
- Invalid actions are handled safely.
- The generator supports deterministic tests.
- Game state does not depend on rendering.

### Stage 7. UI and Game Logic Integration

**Deliverable:** A complete playable game session.

Tasks:

- Connect the game controller to the screen.
- Implement user-input handling.
- Add the score and upcoming-ball sequence.
- Implement game start and restart.
- Add required messages.
- Ensure correct behavior when the game ends.

Acceptance criteria:

- The player can complete a full game session.
- The interface updates after every action.
- Logic and rendering remain consistent.
- UI tests pass.

### Stage 8. Visual Refinement

**Deliverable:** A final appearance closely matching the original.

Tasks:

- Compare application screenshots with the references.
- Adjust dimensions, spacing, and panel positions.
- Refine ball shapes.
- Verify color combinations.
- Check the font and scaling factors.
- Eliminate anti-aliasing.
- Verify proportions at different window sizes.

Acceptance criteria:

- The interface is visually recognizable as Gamos Color Lines (1992).
- No modern decorative elements are present.
- Pixel graphics are sharp.
- The palette contains no more than 16 colors.
- Golden tests pass.

### Stage 9. Final Verification and Documentation

**Deliverable:** A project ready for local execution.

Tasks:

- Run all tests.
- Verify startup from a clean state.
- Verify the absence of network dependencies.
- Verify high-score persistence.
- Document startup and controls.
- Document known limitations.
- Update the documentation and stage plans.

Acceptance criteria:

- The application builds successfully.
- The application runs autonomously.
- Tests pass.
- Instructions are up to date.
- No critical tasks remain incomplete.

## 15. Cursor Working Rules

1. Before each stage, read the general documentation and all previous stage plans.
2. Do not start the next stage until the current stage meets its acceptance criteria.
3. Do not rewrite the entire project when the existing implementation can be extended.
4. Do not replace the original visual style with modern design.
5. Do not use raster images for game objects except for the two character sprites.
6. Do not use more than 16 colors in game graphics.
7. Do not use anti-aliasing for text, balls, the grid, or scaling.
8. Do not add functionality that is outside the scope of the current stage.
9. Add automated tests alongside each implemented feature.
10. After each stage, report what was implemented, which tests were run, and which acceptance criteria were satisfied.
11. If a detail cannot be determined reliably from the references, document the uncertainty and choose the most conservative solution.
12. Do not claim complete visual fidelity until the application has been compared with the screenshots.

## 16. Out of Scope for the MVP

- Network multiplayer.
- Online leaderboards.
- User accounts.
- Advertising and in-app purchases.
- Server-side components.
- External gaming services.
- Arbitrary visual themes.
- Modern effects and anti-aliasing.
- Additional game modes unless their presence in the original is confirmed.

## 17. Final Success Criteria

The game is considered complete when the user can launch it locally, play a full game, and experience a visual presentation that convincingly reproduces Gamos Color Lines (1992).

Key indicators of completion:

- The game board and balls are drawn entirely programmatically.
- Only the King and Pretender images are used.
- The game screen is designed using a virtual resolution of 640 × 480.
- The palette contains exactly 16 predefined colors.
- All text is raster-based, pixelated, and enlarged without smoothing.
- Game rules are verified by automated tests.
- The interface preserves its proportions and pixel-art style.
- The project remains simple, standalone, and maintainable.

**Important technical note:** The requirement of “16 colors” should preferably be verified against the final raster of the game screen before scaling. This makes it possible to independently verify that text, highlights, and effects do not introduce additional shades. The character sprites must also be converted to the approved palette; otherwise, the original PNG files may contain hundreds or thousands of colors and violate the overall restriction.

