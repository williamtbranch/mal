package step0

import "core:fmt"

import "readline"
import "reader"
import "types"
import "printer"

// Environment :: map[string]proc(args: types.MalType) -> (value : types.MalType, error : bool);
// EnvironmentProc :: proc(args: types.MalType) -> (value : types.MalType, arror : bool);

Environment :: map[types.symbol]proc(arg : types.MalType) -> types.MalType;
env : Environment = {
	"+" = proc(arg: types.MalType) -> types.MalType 
		where type_of(types.MalType) == types.MalList,
			len(arg.(types.MalList)) == 2,
			type_of(arg.(types.MalList)[0]) == int,
			type_of(arg.(types.MalList)[1]) == int
	{
		args : types.MalList = arg.(types.MalList);
		a, b : int = args[0].(int), args[1].(int);
        return a + b;
	},
	"-" = proc(arg: types.MalType) -> types.MalType 
		where type_of(types.MalType) == types.MalList,
			len(arg.(types.MalList)) == 2,
			type_of(arg.(types.MalList)[0]) == int,
			type_of(arg.(types.MalList)[1]) == int
	{
		args : types.MalList = arg.(types.MalList);
		a, b : int = args[0].(int), args[1].(int);
        return a - b;
	},
	"*" = proc(arg: types.MalType) -> types.MalType 
		where type_of(types.MalType) == types.MalList,
			len(arg.(types.MalList)) == 2,
			type_of(arg.(types.MalList)[0]) == int,
			type_of(arg.(types.MalList)[1]) == int
	{
		args : types.MalList = arg.(types.MalList);
		a, b : int = args[0].(int), args[1].(int);
        return a * b;
	},
	"/" = proc(arg: types.MalType) -> types.MalType 
		where type_of(types.MalType) == types.MalList,
			len(arg.(types.MalList)) == 2,
			type_of(arg.(types.MalList)[0]) == int,
			type_of(arg.(types.MalList)[1]) == int
	{
		args : types.MalList = arg.(types.MalList);
		a, b : int = args[0].(int), args[1].(int);
        return int(a / b);
	},
};

READ :: proc(input : string) -> types.MalType {
	ast := reader.read_string(input);
	return ast;
}

EVAL :: proc(input : types.MalType, env : Environment) -> types.MalType {
	return input;
}

PRINT :: proc(input : types.MalType) {

	fmt.println();

	output := printer.pr_str(input);
	if len(output) == 0 do return;

	fmt.print(output);
	fmt.println();
}

rep :: proc(input : string, env : Environment) {
	PRINT( EVAL ( READ (input), env));
}

main :: proc() {
	using readline;

	line_reader := Line_Reader{};
	line_reader_init(&line_reader);
	defer line_reader_cleanup(&line_reader);

	args : types.MalList = types.MalList{1, 2};
	addop := env["+"];
	result := addop(args);
	fmt.println(result);

	for {

		input, exit := readline(&line_reader);
		if exit {
			fmt.println();
			break;
		} 

		rep(input, env);
	}
}