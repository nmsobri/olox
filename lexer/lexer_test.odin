package lexer

import "core:testing"
import "core:fmt"
import "core:strings"

// Helper function to create a test lexer
test_lexer :: proc(source: string) -> ^Lexer {
    return lexer_new(transmute([]byte)source, context.temp_allocator)
}

// Helper function to scan all tokens from source
scan_all_tokens :: proc(source: string) -> []Token {
    lexer := test_lexer(source)
    defer free(lexer)

    tokens := make([dynamic]Token)
    defer delete(tokens)

    for {
        token := lexer->scan_token()
        append(&tokens, token)
        if token.type == .EOF do break
    }

    return tokens[:]
}

@(test)
test_single_character_tokens :: proc(t: ^testing.T) {
    source := "(){};,.-+/*"
    expected_types := []TokenType{
        .LEFT_PAREN, .RIGHT_PAREN, .LEFT_BRACE, .RIGHT_BRACE,
        .SEMICOLON, .COMMA, .DOT, .MINUS, .PLUS, .SLASH, .STAR, .EOF
    }

    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), len(expected_types))

    for i in 0..<len(expected_types) {
        testing.expect_value(t, tokens[i].type, expected_types[i])
    }
}

@(test)
test_two_character_tokens :: proc(t: ^testing.T) {
    test_cases := []struct{
        source: string,
        expected: TokenType,
    }{
        {"!=", .BANG_EQUAL},
        {"!", .BANG},
        {"==", .EQUAL_EQUAL},
        {"=", .EQUAL},
        {"<=", .LESS_EQUAL},
        {"<", .LESS},
        {">=", .GREATER_EQUAL},
        {">", .GREATER},
    }

    for test_case in test_cases {
        tokens := scan_all_tokens(test_case.source)
        defer delete(tokens)

        testing.expect_value(t, len(tokens), 2) // token + EOF
        testing.expect_value(t, tokens[0].type, test_case.expected)
    }
}

@(test)
test_whitespace_handling :: proc(t: ^testing.T) {
    source := "  \t\r\n  (  \n  )  "
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), 3) // LEFT_PAREN, RIGHT_PAREN, EOF
    testing.expect_value(t, tokens[0].type, TokenType.LEFT_PAREN)
    testing.expect_value(t, tokens[1].type, TokenType.RIGHT_PAREN)
    testing.expect_value(t, tokens[2].type, TokenType.EOF)
}

@(test)
test_line_counting :: proc(t: ^testing.T) {
    source := "(\n\n)"
    lexer := test_lexer(source)
    defer free(lexer)

    token1 := lexer->scan_token()
    testing.expect_value(t, token1.line, 1)

    token2 := lexer->scan_token()
    testing.expect_value(t, token2.line, 3)
}

@(test)
test_comments :: proc(t: ^testing.T) {
    source := "( // this is a comment\n)"
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), 3) // LEFT_PAREN, RIGHT_PAREN, EOF
    testing.expect_value(t, tokens[0].type, TokenType.LEFT_PAREN)
    testing.expect_value(t, tokens[1].type, TokenType.RIGHT_PAREN)
}

@(test)
test_string_literals :: proc(t: ^testing.T) {
    test_cases := []struct{
        source: string,
        should_succeed: bool,
    }{
        {`"hello"`, true},
        {`"hello world"`, true},
        {`""`, true},
        {`"multi\nline"`, true},
        {`"unterminated`, false},
    }

    for test_case in test_cases {
        tokens := scan_all_tokens(test_case.source)
        defer delete(tokens)

        if test_case.should_succeed {
            testing.expect_value(t, len(tokens), 2) // STRING, EOF
            testing.expect_value(t, tokens[0].type, TokenType.STRING)
        } else {
        // Should have an error token
            testing.expect_value(t, tokens[0].type, TokenType.ERROR)
        }
    }
}

@(test)
test_string_with_newlines :: proc(t: ^testing.T) {
    source := "\"line1\nline2\""
    lexer := test_lexer(source)
    defer free(lexer)

    initial_line := lexer.line
    token := lexer->scan_token()

    testing.expect_value(t, token.type, TokenType.STRING)
    testing.expect_value(t, lexer.line, initial_line + 1) // Should increment line counter
}

@(test)
test_number_literals :: proc(t: ^testing.T) {
    test_cases := []string{
        "123",
        "123.456",
        "0",
        "0.0",
        "999.999",
    }

    for test_case in test_cases {
        tokens := scan_all_tokens(test_case)
        defer delete(tokens)

        testing.expect_value(t, len(tokens), 2) // NUMBER, EOF
        testing.expect_value(t, tokens[0].type, TokenType.NUMBER)
    }
}

@(test)
test_identifiers :: proc(t: ^testing.T) {
    test_cases := []string{
        "variable",
        "_private",
        "camelCase",
        "snake_case",
        "var123",
        "hello_world_123",
    }

    for test_case in test_cases {
        tokens := scan_all_tokens(test_case)
        defer delete(tokens)

        testing.expect_value(t, len(tokens), 2) // IDENTIFIER, EOF
        testing.expect_value(t, tokens[0].type, TokenType.IDENTIFIER)
    }
}

