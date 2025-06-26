package lexer

import fmt "core:fmt"

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
	string,
	bool,
	f64,
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
	return Token {
		type = type,
		start = lexer.start,
		length = lexer.next - lexer.start,
		line = lexer.line,
		lexeme = string(lexer.source[lexer.start:lexer.next]),
		literal = string(lexer.source[lexer.start:lexer.next]),
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
