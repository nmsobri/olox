package lexer
import "../lox"
import strconv "core:strconv"
import utf8 "core:unicode/utf8"

Keywords := make(map[string]TokenType)

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
}

@(fini)
deinit :: proc() {
	delete(Keywords)
}

Lexer :: struct {
	source:           []byte,
	start:            int,
	current:          int,
	line:             int,
	using lexer_proc: lexer_proc,
}

lexer_proc :: struct {
	scan_token:      proc(lexer: ^Lexer) -> Token,
	is_at_end:       proc(lexer: ^Lexer) -> bool,
	advance:         proc(lexer: ^Lexer) -> byte,
	match:           proc(lexer: ^Lexer, c: byte) -> bool,
	peek:            proc(lexer: ^Lexer) -> byte,
	peek_next:       proc(lexer: ^Lexer) -> byte,
	skip_whitespace: proc(lexer: ^Lexer),
	string:          proc(lexer: ^Lexer) -> Token,
	is_digit:        proc(lexer: ^Lexer, c: byte) -> bool,
	is_alpha:        proc(lexer: ^Lexer, c: byte) -> bool,
	number:          proc(lexer: ^Lexer) -> Token,
	identifier:      proc(lexer: ^Lexer) -> Token,
}

lexer_new :: proc(source: []byte) -> ^Lexer {
	lex := new(Lexer)

	lex.source = source
	lex.start = 0
	lex.current = 0
	lex.line = 1

	lex.scan_token = lexer_scan_token
	lex.is_at_end = lexer_is_at_end
	lex.advance = lexer_advance
	lex.match = lexer_match
	lex.peek = lexer_peek
	lex.peek_next = lexer_peek_next
	lex.skip_whitespace = lexer_skip_whitespace
	lex.string = lexer_string
	lex.is_digit = lexer_is_digit
	lex.is_alpha = lexer_is_alpha
	lex.number = lexer_number
	lex.identifier = lexer_identifier

	return lex
}

lexer_scan_token :: proc(lexer: ^Lexer) -> Token {
	lexer->skip_whitespace()

	lexer.start = lexer.current

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
		return lexer->string()

	case lexer->is_digit(c):
		return lexer->number()

	case lexer->is_alpha(c):
		return lexer->identifier()
	}

	return token_error("Unexpected character.", lexer)
}

lexer_is_at_end :: proc(lexer: ^Lexer) -> bool {
	if lexer.current >= len(lexer.source) do return true
	return false
}

lexer_advance :: proc(lexer: ^Lexer) -> byte {
	current := lexer.source[lexer.current]
	lexer.current += 1
	return current
}

lexer_match :: proc(lexer: ^Lexer, c: byte) -> bool {
	if lexer->is_at_end() do return false
	if lexer.source[lexer.current] != c do return false

	lexer->advance()
	return true
}

lexer_peek :: proc(lexer: ^Lexer) -> byte {
	if lexer->is_at_end() do return 0
	return lexer.source[lexer.current]
}

lexer_peek_next :: proc(lexer: ^Lexer) -> byte {
	if lexer->is_at_end() do return 0
	return lexer.source[lexer.current + 1]
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

lexer_is_digit :: proc(lexer: ^Lexer, c: byte) -> bool {
	return c >= '0' && c <= '9'
}

lexer_is_alpha :: proc(lexer: ^Lexer, c: byte) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
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

	lexeme := lexer.source[lexer.start:lexer.current]

	if keyword, ok := Keywords[string(lexeme)]; ok {
		return token_new(keyword, lexer)
	}

	return token_new(.IDENTIFIER, lexer)
}
