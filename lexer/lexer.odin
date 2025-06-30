package lexer
import "../lox"
import strconv "core:strconv"
import unicode "core:unicode"
import utf8 "core:unicode/utf8"

Keywords := make(map[string]TokenType)
BindingPower := make(map[TokenType]int)

@(init)
init :: proc() {
	Keywords["and"] = .AND
	Keywords["class"] = .CLASS
	Keywords["else"] = .ELSE
	Keywords["false"] = .FALSE
	Keywords["fun"] = .FUN
	Keywords["for"] = .FOR
	Keywords["if"] = .IF
	Keywords["nil"] = .NIL
	Keywords["or"] = .OR
	Keywords["print"] = .PRINT
	Keywords["return"] = .RETURN
	Keywords["super"] = .SUPER
	Keywords["this"] = .THIS
	Keywords["true"] = .TRUE
	Keywords["var"] = .VAR
	Keywords["while"] = .WHILE

	BindingPower[TokenType.PLUS] = 1
	BindingPower[TokenType.MINUS] = 1
	BindingPower[TokenType.STAR] = 2
	BindingPower[TokenType.SLASH] = 2
}

@(fini)
deinit :: proc() {
	delete(Keywords)
	delete(BindingPower)
}

lexer_proc :: struct {
	scan_token:      proc(lexer: ^Lexer) -> Token,
	is_at_end:       proc(lexer: ^Lexer) -> bool,
	advance:         proc(lexer: ^Lexer) -> rune,
	match:           proc(lexer: ^Lexer, r: rune) -> bool,
	peek:            proc(lexer: ^Lexer) -> rune,
	peek_next:       proc(lexer: ^Lexer) -> rune,
	skip_whitespace: proc(lexer: ^Lexer),
	strings:         proc(lexer: ^Lexer) -> Token,
	is_digit:        proc(lexer: ^Lexer, r: rune) -> bool,
	is_alpha:        proc(lexer: ^Lexer, r: rune) -> bool,
	number:          proc(lexer: ^Lexer) -> Token,
	identifier:      proc(lexer: ^Lexer) -> Token,
	free:            proc(lexer: ^Lexer),
}

Lexer :: struct {
	source:           []byte,
	start:            int,
	next:             int,
	line:             int,
	using lexer_proc: lexer_proc,
}


lexer_new :: proc(source: []byte) -> ^Lexer {
	lex := new(Lexer)

	lex.source = source
	lex.start = 0
	lex.next = 0
	lex.line = 1

	lex.scan_token = lexer_scan_token
	lex.is_at_end = lexer_is_at_end
	lex.advance = lexer_advance
	lex.match = lexer_match
	lex.peek = lexer_peek
	lex.peek_next = lexer_peek_next
	lex.skip_whitespace = lexer_skip_whitespace
	lex.strings = lexer_string
	lex.is_digit = lexer_is_digit
	lex.is_alpha = lexer_is_alpha
	lex.number = lexer_number
	lex.identifier = lexer_identifier
	lex.free = lexer_free

	return lex
}

lexer_free :: proc(lexer: ^Lexer) {
	if lexer != nil {
		free(lexer)
	}
}

lexer_scan_token :: proc(lexer: ^Lexer) -> Token {
	lexer->skip_whitespace()

	lexer.start = lexer.next

	if lexer->is_at_end() do return token_new(.EOF, lexer)

	c := lexer->advance()

	switch {
	case c == '(':
		return token_new(.LEFT_PAREN, lexer)

	case c == ')':
		return token_new(.RIGHT_PAREN, lexer)

	case c == '{':
		return token_new(.LEFT_BRACE, lexer)

	case c == '}':
		return token_new(.RIGHT_BRACE, lexer)

	case c == ';':
		return token_new(.SEMICOLON, lexer)

	case c == ',':
		return token_new(.COMMA, lexer)

	case c == '.':
		return token_new(.DOT, lexer)

	case c == '-':
		return token_new(.MINUS, lexer)

	case c == '+':
		return token_new(.PLUS, lexer)

	case c == '/':
		return token_new(.SLASH, lexer)

	case c == '*':
		return token_new(.STAR, lexer)

	case c == '!':
		return token_new(.BANG_EQUAL if lexer->match('=') else .BANG, lexer)

	case c == '=':
		return token_new(.EQUAL_EQUAL if lexer->match('=') else .EQUAL, lexer)

	case c == '<':
		return token_new(.LESS_EQUAL if lexer->match('=') else .LESS, lexer)

	case c == '>':
		return token_new(.GREATER_EQUAL if lexer->match('=') else .GREATER, lexer)

	case c == '"':
		return lexer->strings()

	case lexer->is_digit(c):
		return lexer->number()

	case lexer->is_alpha(c):
		return lexer->identifier()
	}

	return token_error("Unexpected character.", lexer)
}

