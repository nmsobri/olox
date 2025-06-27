package parser

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
