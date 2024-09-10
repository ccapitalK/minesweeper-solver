import std.array;
import std.exception;
import std.stdio;

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
                case '#':
                    *state.getCell(x, y) = -1;
                    break;
                default:
                    enforce(false);
                }
            }
        }
        return state;
    }
}

string getNextMask(BoardState state) {
    Appender!string builder;
    foreach (i, cell; state.cells) {
        if (i > 0 && i % state.w == 0) {
            builder.put('\n');
        }
        switch (cell) {
        case -1:
            builder.put('#');
            break;
        default:
            builder.put(cast(char)('0' + cell));
            break;
        }
    }
    return builder.data;
}

string solve(string data) {
    auto state = BoardState.fromSerialized(data);
    return state.getNextMask();
}

void main(string[] args) {
    foreach (filename; args[1 .. $]) {
        import std.file;

        writeln("START");
        auto data = cast(string) read(filename);
        writeln(solve(data));
        writeln("END");
    }
}