lexer_is_at_end :: proc(lexer: ^Lexer) -> bool {
	if lexer.next >= len(lexer.source) do return true
	return false
}

lexer_advance :: proc(lexer: ^Lexer) -> rune {
	r, size := utf8.decode_rune(lexer.source[lexer.next:])
	lexer.next += size
	return r
}

lexer_match :: proc(lexer: ^Lexer, r: rune) -> bool {
	if lexer->is_at_end() do return false

	fr, _ := utf8.decode_rune(lexer.source[lexer.next:])
	if r != fr do return false

	lexer->advance()
	return true
}

lexer_peek :: proc(lexer: ^Lexer) -> rune {
	if lexer->is_at_end() do return 0
	r, _ := utf8.decode_rune(lexer.source[lexer.next:])
	return r
}

lexer_peek_next :: proc(lexer: ^Lexer) -> rune {
	if lexer->is_at_end() do return 0

	r: rune
	current := lexer.next

	for i in 0 ..< 2 {
		size: int
		r, size = utf8.decode_rune(lexer.source[current:])
		current += size
	}

	return r
}

lexer_skip_whitespace :: proc(lexer: ^Lexer) {
	for {
		c := lexer->peek()
		switch c {
		case ' ', '\t', '\r':
			lexer->advance()

		case '\n':
			{
				lexer.line += 1
				lexer->advance()
			}

		case '/':
			{
				if lexer->peek_next() == '/' {
					for lexer->peek() != '\n' && !lexer->is_at_end() {
						lexer->advance()
					}
				} else do return
			}

		case:
			return
		}
	}
}

lexer_string :: proc(lexer: ^Lexer) -> Token {
	for lexer->peek() != '"' && !lexer->is_at_end() {
		if lexer->peek() == '\n' do lexer.line += 1
		lexer->advance()
	}

	if lexer->is_at_end() do return token_error("Unterminated string.", lexer)

	lexer->match('"') // consume the closing quote

	return token_new(.STRING, lexer)
}

lexer_is_digit :: proc(lexer: ^Lexer, r: rune) -> bool {
	return unicode.is_digit(r)
}

lexer_is_alpha :: proc(lexer: ^Lexer, r: rune) -> bool {
	return(
		unicode.is_letter(r) ||
		unicode.is_nonspacing_mark(r) ||
		unicode.is_spacing_mark(r) ||
		unicode.is_enclosing_mark(r) ||
		r == '_' \
	)
}

lexer_number :: proc(lexer: ^Lexer) -> Token {
	for lexer->is_digit(lexer->peek()) do lexer->advance()

	if lexer->peek() == '.' && lexer->is_digit(lexer->peek_next()) {
		lexer->advance() // the dot
		for lexer->is_digit(lexer->peek()) do lexer->advance()
	}

	return token_new(.NUMBER, lexer)
}

lexer_identifier :: proc(lexer: ^Lexer) -> Token {
	for lexer->is_digit(lexer->peek()) || lexer->is_alpha(lexer->peek()) do lexer->advance()

	lexeme := lexer.source[lexer.start:lexer.next]

	if keyword, ok := Keywords[string(lexeme)]; ok {
		return token_new(keyword, lexer)
	}

	return token_new(.IDENTIFIER, lexer)
}
