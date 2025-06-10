package lexer

import fmt "core:fmt"

TokenType :: enum {
    ILLEGAL,
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
    FUN,
    FOR,
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

    EOF,
}

Literal :: union {
    string,
    bool,
    f64,
}

token :: struct {
    type: TokenType,
    lexeme: string,
    literal: Literal,
    line: int,

    new: proc(type: TokenType, lexeme: string, literal: Literal, line:int) -> token,
    to_string: proc(token: ^token) -> string,
}

token_new :: proc( type: TokenType, lexeme: string, literal: Literal, line:int) -> token {
    return token {
        type = type,
        lexeme = lexeme,
        literal = literal,
        line = line,

        new = token_new,
        to_string = token_to_string,
    }
}

token_to_string :: proc(token: ^token) -> string {
    return fmt.tprintf(
        "type:%s, lexeme:%s, literal:%v", token.type, token.lexeme, token.literal,
    )
}