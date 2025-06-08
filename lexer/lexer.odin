package lexer
import "../lox"
import utf8 "core:unicode/utf8"

lexer :: struct {
    source: []byte,
    tokens: [dynamic]token,
    start: int,
    current: int,
    line: int,

    new: proc(source: []byte) -> lexer,
    scan_tokens: proc(^lexer) -> [dynamic]token,
    is_at_end: proc(^lexer) -> bool,
    scan_token: proc(^lexer),
    advance: proc(^lexer) -> rune,
    match: proc(^lexer, rune) -> bool,
    peek: proc(^lexer) -> rune,
}

lexer_new :: proc(source: []byte) -> lexer {
    return lexer {
        source = source,
        tokens = make([dynamic]token, 0),
        start = 0,
        current= 0,
        line = 1,

        new = lexer_new,
        scan_tokens = lexer_scan_tokens,
        is_at_end = lexer_is_at_end,
        scan_token = lexer_scan_token,
        advance = lexer_advance,
        match =  lexer_match,
        peek = lexer_peek,
    }
}

lexer_scan_tokens :: proc(lex: ^lexer) -> [dynamic]token {
    for !lex->is_at_end() {
        lex.start = lex.current
        lex->scan_token()
    }

    append(&lex.tokens, token_new(.EOF, "<EOF>", "<EOF>", lex.line))
    return lex.tokens
}

lexer_scan_token :: proc(lex: ^lexer) {
    t: TokenType
    c: rune = lex->advance()

    switch c {
        case '(': t = .LEFT_PAREN
        case ')': t = .RIGHT_PAREN
        case '{': t = .LEFT_BRACE
        case '}': t = .RIGHT_BRACE
        case ',': t = .COMMA
        case '.': t = .DOT
        case '-': t = .MINUS
        case '+': t = .PLUS
        case ';': t = .SEMICOLON
        case '*': t = .STAR
        case '!': t = .BANG_EQUAL if lex->match('=') else .BANG
        case '=': t = .EQUAL_EQUAL if lex->match('=') else .EQUAL
        case '<': t = .LESS_EQUAL if lex->match('=') else .LESS
        case '>': t = .GREATER_EQUAL if lex->match('=') else .GREATER
        case ' ', '\r', '\t': return
        case '\n': {
            lex.line += 1
            return
        }

       case '/': {
            if lex->match('/') {
                for !lex->is_at_end() && lex->peek() != '\n' {
                    lex->advance()
                }
                return
            }

            t = .SLASH
        }

        case '"': {
            for !lex->is_at_end() && lex->peek() != '"' {
                if lex->peek() == '\n' {
                    lex.line += 1
                }

                lex->advance()
            }

            if lex->is_at_end() {
                lox.error(lex.line, "Unterminated string.")
                return
            }

            lex->advance() // consume the closing quote

            str := string(lex.source[lex.start + 1: lex.current - 1])
            append(&lex.tokens, token_new(.STRING, str, str, lex.line))
            return
        }

        case: lox.error(lex.line, "Unexpected character.");
    }

    str:= string(lex.source[lex.start:lex.current])
    append(&lex.tokens, token_new(t, str, str, lex.line))
}

lexer_advance :: proc(lex: ^lexer) -> rune {
    r, size := utf8.decode_rune(lex.source[lex.current:])
    lex.current += size
    return r
}

lexer_is_at_end :: proc(lex: ^lexer) -> bool {
    return lex.current >= len(lex.source)
}

lexer_match :: proc(lex: ^lexer, search_needle: rune) -> bool {
    if lex->is_at_end() do return false

    next_needle, s := utf8.decode_rune(lex.source[lex.current:])

    if next_needle != search_needle do return false

    lex.current += s
    return true
}

lexer_peek :: proc(lex: ^lexer)-> rune {
    if lex->is_at_end() do return rune(0)
    r, _ := utf8.decode_rune(lex.source[lex.current:])
    return r
}

// Todo: number literals