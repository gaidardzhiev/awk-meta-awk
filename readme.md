# AWK Meta AWK

An awk interpreter written in awk. Emulates the interpreter structure from scratch while using awk's built in string, math, and I/O primitives.

The implementation reads awk source code and executes it against input data. It includes a lexer, parser, regex engine, field splitter, virtual machine, and all built in functions. All written in awk. The end goal is for AWK Meta AWK to interpret its own source code. Not only as a demonstration of cleverness but as proof that awk primitives are expressive enough to implement the full awk language.

## The approach

One interpreter: the awk interpreter. It reads awk source, parses it into instructions, and executes those instructions against input records. No intermediate representation. No optimization passes. The parser produces instruction sequences directly. The VM walks them once.

Everything manual in the interpreter:
- Lexer: character by character token parsing
- Parser: recursive descent producing instruction sequences
- Regex engine: Thompson's algorithm without awk regex
- Field splitter: manual record scanning without $1, $2
- VM: instruction dispatch loop with explicit stack

Uses awk primitives:
- String operations: substr(), index(), length()
- Math functions: sin(), cos(), atan2(), log(), exp(), sqrt()
- Array storage: awk's associative arrays
- I/O: print(), printf(), getline(), file redirection

## The language

Full POSIX awk. Every feature:
- Pattern-action structure: `BEGIN`, `END`, `/regex/`, `expr { action }`
- Variables: numeric, string, associative arrays
- Fields: $0 through $n, automatic field splitting
- Built-ins: split, match, sub, gsub, substr, index, length, sprintf, printf, print
- Math: sin, cos, atan2, log, exp, sqrt, int, rand, srand
- I/O: close, file redirection, getline
- Control: if, else, while, for, next, exit, return
- Functions: user-defined and built-in

What you see is awk. What runs is your awk interpreter in awk.

## The implementation

[awk-meta.awk](./awk-meta.awk) is the single file. It will contain:

1. **Lexer**: single `lx_one` function consuming one token at a time from a byte buffer. Identifies keywords via string comparison against null-terminated keyword strings. Returns a token structure allocated from a bump arena.

2. **Parser**: recursive descent parser producing a heap-allocated instruction sequence. Each instruction is a fixed block with fields for opcode, numeric value, string pointer, and child slots. No dynamic resizing.

3. **Regex engine**: Thompson's algorithm. Character classes, alternation, grouping, quantifiers. Full ERE support without using awk regex.

4. **Field splitter**: manual record scanning finding matches of FS regex using the regex engine. Extracts fields between matches. Stores in managed array using awk arrays.

5. **VM**: instruction execution loop. Stack-based with explicit stack management. Opcodes: PUSH, ADD, SUB, MATCH, JUMP, JUMP_IF_FALSE, CALL, RETURN, PRINT, STORE, LOAD.

6. **Built ins**: split uses regex engine. gsub uses regex engine. sprintf uses awk's sprintf. print uses awk's print.

Forward calls including recursion are patched in a single pass at the end of parsing. All calling convention logic lives in three functions: `emit_fn_entry`, `emit_fn_exit`, `emit_call`. They do not duplicate each other.

Runtime provides internal functions, registered in function table and called via the VM like any other function.

## License

This project is provided under the [GPL3 License](./COPYING) Copyright (C) 2026 Ivan Gaydardzhiev
