package parser

import "core:fmt"
import "core:strings"

BinaryExpr :: struct {
	left:     ^Expr,
	operator: string,
	right:    ^Expr,
}

UnaryExpr :: struct {
	operator: string,
	right:    ^Expr,
}

LiteralExpr :: union {
	f64,
	i64,
	string,
	bool,
}


Expr :: union {
	BinaryExpr,
	UnaryExpr,
	LiteralExpr,
}

VarStmt :: struct {
	name:  string,
	value: Expr,
}

ExprStmt :: struct {
	expression: Expr,
}

Statement :: union {
	VarStmt,
	ExprStmt,
}

Program :: struct {
	statements: [dynamic]Statement,
}

to_string :: proc{
	binary_expr_to_string,
	unary_expr_to_string,
	literal_expr_to_string,
	expr_to_string,
	var_stmt_to_string,
	expr_stmt_to_string,
	statement_to_string,
	program_to_string,
	binary_expr_to_string_indented,
	unary_expr_to_string_indented,
	expr_to_string_indented,
}

// Helper to create indentation
make_indent :: proc(level: int) -> string {
	indent := ""

	for i in 0..<level {
		indent = fmt.tprintf("%s  ", indent) // 2 spaces per level
	}

	return indent
}

binary_expr_to_string :: proc(expr: BinaryExpr) -> string {
	return to_string(expr, 0)
}

binary_expr_to_string_indented :: proc(expr: BinaryExpr, indent_level: int) -> string {
	indent := make_indent(indent_level)
	next_indent := indent_level + 1

	result := fmt.tprintf("BinaryExpr{{\n%s  left = %s,\n", indent, to_string(expr.left^, next_indent))
	result = fmt.tprintf("%s%s  operator = \"%s\",\n", result, indent, expr.operator)
	result = fmt.tprintf("%s%s  right = %s\n%s}", result, indent, to_string(expr.right^, next_indent), indent)

	return result
}

unary_expr_to_string :: proc(expr: UnaryExpr) -> string {
	return to_string(expr, 0)
}

unary_expr_to_string_indented :: proc(expr: UnaryExpr, indent_level: int) -> string {
	indent := make_indent(indent_level)
	next_indent := indent_level + 1

	result := fmt.tprintf("UnaryExpr{{\n%s  operator = \"%s\",\n", indent, expr.operator)
	result = fmt.tprintf("%s%s  right = %s\n%s}", result, indent, to_string(expr.right^, next_indent), indent)

	return result
}

literal_expr_to_string :: proc(expr: LiteralExpr) -> string {
	return fmt.tprintf("LiteralExpr(%v)", expr)
}

expr_to_string :: proc(expr: Expr) -> string {
	return to_string(expr, 0)
}

expr_to_string_indented :: proc(expr: Expr, indent_level: int) -> string {
	switch e in expr {
	case BinaryExpr:
		return to_string(e, indent_level)
	case UnaryExpr:
		return to_string(e, indent_level)
	case LiteralExpr:
		return to_string(e) // Literals don't need indentation
	}
	return "UnknownExpr"
}

var_stmt_to_string :: proc(stmt: VarStmt) -> string {
	return fmt.tprintf("VarStmt{{\n  name = \"%s\",\n  value = %s\n}",
	stmt.name, to_string(stmt.value, 1))
}

expr_stmt_to_string :: proc(stmt: ExprStmt) -> string {
	return fmt.tprintf("ExprStmt{{\n  expression = %s\n}",
	to_string(stmt.expression, 1))
}

statement_to_string :: proc(stmt: Statement) -> string {
	switch s in stmt {
	case VarStmt:
		return to_string(s)
	case ExprStmt:
		return to_string(s)
	}
	return "UnknownStatement"
}

program_to_string :: proc(program: Program) -> string {
	result := "[\n"
	for stmt, i in program.statements {
		if i > 0 do result = fmt.tprintf("%s,\n", result)

		stmt_str := to_string(stmt)
		lines := strings.split(stmt_str, "\n")

		for line, j in lines {
			if j > 0 do result = fmt.tprintf("%s\n", result)
			result = fmt.tprintf("%s  %s", result, line)
		}
	}
	result = fmt.tprintf("%s\n]", result)
	return result
}