package parser

import lex "../lexer"
import fmt "core:fmt"

parser_proc :: struct {
	parse_program:              proc(p: ^Parser) -> Program,
	parse_statement:            proc(p: ^Parser) -> Statement,
	parse_expression_statement: proc(p: ^Parser) -> ExprStmt,
	parse_expression:           proc(p: ^Parser) -> Expr,
	parse_var_statement:        proc(p: ^Parser) -> Statement,
	next_token:                 proc(p: ^Parser) -> lex.Token,
	peek_token:                 proc(p: ^Parser) -> lex.Token,
	match_token:                proc(p: ^Parser, token: lex.TokenType) -> lex.Token,
}

Parser :: struct {
	lexer:             ^lex.Lexer,
	current_token:     lex.Token,
	using parser_proc: parser_proc,
}

parser_new :: proc(lexer: ^lex.Lexer) -> ^Parser {
	p := new(Parser)

	p.lexer = lexer
	p.parse_program = parser_parse_program
	p.parse_statement = parser_parse_statement
	p.parse_expression_statement = parser_parse_expression_statement
	p.parse_expression = parser_parse_expression
	p.parse_var_statement = parser_parse_var_statement
	p.next_token = parser_next_token
	p.peek_token = parser_peek_token
	p.match_token = parser_match_token

	p->next_token() // prime token
	return p
}

parser_free :: proc(parser: ^Parser) {
	free(parser)
}

parser_parse_program :: proc(p: ^Parser) -> Program {
	program := Program {
		statements = make([dynamic]Statement),
	}

	stmt := p->parse_statement()

	append(&program.statements, stmt)

	return program
}

parser_parse_statement :: proc(p: ^Parser) -> Statement {
	#partial switch p.current_token.type {
	case .VAR:
		return p->parse_var_statement()

	case:
		return p->parse_expression_statement()
	}
}

parser_parse_var_statement :: proc(p: ^Parser) -> Statement {
	ident := p->match_token(.IDENTIFIER)

	p->match_token(.EQUAL)

	val := p->parse_expression_statement()

	return VarStmt{name = ident.lexeme, value = val.expression}
}

parser_parse_expression_statement :: proc(p: ^Parser) -> ExprStmt {
	expression := p->parse_expression()
	return ExprStmt{expression = expression}
}

parser_next_token :: proc(p: ^Parser) -> lex.Token {
	p.current_token = p.lexer->scan_token()
	return p.current_token
}

parser_peek_token :: proc(p: ^Parser) -> lex.Token {
	lexer_next := p.lexer.next
	token := p.lexer->scan_token()
	p.lexer.next = lexer_next // restore lexer position
	return token
}

parser_match_token :: proc(p: ^Parser, token_type: lex.TokenType) -> lex.Token {
	if p->peek_token().type != token_type {
		fmt.eprintfln("Unexpected token: expected %s, got %s", token_type, p->peek_token().type)
		panic("Unexpected token")
	}

	return p->next_token()
}

parser_parse_expression :: proc(p: ^Parser) -> Expr {
	p->next_token()
	return LiteralExpr(p.current_token.literal)
}
