import std.array;
import std.exception;
import std.typecons;

const int EMPTY = -1;

alias Point = Tuple!(size_t, size_t);

class BoardState {
    size_t w;
    size_t h;
    int[] cells;

    int* getCell(ulong x, ulong y) => &cells[y * w + x];

    this(size_t w, size_t h) {
        this.w = w;
        this.h = h;
        cells.length = w * h;
    }

    static BoardState fromSerialized(string data) {
        auto lines = data.split('\n');
        if (lines.length > 0 && lines[$ - 1] == "") {
            lines.length -= 1;
        }
        if (lines.length == 0) {
            return new BoardState(0, 0);
        }
        auto state = new BoardState(lines[0].length, lines.length);
        foreach (y, line; lines) {
            enforce(line.length == state.w);
            foreach (x, c; line) {
                switch (c) {
                case '0': .. case '9':
                    *state.getCell(x, y) = c - '0';
                    break;
                case '.':
                    *state.getCell(x, y) = EMPTY;
                    break;
                default:
                    enforce(false, "Unknown character " ~ c);
                }
            }
        }
        return state;
    }
}
