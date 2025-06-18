package vm

import fmt "core:fmt"

Line :: struct {
    line: int,
    offset: int
}

Chunk :: struct {
    code: [dynamic]u8,
    using chunk_proc: chunk_proc,
    constants: ^ValueArray,
    lines: [dynamic]Line
}

chunk_proc :: struct {
    write : proc(chunk:^Chunk, data:u8, line:int),
    free : proc(chunk:^Chunk),
    dissassemble: proc(chunk:^Chunk, name:string),
    dissassemble_instruction: proc(chunk:^Chunk, offset:int) -> int,
    simple_instruction: proc(chunk:^Chunk, name: string, offset:int)->int,
    constant_instruction: proc(chunk:^Chunk, name:string, offset:int) -> int,
    add_constant: proc(chunk:^Chunk, value:Value) -> u8,
    line: proc(chunk:^Chunk, offset:int) -> int,
}

chunk_new :: proc() -> ^Chunk {
    chunk := new(Chunk);
    chunk.code = make([dynamic]u8);
    chunk.constants = value_array_new();
    chunk.lines = make([dynamic]Line)

    chunk.write = chunk_write
    chunk.free = chunk_free
    chunk.dissassemble = chunk_dissassemble
    chunk.dissassemble_instruction = chunk_dissassemble_instruction
    chunk.simple_instruction = chunk_simple_instruction
    chunk.constant_instruction = chunk_constant_instruction
    chunk.add_constant = chunk_add_constant
    chunk.line = chunk_line

    return chunk;
}

chunk_write :: proc(chunk: ^Chunk, data: u8, line: int) {
    current_offset := len(chunk.code)
    append(&chunk.code, data)

    if len(chunk.lines) == 0 || chunk.lines[len(chunk.lines)-1].line != line{
        append(&chunk.lines, Line{line = line, offset = current_offset})
    }
}

chunk_free :: proc(chunk: ^Chunk) {
    if chunk != nil {
        chunk.constants->free()
        delete(chunk.code);
        free(chunk);
    }
}

chunk_dissassemble:: proc( chunk: ^Chunk, name: string) {
    fmt.printfln("== %s ==", name);

    for offset := 0; offset < len(chunk.code); {
        offset = chunk->dissassemble_instruction(offset);
    }
}
chunk_dissassemble_instruction:: proc(chunk: ^Chunk, offset: int) -> int{
    fmt.printf("%04d ", offset);
    fmt.printf("%d ", chunk->line(offset));
    instruction := chunk.code[offset]

    switch OpCode(instruction) {
        case .OP_RETURN: return chunk->simple_instruction("OP_RETURN", offset);
        case .OP_CONSTANT: return chunk->constant_instruction("OP_CONSTANT", offset);
        case .OP_NEGATE: return chunk->simple_instruction("OP_NEGATE", offset);
        case .OP_ADD: return chunk->simple_instruction("OP_ADD", offset);
        case .OP_SUBTRACT: return chunk->simple_instruction("OP_SUBSTRACT", offset);
        case .OP_MULTIPLY: return chunk->simple_instruction("OP_MULTIPLY", offset);
        case .OP_DIVIDE: return chunk->simple_instruction("OP_DIVIDE", offset);

        case:{
            fmt.printfln("Unknown opcode %d", instruction);
            return offset + 1;
        }
    }
}

chunk_simple_instruction :: proc(chunk: ^Chunk, name: string, offset: int)->int {
    fmt.printf("%-26s", name);
    return offset + 1; // opcode only
}

chunk_constant_instruction :: proc(chunk: ^Chunk, name: string, offset:int)->int {
    constant := chunk.code[offset + 1];
    fmt.printf("%-16s %4d '%g'", name, constant, chunk.constants->value(constant));
    return offset + 2; // opcode and operand
}

chunk_add_constant :: proc(chunk:^Chunk, value:Value) -> u8 {
    append(&chunk.constants.values, value)
    return u8(len(chunk.constants.values) - 1); // return the location of the constant
}

chunk_line :: proc(chunk: ^Chunk, offset: int) -> int {
    for i := len(chunk.lines) - 1; i >= 0; i -= 1 {
        if offset >= chunk.lines[i].offset {
            return chunk.lines[i].line
        }
    }

    return 1
}
