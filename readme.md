# AWK Meta AWK

An AWK interpreter written in AWK. It emulates the interpreter structure from scratch while using AWK's built in string, math, and I/O primitives. The implementation reads AWK source code and executes it against input data. It includes a lexer, parser, regex engine, field splitter, virtual machine, and all built in functions. All written in AWK. By virtue of interpreting its own source code, AWK Meta AWK stands not merely as a demonstration of cleverness but as proof that AWK primitives are expressive enough to implement the full AWK language.

## On the Dilution of Meaning: A Philosophical Inquiry into Semantic Vandalism

The term "meta", from the Greek μετά, which signifies "beyond," "after," and, with a gravity borne of precision, "about itself", names not fashion but a formal relation: self reference. It is the predicate by which a system may hold and utter of itself the truths it embodies; the interpreter that reads and reenacts its own source; the tongue that prescribes its laws and thereby brings into being its own interpreter. In such cases language and machine fold inward upon themselves, and the boundary between sign and interpreter dissolves into a single, rigorous economy of meaning.

Consider, in this strict sense, the curious specimen [awk-meta.awk](./awk-meta.awk): an AWK interpreter wrought in AWK. Here is no mere metaphor but an exacting demonstration, the language enfolds its own mechanism; the interpreter is contained within the syntax that gives it life. Such instances belong to the architecture of computation itself, to the subtle edifice of logic and to the theorems that trace the limits of formal systems.

When a leviathan of commerce lays claim to this term, converting a notion that arises from analysis and proof into a gloss of branding, we confront an act that might properly be called semantic vandalism. A signifier, born of mathematical necessity and the Structure of Computation, is torn from its context and refashioned as market rhetoric. Were Gödel, Turing, or von Neumann to witness this transmutation, they would discern not ingenuity but a degradation: the careful instrument of thought reduced to a slogan, precision dissolved into the currency of persuasion.

To reclaim "meta" is, therefore, an ethical labor as much as an intellectual one. It is fidelity to the exactitude of mathematical speech and a modest form of resistance against the profanation of rigorous terms for profit. Let us refuse the surrender of those names and relations that constitute the very grammar of computation; to defend them is to defend the conditions under which clear thought is possible.

## The approach

One interpreter: the AWK interpreter. It reads AWK source, parses it into instructions, and executes those instructions against input records. No intermediate representation or silly optimization passes. The parser produces instruction sequences directly. The VM walks them once.

Everything manual in the interpreter:
- Lexer: character by character token parsing
- Parser: recursive descent producing instruction sequences
- Regex engine: Thompson's algorithm without AWK regex
- Field splitter: manual record scanning without $1, $2
- VM: instruction dispatch loop with explicit stack

Uses AWK primitives:
- String operations: substr(), index(), length()
- Math functions: sin(), cos(), atan2(), log(), exp(), sqrt()
- Array storage: AWK's associative arrays
- I/O: print(), printf(), getline(), file redirection

## The language

A POSIX subset of AWK:
- Pattern-action structure: `BEGIN`, `END`, `/regex/`, `expr { action }`
- Variables: numeric, string, associative arrays
- Fields: $0 through $n, automatic field splitting
- Built-ins: split, match, sub, gsub, substr, index, length, sprintf, printf, print
- Math: sin, cos, atan2, log, exp, sqrt, int, rand, srand
- I/O: close, file redirection, getline
- Control: if, else, while, for, next, exit, return
- Functions: user-defined and built-in

What you see is AWK. What runs is your AWK interpreter in AWK.

## The implementation

[awk-meta.awk](./awk-meta.awk) contains:

1. **Lexer**: single `lx_one` function consuming one token at a time from a byte buffer. Identifies keywords via string comparison against null-terminated keyword strings. Returns a token structure allocated from a bump arena.

2. **Parser**: recursive descent parser producing a heap-allocated instruction sequence. Each instruction is a fixed block with fields for opcode, numeric value, string pointer, and child slots. No dynamic resizing.

