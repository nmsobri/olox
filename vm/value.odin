package vm

Value :: union {
	f64,
}

ValueArray :: struct {
	values:                 [dynamic]Value,
	using value_array_proc: ValueArrayProc,
}

ValueArrayProc :: struct {
	write: proc(va: ^ValueArray, val: Value),
	value: proc(va: ^ValueArray, position: u8) -> Value,
	free:  proc(va: ^ValueArray),
}


value_array_new :: proc() -> ^ValueArray {
	va := new(ValueArray)
	va.values = make([dynamic]Value)

	va.write = value_array_write
	va.free = value_array_free
	va.value = value_array_value

	return va
}


value_array_write :: proc(va: ^ValueArray, val: Value) {
	append(&va.values, val)
}

value_array_free :: proc(va: ^ValueArray) {
	if va != nil {
		delete(va.values)
		free(va)
	}
}
value_array_value :: proc(va: ^ValueArray, position: u8) -> Value {
	return va.values[position]
}
