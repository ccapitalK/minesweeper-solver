import std.array;
import std.algorithm;
import std.exception;
import std.stdio;

import util;

struct Constraint {
    Point[] points;
    int count;

    void checkInvariants() const {
        enforce(points.isSorted());
    }
}

class Solver {
    BoardState state;
    Constraint[] constraints;
    size_t[][Point] constraintsByPoints;
    bool[Point] known;

    void registerConstraint(Constraint c) {
        size_t idx = constraints.length;
        constraints ~= c;
        foreach (p; c.points) {
            constraintsByPoints[p] ~= idx;
        }
    }

    private void initializeBaseConstraints() {
        foreach (int x; 0 .. cast(int) state.w) {
            foreach (int y; 0 .. cast(int) state.h) {
                auto cell = *state.getCell(x, y);
                if (cell <= 0) {
                    continue;
                }
                Constraint c;
                c.count = cell;
                foreach (int dx; -1 .. 2) {
                    foreach (int dy; -1 .. 2) {
                        if (dx == 0 && dy == 0) {
                            continue;
                        }
                        auto cx = x + dx;
                        auto cy = y + dy;
                        if (cx < 0 || cy < 0 || cx >= state.w || cy >= state.h) {
                            continue;
                        }
                        auto neighbour = *state.getCell(cx, cy);
                        if (neighbour == EMPTY) {
                            c.points ~= Point(cx, cy);
                        }
                        c.checkInvariants();
                    }
                }
                registerConstraint(c);
            }
        }
    }

    private bool solved = false;
    void solve() {
        enforce(!solved);
        initializeBaseConstraints();
        foreach (c; constraints) {
            if (c.points.length != c.count) {
                continue;
            }
            foreach (p; c.points) {
                known[p] = true;
            }
        }
        solved = true;
    }
}

string getNextMask(Solver solver) {
    auto state = solver.state;
    Appender!string builder;
    foreach (y; 0 .. state.h) {
        foreach (x; 0 .. state.w) {
            auto cell = *state.getCell(x, y);
            switch (cell) {
            case EMPTY:
                builder.put(((Point(x, y) in solver.known) != null) ? '#' : '.');
                break;
            default:
                builder.put(cast(char)('0' + cell));
                break;
            }
        }
        builder.put('\n');
    }
    return builder.data;
}

string solve(string data) {
    auto state = BoardState.fromSerialized(data);
    auto solver = new Solver;
    solver.state = state;
    solver.solve();
    return solver.getNextMask();
}

unittest {
    // Basic single constraint tests
    assert(solve(".....\n.....\n....3\n") == ".....\n...##\n...#3\n");
    assert(solve(".....\n.....\n...32\n") == ".....\n...##\n...32\n");
    assert(solve("234..\n.....\n...32\n") == "234#.\n#####\n...32\n");

    // Constraint subset tests
    // assert(solve(".....\n..1..\n11111\n") == ".###.\n..1..\n11111\n");
}
