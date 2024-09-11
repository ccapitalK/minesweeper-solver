# Minesweeper solver

A simple command line solver for minesweeper, that solves by exhaustively searching the consequences of constraints. Mostly done as a quick experiment.

## Input format

Ascii art grid, one character = one tile

- `.` = Empty cell
- `0-9` = Expanded tile with this many neighbours known to be mines

## Output format

Same grid as input, with some Empty Cells replaced as follows

- `$` = cell that is known to not contain a mine
- `#` = cell that is known to contain a mine

## How to run

- Install dlang toolchain (dub, dmd, visit https://dlang.org/ for more info)
- `dub build`
- `./minesweeper-solver PATH_TO_INPUT_FILE`

## Output when run on example_input.txt

```
START
Solved after 150 constraints searched
......$#101$.
......$1101#.
......$10012.
....#$#10001.
..$$#3110001.
..1111000001.
..1000000013.
..100000112#.
..1000001#$$.
..2100124$...
..#2102###...
..$#424#.....
...###$#.....
END
```
