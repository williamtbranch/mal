package reader

match_ignored :: proc(input : string) -> (token, the_rest : string) {

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
            case len(return_token(match_ignored(the_rest))) > 0 : return;
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

    ignored, not_ignored := match_ignored(input);

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

// main :: proc() {

//     string_array : []string = {
//         "  ,,  \\",
//         ",  ,, ",
//         ",  hello world!",
//         "\t TAB there was a tab there but it was removed",
//         "\n NEWLINE",
//         "[]{}()'`~^@ SPECIAL CHARACTERS!!!",
//         "] closing bracket",
//         "{ open curly",
//         "} close curly",
//         "(def cat 5)",
//         ") closing paren",
//         "'quote ",
//         "` back tick",
//         "~ wave",
//         "^ carrot",
//         "@ at",
//         "+-*/ some math stuff",
//         "1542 numbers",
//         "3.14159 some pi",
//         "true boolean value",
//         "false the other boolean",
//         "3.14hello159 a weird number, but is still a mal token",
//         "3.14&hello@7 same here",
//         `"hello \" \"\" worl\"d\" and me too. this string is never ending`,
//         `" hel\n\tlo \" \"\" \\worl\"d\ same with this one`,
//         `"happy" go lucky. `,
//         `    "happier" go luckier`,
//         `  "happiest\"" go luckiest`,
//         `""`,
//         `"`,
//         "",
//         "~@ go fast. ",
//         "`~@ go fast.",
//         ";jageu'a comment goes on forever",
//         "euhakj space seperated",
//         "function( int a )",
//         "true false",
//     };

    // print_match :: proc(match_name, token : string) {
    //     fmt.print("\t"); 
    //     fmt.print(match_name);
    //     fmt.print(" \e[47;30m");
    //     fmt.print(token);
    //     fmt.print("\e[0m");
    //     fmt.println();
    // }

    // for test, index in string_array {
       
    //     token, the_rest := match_mal_token(test);
    //     fmt.print("case ");
    //     fmt.print(index);
    //     fmt.print(": \e[42;30m");
    //     fmt.print(token);
    //     fmt.print("\e[0m");
    //     fmt.print(the_rest);
    //     fmt.println();

        /*
        if token, the_rest := match_ignored(test); len(token) > 0 {
            print_match("match_ignored", token);
            continue;
        }
        if token, the_rest := match_splice_unquote(test); len(token) > 0 {
            print_match("match_splice_unquote", token);
        }
        if token, the_rest := match_special(test); len(token) > 0 {
            print_match("match_special", token);
        }
        if token, the_rest := match_string(test); len(token) > 0 {
            print_match("match_string ", token);
        }
        if token, the_rest := match_comment(test); len(token) > 0 {
            print_match("match_comment", token);
        }
        if token, the_rest := match_common(test); len(token) > 0 {
            print_match("match_common ", token);
        }
        */

    //}
//}