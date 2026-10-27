# Color Lines Game Mechanics

Color Lines is a logic puzzle game in which the player moves colored balls around a grid to form lines of balls of the same color. The objective is to score as many points as possible, clear the board, and prevent it from filling up.

The classic version, known from 1990s games such as Gamos Color Lines for DOS, uses a 9 × 9 grid.

## 1. The Game Board

- The board consists of 81 cells arranged in 9 rows and 9 columns.
- Each cell can contain at most one ball.
- Balls come in different colors.
- Empty cells allow balls to move across the board.
- The player can see the next balls that are scheduled to appear.

At the beginning of the game, the board is partially filled with balls, while the remaining cells are empty.

## 2. The Main Gameplay Loop

1. Select a ball. The player clicks a ball to select it. The selected ball is visually highlighted.
2. Choose a destination cell. The player clicks an empty cell. If a path through empty cells exists, the ball moves to that cell.
3. Check for a line. After the move, the game checks whether a line of balls of the same color has been formed. If so, those balls are removed and the player earns points.
4. Spawn new balls. If no line is formed, new balls appear in empty cells. The next turn then begins.

Important rule: If the player's move creates a line and the balls are removed, new balls usually do not appear during that turn.

## 3. Line Formation Rules

A line is formed when five or more consecutive balls of the same color are aligned in one of four directions:

- Horizontal
- Vertical
- Diagonal downwards
- Diagonal upwards

The following rules apply:

- All balls in a line must have the same color.
- There must be no empty cells between consecutive balls.
- All balls belonging to the line are removed, not just the first five.
- A line can include both existing balls and the ball moved by the player.
- Lines containing six, seven, or more balls award more points than the minimum five-ball line.

In the classic version of Color Lines, horizontal, vertical, and both diagonal directions count as valid lines.

## 4. Moving Balls

A ball cannot jump over other balls. There must be a continuous path of empty cells between the starting cell and the destination cell. Diagonal movement is not allowed.

For example, a ball in the bottom-left corner can reach a cell in the top-right corner by following a path with several turns, provided the path is clear.

The game can implement this using a grid-based pathfinding algorithm, such as breadth-first search (BFS).

## 5. Spawning New Balls

In the original Gamos Color Lines 1992 version:

- Seven colors are used.
- Five balls of random colors are placed on the board at the beginning.
- Three new balls appear after an unsuccessful move.
- The colors and positions of the new balls are chosen randomly.
- The player can see the three upcoming balls in advance.

If the newly spawned balls accidentally form a line, that line is also removed and awards points. However, this does not grant an extra turn. An extra turn is effectively avoided only when the player creates a line with their own move, preventing the usual spawning of new balls.

## 6. Scoring and Game Over

The primary objective is to achieve the highest possible score.

- Removing a line awards points.
- Longer lines are more valuable than shorter ones.
- The cells freed by removing balls become available for future moves and new balls.
- The game ends when the board has no empty cells left for further gameplay.

The original game includes a high-score competition: the player attempts to beat the current record. Beating the record does not end the game; play continues until the board is filled.

## 7. Requirements for an Accurate Recreation

If you are implementing a faithful recreation of Gamos Color Lines 1992 for DOS, I recommend defining the following rules as explicit gameplay requirements.

| Parameter           | Rule                                           |
| ------------------- | ---------------------------------------------- |
| Board size          | 9 × 9 cells                                    |
| Number of colors    | 7                                              |
| Initial balls       | 5                                              |
| New balls per turn  | 3                                              |
| Minimum line length | 5 balls                                        |
| Line directions     | 4: horizontal, vertical, and two diagonals     |
| Ball movement       | Only through empty cells; no diagonal movement |
| Successful move     | The line is removed; no new balls spawn        |
| Unsuccessful move   | Three upcoming balls spawn                     |
| Game-over condition | The board is full                              |
| Objective           | Achieve the highest possible score             |

Important detail for an accurate recreation: If multiple lines intersect, the original game's behavior should be verified to determine whether all balls belonging to all intersecting lines are removed and exactly how the score is calculated. Do not automatically substitute the rules of a modern Color Lines variant.

## 8. squash and stretch

When a ball is selected, it begins bouncing continuously in place. The animation uses squash-and-stretch deformation: the ball stretches vertically while airborne, then squashes horizontally and expands vertically when it contacts the ground. The motion loops until the player selects a destination cell or selects another ball. The deformation must be clearly visible at low resolution and use hard pixel edges without antialiasing.