@(test)
test_keywords :: proc(t: ^testing.T) {
    test_cases := []struct{
        keyword: string,
        expected: TokenType,
    }{
        {"and", .AND},
        {"class", .CLASS},
        {"else", .ELSE},
        {"false", .FALSE},
        {"fun", .FUN},
        {"for", .FOR},
        {"if", .IF},
        {"nil", .NIL},
        {"or", .OR},
        {"print", .PRINT},
        {"return", .RETURN},
        {"super", .SUPER},
        {"this", .THIS},
        {"true", .TRUE},
        {"var", .VAR},
        {"while", .WHILE},
    }

    for test_case in test_cases {
        tokens := scan_all_tokens(test_case.keyword)
        defer delete(tokens)

        testing.expect_value(t, len(tokens), 2) // KEYWORD, EOF
        testing.expect_value(t, tokens[0].type, test_case.expected)
    }
}

@(test)
test_mixed_expression :: proc(t: ^testing.T) {
    source := `var x = 123.45 + "hello";`
    expected_types := []TokenType{
        .VAR, .IDENTIFIER, .EQUAL, .NUMBER, .PLUS, .STRING, .SEMICOLON, .EOF
    }

    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), len(expected_types))

    for i in 0..<len(expected_types) {
        testing.expect_value(t, tokens[i].type, expected_types[i])
    }
}

@(test)
test_function_declaration :: proc(t: ^testing.T) {
    source := `fun hello() { print "Hello, World!"; }`
    expected_types := []TokenType{
        .FUN, .IDENTIFIER, .LEFT_PAREN, .RIGHT_PAREN, .LEFT_BRACE,
        .PRINT, .STRING, .SEMICOLON, .RIGHT_BRACE, .EOF
    }

    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), len(expected_types))

    for i in 0..<len(expected_types) {
        testing.expect_value(t, tokens[i].type, expected_types[i])
    }
}

@(test)
test_control_flow :: proc(t: ^testing.T) {
    source := `if (x > 0) { return true; } else { return false; }`
    expected_types := []TokenType{
        .IF, .LEFT_PAREN, .IDENTIFIER, .GREATER, .NUMBER, .RIGHT_PAREN,
        .LEFT_BRACE, .RETURN, .TRUE, .SEMICOLON, .RIGHT_BRACE,
        .ELSE, .LEFT_BRACE, .RETURN, .FALSE, .SEMICOLON, .RIGHT_BRACE, .EOF
    }

    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), len(expected_types))

    for i in 0..<len(expected_types) {
        testing.expect_value(t, tokens[i].type, expected_types[i])
    }
}

@(test)
test_empty_source :: proc(t: ^testing.T) {
    source := ""
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), 1) // Just EOF
    testing.expect_value(t, tokens[0].type, TokenType.EOF)
}

@(test)
test_only_comments :: proc(t: ^testing.T) {
    source := "// just a comment"
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), 1) // Just EOF
    testing.expect_value(t, tokens[0].type, TokenType.EOF)
}

@(test)
test_unexpected_character :: proc(t: ^testing.T) {
    source := "@"  // @ is not a valid character in your lexer
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, tokens[0].type, TokenType.ERROR)
}

@(test)
test_peek_next_functionality :: proc(t: ^testing.T) {
// Test that peek_next works correctly with decimal numbers
    source := "12.34"
    tokens := scan_all_tokens(source)
    defer delete(tokens)

    testing.expect_value(t, len(tokens), 2) // NUMBER, EOF
    testing.expect_value(t, tokens[0].type, TokenType.NUMBER)
}

@(test)
test_complex_program :: proc(t: ^testing.T) {
    source := `
    class Calculator {
        fun add(a, b) {
            return a + b;
        }

        fun multiply(a, b) {
            var result = 0;
            for (var i = 0; i < b; i = i + 1) {
                result = result + a;
            }
            return result;
        }
    }

    var calc = Calculator();
    print calc.add(5, 3);
    print calc.multiply(4, 6);
    `

    tokens := scan_all_tokens(source)
    defer delete(tokens)

    // Just verify we get a reasonable number of tokens and no errors
    testing.expect(t, len(tokens) > 30, "Should have many tokens for complex program")

    // Check that the last token is EOF
    testing.expect_value(t, tokens[len(tokens)-1].type, TokenType.EOF)

    // Verify no error tokens
    for token in tokens {
        testing.expect(t, token.type != .ERROR, "Should not have error tokens in valid program")
    }
}

// Test helper functions
@(test)
test_lexer_helper_functions :: proc(t: ^testing.T) {
    lexer := test_lexer("abc123")
    defer free(lexer)

    // Test is_alpha
    testing.expect_value(t, lexer->is_alpha('a'), true)
    testing.expect_value(t, lexer->is_alpha('Z'), true)
    testing.expect_value(t, lexer->is_alpha('_'), true)
    testing.expect_value(t, lexer->is_alpha('1'), false)
    testing.expect_value(t, lexer->is_alpha('!'), false)

    // Test is_digit
    testing.expect_value(t, lexer->is_digit('0'), true)
    testing.expect_value(t, lexer->is_digit('9'), true)
    testing.expect_value(t, lexer->is_digit('a'), false)
    testing.expect_value(t, lexer->is_digit('_'), false)
}