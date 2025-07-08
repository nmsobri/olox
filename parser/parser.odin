package parser
import lex "../lexer"
import fmt "core:fmt"
import "core:mem"

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
	expect_token:               proc(p: ^Parser, token: lex.TokenType) -> lex.Token,
}

Parser :: struct {
	lexer:             ^lex.Lexer,
	current_token:     lex.Token,
	allocator:         mem.Allocator,
	using parser_proc: parser_proc,
}

parser_new :: proc(lexer: ^lex.Lexer, allocator: mem.Allocator) -> ^Parser {
	p := new(Parser, allocator)

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
	p.expect_token = parser_expect_token
	p.allocator = allocator

	p->next_token()
	return p
}

parser_parse_program :: proc(p: ^Parser) -> Program {
	program := Program {
		statements = make([dynamic]Statement, p.allocator),
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
	ident := p->expect_token(.IDENTIFIER)
	p->expect_token(.EQUAL)
	p->next_token()
	val := p->parse_expression(0)

	return VarStmt{name = ident.lexeme, value = val}
}

parser_parse_expression_statement :: proc(p: ^Parser) -> ExprStmt {
	expression := p->parse_expression(0)
	return ExprStmt{expression = expression}
}

parser_parse_expression :: proc(p: ^Parser, current_binding_power: int) -> Expr {
	left: Expr = p->parse_prefix_expression()

	next_binding_power := lex.BindingPower[p->peek_token().type]

	for next_binding_power > current_binding_power {
		p->next_token()
		left = p->parse_infix_expression(left, next_binding_power)
		next_binding_power = lex.BindingPower[p->peek_token().type]
	}

	return left
}

parser_parse_prefix_expression :: proc(p: ^Parser) -> Expr {
	context.allocator = p.allocator

	#partial switch p.current_token.type {
	case .NUMBER, .STRING, .TRUE, .FALSE:
		return LiteralExpr(p.current_token.literal)

	case .LEFT_PAREN:
		// grouped expression
		p->next_token()
		expr := p->parse_expression(0)
		p->expect_token(.RIGHT_PAREN)
		return expr

	case .MINUS, .BANG:
		op := p.current_token.lexeme
		right := new(Expr)
		p->next_token()
		right^ = p->parse_expression(0)
		return UnaryExpr{operator = op, right = right}

	case:
		msg := fmt.tprintf("parser error: unexpected prefix token `%s`", p.current_token.lexeme)
		panic(msg)
	}
}

parser_parse_infix_expression :: proc(p: ^Parser, left: Expr, current_binding_power: int) -> Expr {
	#partial switch p.current_token.type {
	case .PLUS,
	     .MINUS,
	     .STAR,
	     .SLASH,
	     .BANG_EQUAL,
	     .EQUAL_EQUAL,
	     .GREATER,
	     .GREATER_EQUAL,
	     .LESS,
	     .LESS_EQUAL:
		return p->parse_binary_expression(left, current_binding_power)

	case:
		msg := fmt.tprintf("parser error: unexpected infix token `%s`", p.current_token.lexeme)
		panic(msg)
	}
}

parser_parse_binary_expression :: proc(
	p: ^Parser,
	left: Expr,
	current_binding_power: int,
) -> Expr {
	context.allocator = p.allocator
	op := p.current_token.lexeme

	shadow_left := new(Expr)
	shadow_left^ = left

	right := new(Expr)
	p->next_token()
	right^ = p->parse_expression(current_binding_power)
	return BinaryExpr{left = shadow_left, operator = op, right = right}
}

parser_next_token :: proc(p: ^Parser) -> lex.Token {
	p.current_token = p.lexer->scan_token()
	return p.current_token
}

parser_peek_token :: proc(p: ^Parser) -> lex.Token {
	lexer_next := p.lexer.next
	token := p.lexer->scan_token()

	p.lexer.next = lexer_next
	return token
}

parser_expect_token :: proc(p: ^Parser, token_type: lex.TokenType) -> lex.Token {
	if p->peek_token().type != token_type {
		fmt.eprintfln("Unexpected token: expected %s, got %s", token_type, p->peek_token().type)
		panic("Unexpected token")
	}

	return p->next_token()
}
