package step0

import "core:fmt"

import "readline"

READ :: proc(input : string) -> string {
	return input;
}

EVAL :: proc(input : string) -> string {
	return input;
}

PRINT :: proc(input : string) {

	fmt.println();
	if len(input) == 0 do return;

	fmt.print(input);
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

