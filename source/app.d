import std.stdio;
import solve;

void main(string[] args) {
    foreach (filename; args[1 .. $]) {
        import std.file;

        writeln("START");
        auto data = cast(string) read(filename);
        writef("%s", solve.solve(data));
        writeln("END");
    }
}
