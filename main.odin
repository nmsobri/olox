package main

import "lox"
import "core:fmt"
import lex "lexer"
import "core:bufio"
import os "core:os"
import strings "core:strings"

main :: proc() {
    if len(os.args) > 2 {
        fmt.eprintln("Usage: olox <file>")
        os.exit(1)
    } else if len(os.args) == 2 {
        run_file(os.args[1])
    } else {
        run_prompt()
    }
}

run_file :: proc(filename: string) {
    if content , ok := os.read_entire_file(filename); ok {
        run(content)
        if lox.HadError do os.exit(1)
    } else {
        fmt.eprintln("Could not read file: ", filename)
        os.exit(1)
    }
}

run_prompt :: proc() {
    for {
        fmt.print("> ")

        reader: bufio.Reader
        bufio.reader_init(&reader, os.stream_from_handle(os.stdin))

        line, err := bufio.reader_read_string(&reader, '\n')

        if err != nil {
            if err == .EOF {
                fmt.eprintln("Bye!")
            } else {
                fmt.eprintln("Error reading input: ", err)
            }

            os.exit(1)
        }

        line = strings.trim_right(line,"\r\n" )
        run(transmute([]byte)line)
        lox.HadError = false // continue user session even there is an error
    }
}

run :: proc(content: []byte) {
    lexer := lex.lexer_new(content)
    tokens := lexer->scan_tokens()

    for &token in tokens {
        fmt.println(token->to_string())
    }
}
