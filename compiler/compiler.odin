package compiler

import lex "../lexer"
import "core:fmt"

compiler_proc :: struct {
	compile: proc(c: ^Compiler),
	free : proc(c: ^Compiler),
}

Compiler :: struct {
	lexer:               ^lex.Lexer,
	using compiler_proc: compiler_proc,
}

compiler_new :: proc(lexer: ^lex.Lexer) -> ^Compiler {
	c := new(Compiler)
	c.lexer = lexer
	c.compile = compiler_compile
	c.free = compiler_free
	return c
}

compiler_free :: proc(c: ^Compiler) {
	if c != nil {
		free(c)
	}
}

compiler_compile :: proc(c: ^Compiler) {
	line := 0

	for {
		token := c.lexer->scan_token()

		if token.line != line {
			fmt.printf("%4d ", token.line)
			line = token.line
		} else {
			fmt.print("   | ")
		}

		lexeme := "<EOF>" if token.type == .EOF else string(c.lexer.source[c.lexer.start:c.lexer.next])

		fmt.printfln("%s %s", token.type, lexeme)

		if token.type == .EOF do break
	}
}
