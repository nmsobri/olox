package lexer
import "../lox"
import utf8 "core:unicode/utf8"
import strconv "core:strconv"

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
    peek_next: proc(^lexer) -> rune,
    is_digit: proc(^lexer, rune) -> bool,
    is_alpha: proc(^lexer, rune) -> bool,
    is_alpha_numeric: proc(^lexer, rune) -> bool,
    identifier: proc(^lexer) -> TokenType,
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
        peek_next = lexer_peek_next,
        is_digit =  lexer_is_digit,
        is_alpha = lexer_is_alpha,
        is_alpha_numeric = lexer_is_alpha_numeric,
        identifier = lexer_identifier,
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

    switch {
        case c == '(': t = .LEFT_PAREN
        case c == ')': t = .RIGHT_PAREN
        case c == '{': t = .LEFT_BRACE
        case c == '}': t = .RIGHT_BRACE
        case c == ',': t = .COMMA
        case c == '.': t = .DOT
        case c == '-': t = .MINUS
        case c == '+': t = .PLUS
        case c == ';': t = .SEMICOLON
        case c == '*': t = .STAR
        case c == '!': t = .BANG_EQUAL if lex->match('=') else .BANG
        case c == '=': t = .EQUAL_EQUAL if lex->match('=') else .EQUAL
        case c == '<': t = .LESS_EQUAL if lex->match('=') else .LESS
        case c == '>': t = .GREATER_EQUAL if lex->match('=') else .GREATER
        case c == ' ' || c ==  '\r' || c == '\t': return

        case c == '\n': {
            lex.line += 1
            return
        }

       case c == '/': {
            if lex->match('/') {
                for !lex->is_at_end() && lex->peek() != '\n' {
                    lex->advance()
                }

                return
            }

            t = .SLASH
        }

        case c == '"': {
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

        case lex->is_digit(c): {
            for lex->is_digit(lex->peek()) do lex->advance()

            if lex->peek() == '.' && lex->is_digit(lex->peek_next()) {
                lex->advance() // consume the '.'
                for lex->is_digit(lex->peek()) do lex->advance()
            }

            t = .NUMBER
            str := string(lex.source[lex.start:lex.current])

            if str_f64, ok := strconv.parse_f64(str); ok {
                literal: Literal = f64(str_f64)
                append(&lex.tokens, token_new(t, str, literal, lex.line))
            }

            return
        }

        case lex->is_alpha(c): {
            t = lex->identifier()
        }

        case: {
            lox.error(lex.line, "Unexpected character.");
        }
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

lexer_peek_next :: proc(lex: ^lexer) -> rune {
    how_far :: 2 // we only support up to 2 lookahead characters
    current_pos := lex.current
    r: rune = 0

    for i in 0..< how_far{
        if lex->is_at_end() do return rune(0)
        c, size := utf8.decode_rune(lex.source[current_pos:])
        r = c
        current_pos += size
    }

    return r
}

lexer_is_digit :: proc(lex: ^lexer, c: rune) -> bool {
    return c >= '0' && c <= '9'
}

lexer_is_alpha :: proc(lex: ^lexer, c: rune) -> bool {
    return c >= 'a' && c <= 'z' ||
           c >= 'A' && c <= 'Z' ||
           c == '_'
}

lexer_is_alpha_numeric :: proc(lex: ^lexer, c: rune) -> bool {
    return lex->is_alpha(c) || lex->is_digit(c)
}

lexer_identifier :: proc(lex: ^lexer) -> TokenType {
    for lex->is_alpha_numeric(lex->peek()) do lex->advance()

    str := string(lex.source[lex.start:lex.current])

    if type, ok := Keywords[str]; ok {
        return type
    }

    return .IDENTIFIER
}