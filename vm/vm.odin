package vm

STACK_MAX :: 256
DEBUG_TRACE_EXECUTION :: true

import fmt "core:fmt"

InterpretResult :: enum u8 {
    INTERPRET_OK,
    INTERPRET_COMPILE_ERROR,
    INTERPRET_RUNTIME_ERROR
}

Vm :: struct {
    ip: [^]u8,
    chunk: ^Chunk,
    sp: int,
    stack: [STACK_MAX]Value,
    using vmproc: VmProc
}

VmProc :: struct {
    free: proc(vm: ^Vm),
    read_byte: proc(vm: ^Vm) -> u8,
    read_constant: proc(vm: ^Vm) -> Value,
    run: proc(vm: ^Vm) -> InterpretResult,
    interpret: proc(vm: ^Vm, chunk: ^Chunk) -> InterpretResult,
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

vm_interpret :: proc(vm: ^Vm, chunk: ^Chunk) -> InterpretResult {
    vm.chunk = chunk
    vm.ip = raw_data(vm.chunk.code)
    return vm->run()
}

vm_run :: proc(vm: ^Vm) -> InterpretResult {
    for {
        offset := uintptr(vm.ip) - uintptr(raw_data(vm.chunk.code))
        instruction := vm->read_byte()

        switch OpCode(instruction) {
            case .OP_RETURN: {
                trace_execution(offset)
                val := vm->pop()
                fmt.println(val)
                return .INTERPRET_OK
            }

            case .OP_CONSTANT: {
                constant := vm->read_constant()
                vm->push(constant)
            }

            case .OP_NEGATE: vm->push(-(vm->pop()))


            case .OP_ADD : {
                right := vm->pop()
                left := vm->pop()
                vm->push(left + right)
            }

            case .OP_SUBTRACT: {
                right := vm->pop()
                left := vm->pop()
                vm->push(left - right)
            }

            case .OP_MULTIPLY: {
                right := vm->pop()
                left := vm->pop()
                vm->push(left * right)
            }

            case .OP_DIVIDE: {
                right := vm->pop()
                left := vm->pop()
                vm->push(left / right)
            }

            case: {
                fmt.printfln("Unknown opcode %d", instruction)
                return .INTERPRET_RUNTIME_ERROR
            }
        }

        trace_execution(offset)
    }
}

vm_read_byte :: proc(vm: ^Vm) -> u8 {
    result := vm.ip[0]
    vm.ip = vm.ip[1:]
    return result
}

vm_read_constant :: proc(vm: ^Vm) -> Value {
    constant_value := vm.chunk.constants.values[vm->read_byte()]
    return constant_value
}

vm_push :: proc(vm: ^Vm, value: Value) {
    vm.stack[vm.sp] = value
    vm.sp += 1
}

vm_pop :: proc(vm: ^Vm) -> Value {
    vm.sp -= 1
    return vm.stack[vm.sp]
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