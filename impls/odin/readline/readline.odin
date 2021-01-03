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

View :: struct {
    prompt: string,
    line: string,
    pos: int //minumum value is 0
}

H_command :: enum {up, down};

Line_Reader :: struct {
    original_termio: termios,
    rune_reader: io.Rune_Reader, // change to byte reader instead?
    history : [dynamic]string,
    using view: View,
    history_pos : int,

}

line_reader_init :: proc(line_reader_ptr : ^Line_Reader) {

    line_reader_ptr.original_termio = termios{};
    tcgetattr(int(os.stdin), &line_reader_ptr.original_termio);

    line_reader_ptr.history = make([dynamic]string);
    line_reader_ptr.view.pos = 0;
    line_reader_ptr.view.line = "";
    line_reader_ptr.view.prompt = "user> ";

    raw := line_reader_ptr.original_termio;

    raw.c_lflag &= ~(u32(0o0000012));
    tcsetattr(int(os.stdin), 2, &raw);

    line_reader_ptr.rune_reader = io.Rune_Reader{os.stream_from_handle(os.stdin)};
    line_reader_ptr.history_pos = 0;
}

view_refresh :: proc(view_ptr: ^View){
    view_ptr.line = "";
    view_ptr.pos = 0;
}

view_move_right :: proc(view_ptr: ^View){
    view_ptr.pos +=1;
    if view_ptr.pos > len(view_ptr.line) do view_ptr.pos -= 1;
}

view_move_left :: proc(view_ptr: ^View){
    view_ptr.pos -=1;
    if view_ptr.pos < 0 do view_ptr.pos = 0;
}

view_add_char :: proc(view_ptr: ^View, character: byte){
    index := view_ptr.pos;

    a, b, c: string;
    a = view_ptr.line[0:index];
    b = string([]byte{character});
    c = view_ptr.line[index:];

    s : []string = {a, b, c};
    view_ptr.line = strings.concatenate(s);
    view_ptr.pos += 1;

}

view_set_line :: proc(view_ptr: ^View, input: string){
    view_ptr.line = input;
    view_ptr.pos = len(view_ptr.line);
}

view_remove_char :: proc(view_ptr: ^View){
    index := view_ptr.pos;
    if view_ptr.pos >= len(view_ptr.line ) do return;
    a, b: string;
    a = view_ptr.line[0:index];
    b = view_ptr.line[index+1:];

    s : []string = {a, b};
    view_ptr.line = strings.concatenate(s);
}

line_reader_cleanup :: proc(line_reader_ptr : ^Line_Reader) {
    original := line_reader_ptr.original_termio;
    tcsetattr(int(os.stdin), 2, &original);
    delete(line_reader_ptr.history);
}

print_history :: proc(line_reader: ^Line_Reader) {

    fmt.println("");
    fmt.println("History is:");
    for line, index in line_reader.history {
        fmt.println(line);
    }
    fmt.println("");
    return;
}

render_view :: proc(view: View){
    fmt.print("\e[1G"); //move to column 1 
    fmt.print("\e[0K"); //clear from cursor to end of line
    fmt.print(view.prompt);
    fmt.print(view.line);
    fmt.print("\e[1G"); //move to column 1 
    //set cursor
    for i in 1..len(view.prompt) + view.pos{
        fmt.print("\e[1C");
    }
}

history_select :: proc(command: H_command, line_reader: ^Line_Reader){
    history_length := len(line_reader.history);
    if command == H_command.up {
        if line_reader.history_pos == history_length - 1{
            line_reader.history[line_reader.history_pos] = line_reader.line;
        }
        line_reader.history_pos -= 1;
        if line_reader.history_pos < 0 do line_reader.history_pos = 0;
    }


    if command == H_command.down {
        line_reader.history_pos += 1;
        if line_reader.history_pos == history_length do line_reader.history_pos = history_length - 1;
    }
    view_set_line(&line_reader.view, line_reader.history[line_reader.history_pos]);
    render_view(line_reader.view);

}

readline :: proc(line_reader: ^Line_Reader) -> (output : string, exit : bool) {

    left : []byte = {27,91,68};
    right : []byte = {27,91,67};
    append(&line_reader.history, output);
    line_reader.history_pos = len(line_reader.history)- 1;
//    fmt.println ("history pos:");//delete me
//    fmt.println (history_pos);//delete me
    view_refresh(&line_reader.view);


    loop : for {
        render_view (line_reader.view);

        b, size, err := io.read_rune(line_reader.rune_reader);

        switch b { 
            case 3, 4:{
                return output, true;
            } 
            case 10: {
                if line_reader.history_pos != len(line_reader.history) -1{
                    output = line_reader.history[line_reader.history_pos];
                }
                line_reader.history[len(line_reader.history) - 1] = line_reader.line;
                output = line_reader.line;
                return output, false;
            }
            case 27: { // ANSI escape sequence
                b1, _, _ := io.read_rune(line_reader.rune_reader);
                b2, _, _ := io.read_rune(line_reader.rune_reader);
                switch b2 {
                    case 65: { // up
                        history_select(H_command.up, line_reader);
                    }

                    case 66: { // down
                        history_select(H_command.down, line_reader);
                    }
                    case 67: { // move right
                        view_move_right(&line_reader.view);
                    }
                    case 68: { // move left
                        view_move_left(&line_reader.view);
                    }
                    case 51: { // forward delete 
                        // TODO: move up in history
                        view_remove_char(&line_reader.view);
                        io.read_rune(line_reader.rune_reader);
                    }
                }
            }
            case 127: { // 'delete - actually backspace key'
                if line_reader.pos > 0 {
                    view_move_left(&line_reader.view);
                    view_remove_char(&line_reader.view);
                }
            }
            case: {
                //default
                view_add_char(&line_reader.view, byte(b));
            }
        }
    }
}