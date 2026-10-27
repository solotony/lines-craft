# Gamos Color Lines (1992) — Animation and Sound Summary

## 1. Movement Trail

- The ball's route is displayed as **footprints** along the cells of the game board.
- The footprints show the path from the starting position to the destination.
- As the ball moves, the footprints it has already passed over gradually **fade away**.
- The untraversed portion of the route remains visible.
- Once the movement is complete, all remaining footprints disappear.

## 2. Ball Animation

- After being selected, the ball starts bouncing in place.
- When it lands, the ball compresses elastically, like a rubber ball, and then returns to its original shape.
- During movement, the ball continues bouncing, combining horizontal movement with vertical bouncing animation.
- After reaching its destination, the ball stops bouncing if it is no longer selected.

## 3. Sound Effects

| Event                    | Sound                                                        |
| ------------------------ | ------------------------------------------------------------ |
| Initial screen           | A melody plays while the title screen is displayed.          |
| Ball selection           | The sound of a bouncing ball.                                |
| Ball landing             | A short sound of the ball hitting the ground.                |
| Ball movement            | Repeated impact sounds synchronized with the ball's bounces. |
| Beating the King's score | A triumphant trumpet fanfare.                                |

## 4. Important Implementation Details

- **Synchronization:** The landing sound coincides with the ball's visual compression.
- **Physics:** The ball does not slide across the board; it bounces elastically from cell to cell.
- **Footprints:** The footprints gradually fade away behind the moving ball.
- **Fanfare:** The fanfare plays when the player's score exceeds the King's score, not every time additional points are earned afterward.
- **Separate audio assets:** The title-screen melody and victory fanfare must be stored as separate sound resources.

This specification describes the observed behavior to reproduce in a recreation of Gamos Color Lines (1992). The exact original audio recordings and musical notes have not yet been identified.

Clarify the movement sequenceSeparate observed facts from requirements