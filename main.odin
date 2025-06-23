package main

import "core:bufio"
import "core:fmt"
import os "core:os"
import strings "core:strings"
import lex "lexer"
import "lox"
import "vm"

main :: proc() {
	v := vm.vm_new()
	defer v->free()

	if len(os.args) == 1 {
		repl(v)
	} else if len(os.args) == 2 {
		run_file(os.args[1], v)
	} else {
		fmt.eprintln("Usage: olox [path]")
		os.exit(1)
	}
}

run_file :: proc(filename: string, v: ^vm.Vm) {
	if content, ok := os.read_entire_file(filename); ok {
		defer delete(content)
		result := v->interpret(content)

		if result == .INTERPRET_COMPILE_ERROR do os.exit(1)
		if result == .INTERPRET_RUNTIME_ERROR do os.exit(1)
	} else {
		fmt.eprintfln("Could not open file \"%s\".", filename)
		os.exit(1)
	}
}

repl :: proc(v: ^vm.Vm) {
	for {
		fmt.print("> ")

		reader: bufio.Reader
		stream := os.stream_from_handle(os.stdin)
		bufio.reader_init(&reader, stream)

		line, err := bufio.reader_read_string(&reader, '\n')
		if err != nil {
			if err == .EOF {
				fmt.eprintln("Bye!")
			} else {
				fmt.eprintln("Error reading input: ", err)
			}

			os.exit(1)
		}

		buffer := transmute([]byte)strings.trim_right(line, "\r\n")
		v->interpret(buffer)
	}
}
