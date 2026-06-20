# AWK Meta AWK

An awk interpreter written in awk. Emulates the interpreter structure from scratch while using awk's built in string, math, and I/O primitives.

The implementation reads awk source code and executes it against input data. It includes a lexer, parser, regex engine, field splitter, virtual machine, and all built in functions. All written in awk. The end goal is for AWK Meta AWK to interpret its own source code. Not only as a demonstration of cleverness but as proof that awk primitives are expressive enough to implement the full awk language.

## On the Dilution of Meaning: A Philosophical Inquiry into Semantic Vandalism

The term "meta", from the Greek μετά, which signifies "beyond," "after," and, with a gravity borne of precision, "about itself", names not fashion but a formal relation: self reference. It is the predicate by which a system may hold and utter of itself the truths it embodies; the interpreter that reads and reenacts its own source; the tongue that prescribes its laws and thereby brings into being its own interpreter. In such cases language and machine fold inward upon themselves, and the boundary between sign and interpreter dissolves into a single, rigorous economy of meaning.

Consider, in this strict sense, the curious specimen [awk-meta.awk](./awk-meta.awk): an awk interpreter wrought in awk. Here is no mere metaphor but an exacting demonstration, the language enfolds its own mechanism; the interpreter is contained within the syntax that gives it life. Such instances belong to the architecture of computation itself, to the subtle edifice of logic and to the theorems that trace the limits of formal systems.

When a leviathan of commerce lays claim to this term, converting a notion that arises from analysis and proof into a gloss of branding, we confront an act that might properly be called semantic vandalism. A signifier, born of mathematical necessity and the Structure of Computation, is torn from its context and refashioned as market rhetoric. Were Gödel, Turing, or von Neumann to witness this transmutation, they would discern not ingenuity but a degradation: the careful instrument of thought reduced to a slogan, precision dissolved into the currency of persuasion.

To reclaim "meta" is, therefore, an ethical labor as much as an intellectual one. It is fidelity to the exactitude of mathematical speech and a modest form of resistance against the profanation of rigorous terms for profit. Let us refuse the surrender of those names and relations that constitute the very grammar of computation; to defend them is to defend the conditions under which clear thought is possible.

## The approach

One interpreter: the awk interpreter. It reads awk source, parses it into instructions, and executes those instructions against input records. No intermediate representation or silly optimization passes. The parser produces instruction sequences directly. The VM walks them once.

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

[awk-meta.awk](./awk-meta.awk) will contain:

1. **Lexer**: single `lx_one` function consuming one token at a time from a byte buffer. Identifies keywords via string comparison against null-terminated keyword strings. Returns a token structure allocated from a bump arena.

2. **Parser**: recursive descent parser producing a heap-allocated instruction sequence. Each instruction is a fixed block with fields for opcode, numeric value, string pointer, and child slots. No dynamic resizing.

3. **Regex engine**: Thompson's algorithm. Character classes, alternation, grouping, quantifiers. Full ERE support without using awk regex.

4. **Field splitter**: manual record scanning finding matches of FS regex using the regex engine. Extracts fields between matches. Stores in managed array using awk arrays.

5. **VM**: instruction execution loop. Stack-based with explicit stack management. Opcodes: PUSH, ADD, SUB, MATCH, JUMP, JUMP_IF_FALSE, CALL, RETURN, PRINT, STORE, LOAD.

6. **Built ins**: split uses regex engine. gsub uses regex engine. sprintf uses awk's sprintf. print uses awk's print.

Forward calls including recursion are patched in a single pass at the end of parsing. All calling convention logic lives in three functions: `emit_fn_entry`, `emit_fn_exit`, `emit_call`. They do not duplicate each other.

Runtime provides internal functions, registered in function table and called via the VM like any other function.

## Implementation status

What the interpreter currently executes correctly, verified against GNU Awk 5.3.2.

**Expressions**
- Arithmetic: `+` `-` `*` `/` `%` `^`
- Comparison: `==` `!=` `<` `<=` `>` `>=`
- Boolean: `&&` `||` `!`
- String concatenation (juxtaposition)
- Ternary: `cond ? a : b`
- Assignment: `=` `+=` `-=` `*=` `/=` `%=` `^=`
- Increment/decrement: prefix `++x` `--x`, postfix `x++` `x--`
- Regex match: `~` `!~` with literal `/pat/` or string
- Array membership: `k in arr`
- Iteration: `for (k in arr)`
- Unary negation: `-x`

**Variables and arrays**
- Scalar variables with numeric and string semantics
- Associative arrays: `a[k] = v`, `a[k]` read, `k in a`, `delete a[k]`
- `split(str, arr)` populating an array by whitespace

**Control flow**
- `if (cond) stmt`
- `if (cond) stmt else stmt`
- `while (cond) stmt`
- `for (init; cond; post) stmt`
- All control forms accept a single statement or a `{ block }`
- `return expr` from user functions
- `next` (skip to next record)
- `exit`

**Functions**
- User defined functions with positional parameters and local variables (extra params)
- Recursion with correct parameter isolation across call depth
- Pass by reference arrays in user defined functions
- Built ins: `print`, `printf`, `sprintf` (up to 8 args), `substr`, `index`, `length`, `split`, `tolower`, `toupper`, `sin`, `cos`, `atan2`, `log`, `exp`, `sqrt`, `int`, `rand`, `srand`

**Program structure**
- `BEGIN { }` and `END { }` blocks
- `/regex/ { }` pattern-action rules
- Unconditional `{ }` rules
- Record dispatch loop with `NR`, `NF`, `$0`--`$NF` set per record
- Multiple input files via command-line arguments

**Lexer**
- Context sensitive `/` disambiguation: lexed as regex literal after `=` `~` `!~` `(` `,` `{` `;` `print` `return`, otherwise as division

**Not yet implemented**
- ~~`for (k in arr)` iteration~~
- `sub()`, `gsub()`, `match()`
- `getline` in expression context
- `delete arr` (whole array)
- `printf` / `print` to file or pipe (`> "file"`, `| "cmd"`)
- `FILENAME`, `FS`, `OFS`, `ORS`, `RS` special variables
- ~~Pass by reference arrays in user defined functions~~

## License

This project is provided under the [GPL3 License](./COPYING) Copyright (C) 2026 Ivan Gaydardzhiev
