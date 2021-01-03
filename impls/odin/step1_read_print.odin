package step0

import "core:fmt"

import "readline"
import "reader"
import "types"
import "printer"

READ :: proc(input : string) -> types.MalType {
	ast := reader.read_string(input);
	return ast;
}

EVAL :: proc(input : types.MalType) -> types.MalType {
	return input;
}

PRINT :: proc(input : types.MalType) {

	fmt.println();

	output := printer.pr_str(input);
	if len(output) == 0 do return;

	fmt.print(output);
	fmt.println();
}

rep :: proc(input : string) {
	PRINT( EVAL ( READ (input)));
}

main :: proc() {
	using readline;

	line_reader := Line_Reader{};
	line_reader_init(&line_reader);
	defer line_reader_cleanup(&line_reader);

	input : string;
	for {

		input, exit := readline(&line_reader);
		if exit {
			fmt.println();
			break;
		} 

		rep(input);
	}
}