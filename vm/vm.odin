package vm

STACK_MAX :: 256
DEBUG_TRACE_EXECUTION :: true

import fmt "core:fmt"
import compiler "../compiler"
import lexer "../lexer"
import parser "../parser"

InterpretResult :: enum u8 {
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR
}

Vm :: struct {
    ip: [^]byte,
    chunk: ^Chunk,
    sp: int,
    stack: [STACK_MAX]Value,
    using vmproc: VmProc
}

VmProc :: struct {
    free: proc(vm: ^Vm),
    read_byte: proc(vm: ^Vm) -> byte,
    read_constant: proc(vm: ^Vm) -> Value,
    run: proc(vm: ^Vm) -> InterpretResult,
    interpret: proc(vm: ^Vm, source: []byte) -> InterpretResult,
    pop: proc(vm: ^Vm) -> Value,
    push: proc(vm: ^Vm, value: Value),
}

vm:Vm

vm_new :: proc() -> ^Vm {
    vm.free = vm_free
    vm.read_byte = vm_read_byte
    vm.run = vm_run
    vm.interpret = vm_interpret
    vm.read_constant = vm_read_constant
    vm.pop = vm_pop
    vm.push = vm_push
    vm.ip = nil
    vm.sp = 0

    return &vm
}

vm_free :: proc(vm: ^Vm) {

}

vm_interpret :: proc(v: ^Vm, source: []byte) -> InterpretResult {
    l := lexer.lexer_new(source)
    defer l->free()

    p := parser.parser_new(l)
    p->parse_program()

    // c := compiler.compiler_new(l)
    // defer c->free()

    // c->compile()

     return .INTERPRET_OK
}

vm_run :: proc(v: ^Vm) -> InterpretResult {
    for {
        offset := uintptr(v.ip) - uintptr(raw_data(v.chunk.code))
        instruction := v->read_byte()

        switch OpCode(instruction) {
            case .OP_RETURN: {
                trace_execution(offset)
                val := v->pop()
                fmt.println(val)
                return .INTERPRET_OK
            }

            case .OP_CONSTANT: {
                constant := v->read_constant()
                v->push(constant)
            }

            case .OP_NEGATE: v->push(-(v->pop().(f64)))


            case .OP_ADD : {
                right := v->pop().(f64)
                left := v->pop().( f64)
                v->push(left + right)
            }

            case .OP_SUBTRACT: {
                right := v->pop().(f64)
                left := v->pop().(f64)
                v->push(left - right)
            }

            case .OP_MULTIPLY: {
                right := v->pop().(f64)
                left := v->pop().(f64)
                v->push(left * right)
            }

            case .OP_DIVIDE: {
                right := v->pop().(f64)
                left := v->pop().(f64)
                v->push(left / right)
            }

            case: {
                fmt.printfln("Unknown opcode %d", instruction)
                return .INTERPRET_RUNTIME_ERROR
            }
        }

        trace_execution(offset)
    }
}

vm_read_byte :: proc(v: ^Vm) -> byte {
    result := v.ip[0]
    v.ip = v.ip[1:]
    return result
}

vm_read_constant :: proc(v: ^Vm) -> Value {
    constant_value := v.chunk.constants.values[v->read_byte()]
    return constant_value
}

vm_push :: proc(v: ^Vm, value: Value) {
    v.stack[v.sp] = value
    v.sp += 1
}

vm_pop :: proc(v: ^Vm) -> Value {
    v.sp -= 1
    return v.stack[v.sp]
}

trace_execution :: proc(offset: uintptr) {
    when DEBUG_TRACE_EXECUTION {
        vm.chunk->dissassemble_instruction(int(offset));

        fmt.print("     ");

        for  slot := 0; slot < vm.sp; slot += 1 {
            fmt.printf("[ ");
            fmt.print(vm.stack[slot]);
            fmt.printf(" ]");
        }
    }

    fmt.println()
}