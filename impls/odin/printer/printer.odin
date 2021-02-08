package printer

import "core:strings"
import "core:fmt"

import "../types"

int_to_string :: proc(the_input : int) -> string {

    output, digit : string;
    is_negative := false;
    r : int;

    input := the_input; // idk why odin makes you do this. "the_input" is already a copy, why can't I change a copy    

    if input < 0 {
        is_negative = true;
        input = -input;
    }

    for input >= 0 {
        r = input % 10;
        input = input/10;

        switch r {
            case 0: digit = "0";
            case 1: digit = "1";
            case 2: digit = "2";
            case 3: digit = "3";
            case 4: digit = "4";
            case 5: digit = "5";
            case 6: digit = "6";
            case 7: digit = "7";
            case 8: digit = "8";
            case 9: digit = "9";
        }

        output = strings.concatenate([]string{digit, output});
        if input == 0 do break;
    }

    if is_negative do output = strings.concatenate([]string{"-", output});

    return output;
}

pr_str :: proc(ast : types.MalType) -> string {
    //fmt.println(ast);
    switch t in ast {
        case int : return int_to_string(ast.(int)); 
        case types.symbol: return string(ast.(types.symbol));
        case string : return "string";
        case bool : return "bool";
        case types.MalList: {

            output, item_str : string;
            output = "(";
            for item, index in ast.(types.MalList) {
                item_str = pr_str(item);
                if index < len(ast.(types.MalList)) - 1 {
                    output = strings.concatenate([]string{output, item_str, " "});
                } else do output = strings.concatenate([]string{output, item_str});
            }
            output = strings.concatenate([]string{output, ")"});

            return output;
        }
        case types.nil_type : return "nil";
    }
    return "Somehow the switch doesn't handle one of the types.MalType (in printer.odin pr_str)";
}