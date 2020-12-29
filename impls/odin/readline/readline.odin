package readline 

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"

foreign import libc "system:c"

foreign libc {
    //atexit    :: proc(procedure : ^proc()) ---;
    tcgetattr :: proc(fd : int, t : ^termios) -> int ---;
    tcsetattr :: proc(fd : int, optional : int, t : ^termios) -> int ---;
}

termios :: struct {
    c_iflag : u32,
    c_oflag : u32,
    c_cflag : u32,
    c_lflag : u32,
    c_cc    : []u8,
};

Line_Reader :: struct {
    original_termio: termios,
    rune_reader: io.Rune_Reader, // change to byte reader instead?
    history : [dynamic]string,
    history_pos : int,
}

line_reader_init :: proc(line_reader_ptr : ^Line_Reader) {

    line_reader_ptr.original_termio = termios{};
    tcgetattr(int(os.stdin), &line_reader_ptr.original_termio);

    raw := line_reader_ptr.original_termio;

    raw.c_lflag &= ~(u32(0o0000012));
    tcsetattr(int(os.stdin), 2, &raw);

    line_reader_ptr.rune_reader = io.Rune_Reader{os.stream_from_handle(os.stdin)};
}

line_reader_cleanup :: proc(line_reader_ptr : ^Line_Reader) {
    original := line_reader_ptr.original_termio;
    tcsetattr(int(os.stdin), 2, &original);
}

add_to_string :: proc(char: byte, s: string, i : int = -1) -> string {
    index := i;
    if index > len(s) do index = len(s);
    if index < 0 do index = len(s);

    a, b, c: string;
    a = s[0:index];
    b = string([]byte{char});
    c = s[index:];

    s : []string = {a, b, c};
    return strings.concatenate(s);
}

remove_from_string :: proc(s: string, i : int = -1) -> string {
    index := i;
    if index >= len(s) do return s;
    if index < 0 do return string(s[0:len(s)-1]);

    a, b: string;
    a = s[0:index];
    b = s[index+1:];

    s : []string = {a, b};
    return strings.concatenate(s);
}

readline :: proc(line_reader: Line_Reader) -> (output : string, exit : bool) {

    left : []byte = {27,91,68};
    right : []byte = {27,91,67};

    pos : int = 0;

    loop : for {

        b, size, err := io.read_rune(line_reader.rune_reader);

        switch b { 
            case 3, 4:{
                return output, true;
            } 
            case 10: {
                //append(line_reader.history, output); // not working
                return output, false;
            }
            case 27: { // ANSI escape sequence
                b1, _, _ := io.read_rune(line_reader.rune_reader);
                b2, _, _ := io.read_rune(line_reader.rune_reader);
                switch b2 {
                    case 65: { // up
                        // TODO: move up in history

                        // update line_reader.history_pos
                        // move left pos times
                        // erase to end of line
                        // print string from history
                    }
                    case 66: { // down
                        // TODO: move down in history

                        // update line_reader.history_pos
                        // move left pos times
                        // erase to end of line
                        // print string from history
                    }
                    case 67: { // move right
                        if pos < len(output) {
                            fmt.print(string(right));
                            pos = pos +1;
                        }
                    }
                    case 68: { // move left
                        if pos > 0 {
                            fmt.print(string(left));
                            pos = pos -1;
                        }
                    }
                    case 51: { // forward delete 
                        // TODO: move up in history
                        output = remove_from_string(output, pos);
                        io.read_rune(line_reader.rune_reader);
                        fmt.print("\e[s"); // save cursor position
                        fmt.print("\e[K"); // erases line after cursor
                        fmt.print(output[pos:]); // print from pos to end
                        fmt.print("\e[u"); // restore cursor pos
                    }
                }
            }
            case 127: { // 'delete - actually backspace key'
                if pos > 0 {
                    output = remove_from_string(output, pos-1);
                    pos = pos -1;
                    fmt.print(string(left));
                    fmt.print("\e[s"); // save cursor position
                    fmt.print("\e[K"); // erases line after cursor
                    fmt.print(output[pos:]); // print from pos to end
                    fmt.print("\e[u"); // restore cursor pos
                }
            }
            case: {
                output = add_to_string(byte(b), output, pos);
                
                fmt.print("\e[s"); // save cursor position
                fmt.print("\e[K"); // erases line after cursor
                fmt.print(output[pos:]); // print from pos to end
                fmt.print("\e[u"); // restore cursor pos
                fmt.print(string(right)); // move right one
                pos = pos +1;
            }
        }
    }
}