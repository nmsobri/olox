package lexer

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

TokenType :: enum {
	LEFT_PAREN,
	RIGHT_PAREN,
	LEFT_BRACE,
	RIGHT_BRACE,
	COMMA,
	DOT,
	MINUS,
	PLUS,
	SEMICOLON,
	SLASH,
	STAR,
	BANG,
	BANG_EQUAL,
	EQUAL,
	EQUAL_EQUAL,
	GREATER,
	GREATER_EQUAL,
	LESS,
	LESS_EQUAL,
	IDENTIFIER,
	STRING,
	NUMBER,
	AND,
	CLASS,
	ELSE,
	FALSE,
	FOR,
	FUN,
	IF,
	NIL,
	OR,
	PRINT,
	RETURN,
	SUPER,
	THIS,
	TRUE,
	VAR,
	WHILE,
	ERROR,
	EOF,
}

Literal :: union {
	f64,
	i64,
	string,
	bool,
}

Token :: struct {
	type:      TokenType,
	start:     int,
	length:    int,
	line:      int,
	lexeme:    string,
	literal:   Literal,
	to_string: proc(token: ^Token) -> string,
}

token_new :: proc(type: TokenType, lexer: ^Lexer) -> Token {
	literal: Literal

	#partial switch type {
	case .STRING:
		size := utf8.rune_size('"') // get `"` byte count to strip those `"`
		literal = string(lexer.source[lexer.start + size:lexer.next - size])

	case .NUMBER:
		str_num := string(lexer.source[lexer.start:lexer.next])

		if strings.contains_rune(str_num, '.') {
			if num, ok := strconv.parse_f64(str_num); ok {
				literal = f64(num)
			} else do panic("invalid number")
		} else {
			if num, ok := strconv.parse_int(str_num); ok {
				literal = i64(num)
			} else do panic("invalid number")
		}

	case .TRUE, .FALSE:
		literal = true if type == .TRUE else false

	case:
		literal = string(lexer.source[lexer.start:lexer.next])
	}

	return Token {
		type = type,
		start = lexer.start,
		length = lexer.next - lexer.start,
		line = lexer.line,
		lexeme = string(lexer.source[lexer.start:lexer.next]),
		literal = literal,
	}
}

token_error :: proc(message: string, lexer: ^Lexer) -> Token {
	return Token {
		type = .ERROR,
		start = 0,
		length = len(message),
		line = lexer.line,
		lexeme = message,
		literal = message,
	}
}

token_to_string :: proc(token: ^Token) -> string {
	return fmt.tprintf("type:%s, lexeme:%s, literal:%v", token.type, token.lexeme, token.literal)
}
