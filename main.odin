package main

import "lox"
import "vm"
import "core:mem"
import "core:fmt"
import lex "lexer"
import "core:bufio"
import os "core:os"
import strings "core:strings"
import vmem "core:mem/virtual"

main :: proc() {
	arena : vmem.Arena
	err := vmem.arena_init_growing(&arena)
	assert(err == nil, "Failed to initialize arena allocator")
	context.allocator = vmem.arena_allocator(&arena)

	ta : mem.Tracking_Allocator
	mem.tracking_allocator_init(&ta, context.allocator)
	context.allocator = mem.tracking_allocator(&ta)

	defer {
		if len(ta.allocation_map) > 0 {
			for _, leak in ta.allocation_map {
				fmt.eprintf("- Leaked %v bytes @ %v\n", leak.size, leak.location)
			}
		}

		mem.tracking_allocator_destroy(&ta)
	}

	defer {
		free_all(context.allocator)
		vmem.arena_destroy(&arena)
	}

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
	defer free_all(context.temp_allocator)

	if content, ok := os.read_entire_file(filename, context.temp_allocator); ok {
		result := v->interpret(content)

		if result == .INTERPRET_COMPILE_ERROR do os.exit(1)
		if result == .INTERPRET_RUNTIME_ERROR do os.exit(1)
	} else {
		fmt.eprintfln("Could not open file \"%s\".", filename)
		os.exit(1)
	}
}

repl :: proc(v: ^vm.Vm) {
	reader: bufio.Reader
	stream := os.stream_from_handle(os.stdin)
	bufio.reader_init(&reader, stream)

	for {
		fmt.print("> ")

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