3. **Regex engine**: Thompson's algorithm. Character classes, alternation, grouping, quantifiers. Full ERE support without using AWK regex.

4. **Field splitter**: manual record scanning finding matches of FS regex using the regex engine. Extracts fields between matches. Stores in managed array using AWK arrays.

5. **VM**: instruction execution loop. Stack-based with explicit stack management. Opcodes: PUSH, ADD, SUB, MATCH, JUMP, JUMP_IF_FALSE, CALL, RETURN, PRINT, STORE, LOAD.

6. **Built ins**: split uses regex engine. gsub uses regex engine. sprintf uses AWK's sprintf. print uses AWK's print.

Forward calls including recursion are patched in a single pass at the end of parsing. All calling convention logic lives in three functions: `emit_fn_entry`, `emit_fn_exit`, `emit_call`. They do not duplicate each other.

Runtime provides internal functions, registered in function table and called via the VM like any other function.

## Implementation status

What the interpreter currently executes correctly, verified against [GNU Awk 5.3.2](https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.gz).

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
- Multidimensional array syntax via SUBSEP semantics: `a[i,j]`
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
- `print` / `printf` to file or pipe (`> "file"`, `| "cmd"`)
- `getline var < file`

**Program structure**
- `BEGIN { }` and `END { }` blocks
- `/regex/ { }` pattern-action rules
- Unconditional `{ }` rules
- Record dispatch loop with `NR`, `NF`, `$0`--`$NF` set per record
- Multiple input files via command-line arguments

**Lexer**
- Context sensitive `/` disambiguation: lexed as regex literal after `=` `~` `!~` `(` `,` `{` `;` `print` `return`, otherwise as division
- Backslash-newline line continuation
- Newline tolerance after continuation-sensitive operators
- Newline before `else`

**Not yet implemented**
- ~~`for (k in arr)` iteration~~
- `sub()`, `gsub()`, `match()`
- `delete arr` (whole array)
- `FILENAME`, `FS`, `OFS`, `ORS`, `RS` special variables
- ~~Pass by reference arrays in user defined functions~~

## Self-Hosting

AWK Meta AWK is self-hosting. The interpreter can interpret itself interpreting itself, at arbitrary depth, and still execute a program correctly at the bottom of the stack.

Try it:

```
./awk-meta.awk $(printf 'awk-meta.awk %.0s' {1..16}) scripts/hello.awk
```

```
./awk-meta.awk $(printf 'awk-meta.awk %.0s' {1..16}) scripts/verify.awk
```

This passes [awk-meta.awk](./awk-meta.awk) as both the interpreter and as sixteen successive layers of input. The outermost instance interprets the next, which interprets the next, down sixteen levels, until the innermost instance runs [hello.awk](scripts/hello.awk) and [verify.awk](scripts/verify.awk).

The language implemented here is expressive enough to implement itself. The interpreter is not a special case, a simplified subset, or a demonstration that happens to work on contrived input. It is a complete enough execution environment that another copy of itself can run inside it. That copy can host another and the recursion has no conceptual floor.

In practical terms this means the implementation covers the full language it claims to cover. An interpreter that silently drops half the language will fail to interpret its own source, because the source uses the language. Self-hosting finds the gaps because every construct the parser can emit must be a construct the VM can execute, because the interpreter reads itself and executes what it finds there. It took a bytecode VM, a recursive descent parser, a Thompson NFA regex engine, a manual field splitter, and a calling convention that survives re-entry through multiple interpreted layers.

The depth is not a party trick either. Sixteen levels of meta-interpretation means the bytecode for the outermost interpreter passes through fifteen interpreted dispatch loops before it executes. Each level adds a full interpreter's worth of state on the AWK associative array heap: instruction sequences, stacks, symbol tables, call frames. It is slow in the way that nested interpretation is always slow. What it is not is wrong.

## License

This project is provided under the [GPL3 License](./COPYING) Copyright (C) 2026 Ivan Gaydardzhiev
