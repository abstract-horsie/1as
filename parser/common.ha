use lexer::{lexer};
use isa;
use map;

export type parser = struct {
	lexer: *lexer,
	table: map::hashmap,
	state: state,
};

// Leaf/AST node identifiers.
export type leafid = enum u8 {
	INSTRUCTION,
	REFERENCE,
	SECTION,
	DEFINE,

	END_OF_STATEMENT,
};

export type leaf = struct {
	id: leafid,
	union {
		// Instruction represented as bytes (in the target endianness).
		inst: l_inst, // id == INSTRUCTION;
		// Reference (more commonly known as a label) represented as
		// a FNV-1a hash locatable in the symbol table.
		ref: u32, // id == REFERENCE;
		// Same as above but for sections.
		section: u32, // id == SECTION;
		// Define statements represented as alignment ([0]) and the
		// data ([1..])
		define: l_def, // id == DEFINE;
		// Literally nothing (MUST be 0).
		nothing: u8, // id == END_OF_STATEMENT;
	},
};

export type operand = (...isa::operand | str);

export type l_inst = struct {
	base: ([]u8 | u32),
	ops: []operand,
};

export type l_def = struct {
	align: u8, // ALLOWED VALUES: 1, 2, 4, and 8;
	data: union {
		_1: []u8,
		_2: []u16,
		_4: []u32,
		_8: []u64,
	},
};

export type state = enum {
	NONE,
	INSTRUCTION,
	INST_SEP,
	SECTION,
	REFERENCE,
	DEFINE,
	DEF_SEP,

	NEWLINE,
};

// Describes the parse tree/AST of the supplied source file/lexemes/tokens.
export type tree = struct {
	leaves: []leaf,
	table: map::hashmap, // symbol table.
};
