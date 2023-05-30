use strings;
use fmt;
use isa;

export type lexer = struct {
	src: []const rune, // a story from a page.
	arch: isa::arch,
	filename: str,
	ix: size, // where are we?
	loc: location, // where are we, but on a map?
};

// Stores the user-friendly position in a file. Used for storing each
// lexeme/token's location.
export type location = struct {
	line: uint,
	character: uint,
};

// Token identifiers.
export type tokid = enum u8 {
	REGISTER,
	INSTRUCTION,
	NUMBER,
	NAME,

	SECTION,
	REFERENCE,
	DEFINE,
	RESERVE,

	COMMA, // ','
	AT,    // '@'

	NEWLINE,
	EOF,
};

// Turns a token identifier into a user-understandable string.
export fn strtokid(id: tokid) str = {
	switch (id) {
	case tokid::REGISTER => return "register";
	case tokid::INSTRUCTION => return "instruction";
	case tokid::NAME, => return "name";
	case tokid::NUMBER => return "number";
	case tokid::SECTION => return "section";
	case tokid::REFERENCE => return "reference";
	case tokid::DEFINE => return "static constant definition";
	case tokid::RESERVE => return "static constant reservation";
	case tokid::COMMA => return "','";
	case tokid::AT => return "'@'";
	case tokid::NEWLINE => return "newline";
	case tokid::EOF => return "end of file";
	case => return "unknown";
	};
};

// The output of [[lexer::lex]]. Stores data about the recognized token, where
// `loc` is the index into the file, `loc_usr` is the user-friendly
// location, and `extra` stores token identifier specific extra information.
export type token = struct {
	id: tokid,
	extra: (u8 | u16 | u32 | u64 | i8 | i16 | i32 | i64 | size | void),
	loc: size,
	loc_usr: location,
};

type state = enum u8 {
	NONE,
	NAME,

	DIGIT,
	ZERO,
	HEXADECIMAL,
};
