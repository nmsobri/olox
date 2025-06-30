package parser

import lex "../lexer"
import fmt "core:fmt"

parser_proc :: struct {
	parse_program:              proc(p: ^Parser) -> Program,
	parse_statement:            proc(p: ^Parser) -> Statement,
	parse_expression_statement: proc(p: ^Parser) -> ExprStmt,
	parse_expression:           proc(p: ^Parser, current_binding_power: int) -> Expr,
	parse_prefix_expression:    proc(p: ^Parser) -> Expr,
	parse_infix_expression:     proc(p: ^Parser, left: Expr, current_binding_power: int) -> Expr,
	parse_binary_expression:    proc(p: ^Parser, left: Expr, current_binding_power: int) -> Expr,
	parse_var_statement:        proc(p: ^Parser) -> Statement,
	next_token:                 proc(p: ^Parser) -> lex.Token,
	peek_token:                 proc(p: ^Parser) -> lex.Token,
	match_token:                proc(p: ^Parser, token: lex.TokenType) -> lex.Token,
	free:                       proc(p: ^Parser),
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
	p.parse_prefix_expression = parser_parse_prefix_expression
	p.parse_infix_expression = parser_parse_infix_expression
	p.parse_binary_expression = parser_parse_binary_expression
	p.parse_var_statement = parser_parse_var_statement
	p.next_token = parser_next_token
	p.peek_token = parser_peek_token
	p.match_token = parser_match_token
	p.free = parser_free

	p->next_token()
	return p
}

parser_free :: proc(parser: ^Parser) {
	free(parser)
}

parser_parse_program :: proc(p: ^Parser) -> Program {
	program := Program {
		statements = make([dynamic]Statement, context.allocator),
	}

	for p.current_token.type != .EOF {
		stmt := p->parse_statement()
		append(&program.statements, stmt)
		p->next_token()
	}

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
	expression := p->parse_expression(0)
	return ExprStmt{expression = expression}
}

parser_parse_expression :: proc(p: ^Parser, current_binding_power: int) -> Expr {
	p->next_token()
	left: Expr = p->parse_prefix_expression()

	next_binding_power := lex.BindingPower[p->peek_token().type]

	if next_binding_power > current_binding_power {
		p->next_token()
		left = p->parse_infix_expression(left, next_binding_power)
	}

	return left
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


parser_parse_prefix_expression :: proc(p: ^Parser) -> Expr {
	#partial switch p.current_token.type {
	case .NUMBER, .STRING:
		return LiteralExpr(p.current_token.literal)

	case:
		panic("parse prefix expression: Unexpected token")
	}
}


parser_parse_infix_expression :: proc(p: ^Parser, left: Expr, current_binding_power: int) -> Expr {
	#partial switch p.current_token.type {
	case .PLUS, .MINUS, .STAR, .SLASH:
		return p->parse_binary_expression(left, current_binding_power)

	case:
		panic("parse infix expression: Unexpected token")
	}
}

parser_parse_binary_expression :: proc(p: ^Parser, left: Expr, current_binding_power: int) -> Expr {
	context.allocator = context.temp_allocator
	op := p.current_token.lexeme

	shadow_left := new(Expr)
	shadow_left^ = left

	right := new(Expr)
	right^ = p->parse_expression(current_binding_power)
	return BinaryExpr{left = shadow_left, operator =op, right = right}
}
