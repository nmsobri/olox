package lox

import "core:os"
import "core:fmt"
import "core:bufio"
import "core:strings"

HadError : bool

error :: proc(line: int, message: string) {
    report(line, "", message)
}

report :: proc(line: int, _where: string, message: string) {
    fmt.eprintfln("[line %d] Error %s: %s", line, _where, message)
    HadError = true
}

