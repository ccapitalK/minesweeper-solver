import std.array;
import std.algorithm;
import std.exception;
import std.stdio;

import util;

enum Known {
    mine,
    safe,
}

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
    Known[Point] known;
    bool[const(Point)[]] seen;

    bool registerConstraint(Constraint c) {
        if (c.points in seen) {
            return false;
        }
        size_t idx = constraints.length;
        constraints ~= c;
        foreach (p; c.points) {
            constraintsByPoints[p] ~= idx;
        }
        seen[c.points.idup] = true;
        return true;
    }

    private void initializeBaseConstraints() {
        foreach (int x; 0 .. cast(int) state.w) {
            foreach (int y; 0 .. cast(int) state.h) {
                auto cell = *state.getCell(x, y);
                if (cell < 0) {
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

    private void tryGenerate(ref Constraint a, ref Constraint b) {
        enforce(a.points.length > b.points.length);
        if (!a.points.isSuperset(b.points)) {
            return;
        }
        enforce(a.count >= b.count);
        size_t bPos = 0;
        Constraint newConstraint;
        foreach(i; 0 .. a.points.length) {
            if (bPos < b.points.length && a.points[i] == b.points[bPos]) {
                ++bPos;
            } else {
                newConstraint.points ~= a.points[i];
            }
        }
        newConstraint.count = a.count - b.count;
        registerConstraint(newConstraint);
    }

    private void iterativeSolve() {
        size_t i = 1;
        while (i < constraints.length) {
            auto length1 = constraints[i].points.length;
            if (length1 > 1 && constraints[i].count == length1) {
                foreach (const p; constraints[i].points) {
                    Constraint c;
                    c.points ~= p;
                    c.count = 1;
                    registerConstraint(c);
                }
                ++i;
                continue;
            }
            size_t[] idxs = [];
            foreach (p; constraints[i].points) {
                idxs = idxs ~ constraintsByPoints[p];
            }
            idxs.sort();
            foreach (j; idxs.uniq()) {
                if (j >= i) {
                    break;
                }
                auto length2 = constraints[j].points.length;
                if (length1 > length2) {
                    tryGenerate(constraints[i], constraints[j]);
                } else if (length2 > length1) {
                    tryGenerate(constraints[j], constraints[i]);
                }
            }
            ++i;
        }
    }

    private void populateKnown() {
        foreach (c; constraints) {
            Known value;
            if (c.count == 0) {
                value = Known.safe;
            } else if (c.points.length == c.count) {
                value = Known.mine;
            } else {
                continue;
            }
            foreach (p; c.points) {
                known[p] = value;
            }
        }
    }

    private bool solved = false;
    void solve() {
        enforce(!solved);
        initializeBaseConstraints();
        iterativeSolve();
        populateKnown();
        // writeln("Solved after ", constraints.length, " constraints searched");
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
                auto known = Point(x, y) in solver.known;
                char c = (known != null) ? (*known == Known.safe ? '$' : '#') : '.';
                builder.put(c);
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

// Note: assumes no duplicates
/// a is superset of b
bool isSuperset(Point[] a, Point[] b) {
    size_t i = 0;
    size_t j = 0;
    while (i < a.length && j < b.length) {
        if (a[i] == b[j]) {
            ++i;
            ++j;
        } else if (a[i] > b[j]) {
            return false;
        } else if (a[i] < b[j]) {
            ++i;
        }
    }
    return j == b.length;
}

unittest {
    Point p(int x, int y) => Point(x, y);
    assert(isSuperset([p(0, 0)], []));
    assert(isSuperset([p(0, 0)], [p(0, 0)]));
    assert(!isSuperset([p(1, 0)], [p(0, 0)]));
    assert(!isSuperset([p(0, 0)], [p(1, 0)]));
    assert(!isSuperset([p(0, 0)], [p(1, 0)]));
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
    assert(solve("234..\n.....\n...32\n") == "234#.\n#####\n..$32\n");
    assert(solve(".....\n..0..\n.....\n") == ".$$$.\n.$0$.\n.$$$.\n");

    // Constraint subset tests
    assert(solve(".....\n..1..\n11111\n") == ".$$$.\n..1..\n11111\n");
    assert(solve(".....\n.....\n11211\n") == ".....\n$#$#$\n11211\n");
    assert(solve(".102.\n.424.\n.....\n") == ".102#\n.424#\n###$#\n");
}
