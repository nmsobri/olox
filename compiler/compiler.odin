package compiler

import lex "../lexer"
import "core:fmt"

Compiler :: struct {
	using compiler_proc: compiler_proc,
}

compiler_proc :: struct {
	compile: proc(c: ^Compiler, source: []u8),
}

compiler_new :: proc() -> ^Compiler {
	c := new(Compiler)
	c.compile = compile
	return c
}

compiler_free :: proc(c: ^Compiler) {
	if c != nil {
		free(c)
	}
}

compile :: proc(compiler: ^Compiler, source: []u8) {
	line := 0
	lexer := lex.lexer_new(source)

	for {
		token := lexer->scan_token()

		if token.line != line {
			fmt.printf("%4d ", token.line)
			line = token.line
		} else {
			fmt.print("   | ")
		}

		lexeme :=
			"<EOF>" if token.type == .EOF else string(lexer.source[lexer.start:lexer.current])

		fmt.printfln("%s %s", token.type, lexeme)

		if token.type == .EOF do break
	}
}
