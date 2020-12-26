package main

import "core:fmt"
import "core:bufio"
import "core:io"
import "core:os"

reader : bufio.Reader = bufio.Reader{};
writer : bufio.Writer = bufio.Writer{};

READ :: proc(input : string) -> string {
	return input;
}

 
EVAL :: proc(input : string) -> string {
	return input;
}

PRINT :: proc(input : string) {
	bufio.writer_write_string(&writer, input);
	bufio.writer_flush(&writer);
}

rep :: proc(input : string) {
	PRINT( EVAL ( READ (input)));
}

main :: proc() {

	bufio.reader_init(&reader, io.Reader{os.stream_from_handle(os.stdout)});
	bufio.writer_init(&writer, io.Writer{os.stream_from_handle(os.stdout)});

	input : string;
	for {
		PRINT("user> ");

		input, _ := bufio.reader_read_string(&reader, '\n');

		rep(input);
	}
}

