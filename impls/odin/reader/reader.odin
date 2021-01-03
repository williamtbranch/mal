package reader

import "core:fmt"

import "../types"

Reader :: struct {
    tokens : [dynamic]string,
    position : int,
}

reader_next :: proc(reader : ^Reader) -> string {
    if reader.position >= len(reader.tokens) do return "";
    token := reader.tokens[reader.position];
    reader.position += 1;
    return token;
}

reader_peek :: proc(reader : ^Reader) -> string {
    if len(reader.tokens) <= reader.position do return "";
    return reader.tokens[reader.position];
}

tokenize :: proc(input : string) -> [dynamic]string {
    token_array : [dynamic]string;
    token, rest : string;
    
    token, rest = match_mal_token(input);

    for ; len(token) > 0; token, rest = match_mal_token(rest)  {
        append(&token_array, token);
    }

    return token_array;
}

read_string :: proc(input : string) -> types.MalType {
    reader := Reader{tokenize(input), 0};
    ast : types.MalType = read_form(&reader);
    return ast;
}

read_form :: proc(reader : ^Reader) -> types.MalType {

    switch reader_peek(reader) {
        case "(": return read_list(reader);
        case : return read_atom(reader);
    }

    return types.MalType{};
}

read_list :: proc(reader : ^Reader) -> types.MalList {
    list := types.MalList{};
    token: string;

    _ = reader_next(reader); // this should be ignoring a '('

    loop : for {
        token = reader_peek(reader);
        if len(token) == 0 {
            fmt.println("\nERROR: MISSING ')'");
            return list;
        }
        switch token {
            case ")": break loop;
            case : append(&list, read_form(reader));
        }
    }

    return list;
}

read_atom :: proc(reader : ^Reader) -> types.MalType {

    token := reader_next(reader);

    is_int, value := string_to_integer(token);
    if is_int do return value;

    symbol : types.symbol = types.symbol(token);
    return types.MalType(symbol);
}

string_to_integer :: proc(the_input : string) -> (is_int : bool, value : int) {

    if len(the_input) == 0 do return false, 0;

    input := the_input;
    sign := 1;
    if input[0] == '-' && len(input) > 1 {
        input = input[1:];
        sign = -1;
    }

    value = 0;
    power := len(input)-1;

    pow :: proc(x, expo : int) -> int {
        out := 1;
        for i in 0..expo-1 {
            out = out*x;
        }
        return out;
    }

    for digit in input {
        switch digit {
            case '0' : continue;
            case '1' : value += 1 * pow(10, power);
            case '2' : value += 2 * pow(10, power);
            case '3' : value += 3 * pow(10, power); 
            case '4' : value += 4 * pow(10, power); 
            case '5' : value += 5 * pow(10, power); 
            case '6' : value += 6 * pow(10, power); 
            case '7' : value += 7 * pow(10, power); 
            case '8' : value += 8 * pow(10, power); 
            case '9' : value += 9 * pow(10, power); 
            case: return false, 0;
        }
        power -= 1;
    }

    value = value*sign;

    //fmt.println("The value is", value);
    return true, value;
}

match_ignore :: proc(input : string) -> (token, the_rest : string) {

    //default values
    token = input;
    the_rest = "";

    loop: for char, index in input {
        switch char {
            case '\n' : continue;
            case ' ' : continue;
            case '\t' : continue;
            case ',' : continue;
            case '\v' : continue;
            case '\f' : continue;
            case '\r' : continue;
            case:{
                token = input[:index];
                the_rest = input[index:];
                break loop;
            }
        }
    }
    return;
}

match_splice_unquote :: proc(input : string) -> (token, the_rest : string) {
    if len(input) > 1 {
        if input[:2] == "~@"{
            token = input[:2];
            the_rest = input[2:];
            return;
        }
    }
    token = "";
    the_rest = input;
    return;
}

match_special :: proc(input : string) -> (token, the_rest : string) {
    //default
    token = "";
    the_rest = input;
    if len(input) > 0 {
        //new default assumes match until proven otherwise.
        token = input[:1];
        the_rest = input[1:];
        switch input[0] {
            case '[' : ;
            case ']' : ;
            case '{' : ;
            case '}' : ;
            case '(' : ;
            case ')' : ;
            case '\'' : ;
            case '`' : ;
            case '~' : ;
            case '^' : ;
            case '@' : ;
            case  : {
                token = "";
                the_rest = input;
            }
        }
    }
    return;
}

match_string :: proc(input : string) -> (token, the_rest : string) {
    //default
    token = "";
    the_rest = input;
    escape_mode := true;
    if len(input) > 0{
        if input[0] == '"'{
            loop: for char, index in input {
                switch char {
                    case '"' :{
                        if index > 0 && escape_mode == false{
                            token = input[:index+1];
                            the_rest = input[index+1:];
                            return;
                        }
                        escape_mode = false;
                        continue;
                    }
                    //consume escaped quotes.
                    case '\\' :{
                        if len(input) > index + 1{
                            if input[index+1] == '"'{
                                escape_mode = true;
                            }
                        }
                    }
                }
            }
            //error case of only openening quote must be accepted per spec.
            token = input;
            the_rest = "";
        }
    }
    return;
}

match_comment :: proc(input : string) -> (token, the_rest : string) {
    token = "";
    the_rest = input;
    if len(input) > 0{
        if input[0] == ';'{
            token = input;
            the_rest = "";
        }
    }
    return;
}

match_common :: proc(input : string) -> (token, the_rest : string) {
    token = "";
    the_rest = input;

    if len(input) < 1 do return;

    return_token :: proc(token, the_rest : string) -> string {return token};
    return_rest :: proc(token, the_rest : string) -> string {return the_rest};

    loop: for char, index in input {
        token = input[:index];
        the_rest = input[index:];
        switch {
            case len(return_token(match_ignore(the_rest))) > 0 : return;
            case char == '[' || char == ']' || char == '(' || char == ')' || char == '{' || char == '}':
                return;
            case char == '\'' || char == '\"' || char == '`' || char == ';': return;
        } 
    }
    
    token = input;
    the_rest = "";
    return;
}

match_mal_token :: proc(input : string) -> (token, the_rest : string) {
    // grab any whitespace in the beginning

    token = "";
    the_rest = input;

    ignored, not_ignored := match_ignore(input);

    if token, the_rest := match_splice_unquote(not_ignored); len(token) > 0 {
        return token, the_rest;
    }
    if token, the_rest := match_special(not_ignored); len(token) > 0 {
        return token, the_rest;
    }
    if token, the_rest := match_string(not_ignored); len(token) > 0 {
        return token, the_rest;
    }
    if token, the_rest := match_comment(not_ignored); len(token) > 0 {
        return token, the_rest;
    }
    if token, the_rest := match_common(not_ignored); len(token) > 0 {
        return token, the_rest;
    }

    the_rest = "\e[31;1mCan't find a valid mal token at start of string\e[0m";

    return;
}
