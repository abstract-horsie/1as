# Structure of the Assembler

## The Lexer
Lexer (a.k.a. scanner) is a global construct that lexes the needed tokens
for the specified architecture: be it `risc-v`, `x86`, or `aarch64`. The
provided function (`lex()`) takes in the source file in runes (`[]rune`) and
an architecture type (`arch`).

## The Parser

`parse(isa: arch, src: []rune, toks: []token)`

## The Code Generator

`codegen(isa: arch, src: []rune, toks: []token, ast: tree)`

## The Abstract Machine Code (AMC)

`elf_mkobj(isa: arch, src: []rune, code: code)`
`pe_mkobj(isa: arch, src: []rune, code: code)`
