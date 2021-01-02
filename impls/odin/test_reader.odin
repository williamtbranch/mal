package test

import "core:fmt"
import "reader"

main :: proc() {

    string_array : []string = {
        "  ,,  \\",
        ",  ,, ",
        ",  hello world!",
        "\t TAB there was a tab there but it was removed",
        "\n NEWLINE",
        "[]{}()'`~^@ SPECIAL CHARACTERS!!!",
        "] closing bracket",
        "{ open curly",
        "} close curly",
        "(def cat 5)",
        ") closing paren",
        "'quote ",
        "` back tick",
        "~ wave",
        "^ carrot",
        "@ at",
        "+-*/ some math stuff",
        "1542 numbers",
        "3.14159 some pi",
        "true boolean value",
        "false the other boolean",
        "3.14hello159 a weird number, but is still a mal token",
        "3.14&hello@7 same here",
        `"hello \" \"\" worl\"d\" and me too. this string is never ending`,
        `" hel\n\tlo \" \"\" \\worl\"d\ same with this one`,
        `"happy" go lucky. `,
        `    "happier" go luckier`,
        `  "happiest\"" go luckiest`,
        `""`,
        `"`,
        "",
        "~@ go fast. ",
        "`~@ go fast.",
        ";jageu'a comment goes on forever",
        "euhakj space seperated",
        "function( int a )",
        "true false",
    };

    print_match :: proc(match_name, token : string) {
        fmt.print("\t"); 
        fmt.print(match_name);
        fmt.print(" \e[47;30m");
        fmt.print(token);
        fmt.print("\e[0m");
        fmt.println();
    }

    for test, index in string_array {
       
        token, the_rest := reader.match_mal_token(test);
        fmt.print("case ");
        fmt.print(index);
        fmt.print(": \e[42;30m");
        fmt.print(token);
        fmt.print("\e[0m");
        fmt.print(the_rest);
        fmt.println();

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

    }
}