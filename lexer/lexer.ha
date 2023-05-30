use ascii;
use fmt;
use isa;
use isa::riscv;
use strings;
use io::{EOF};
use encoding::utf8;

// Initializes a lexer. Use [[lexer::fini]] to free the allocated runes.
// Or use `free(lexer.src)`.
export fn init(
	src: []const u8,
	arch: isa::arch,
	filename: str
) (lexer | utf8::invalid) = {
	const src = strings::try_fromutf8(src)?;
	const src = strings::runes(src);
	return lexer {
		src = src,
		arch = arch,
		filename = filename,
		ix = 0z,
		loc = location {line = 1, character = 1},
	};
};

export fn fini(l: *lexer) void = free(l.src);

export fn scan(l: *lexer) (token | EOF) = {
	let st = state::NONE;
	let loc0 = 0z;

	for (l.ix < len(l.src); l.ix += 1) {
		const c = l.src[l.ix];
		switch (st) {
		case state::NONE =>
			if (isnamestart(c)) {
				loc0 = l.ix;
				st = state::NAME;
				l.loc.character += 1;
			} else if (c == '0') {
				st = state::ZERO;
				l.loc.character += 1;
			} else if (ascii::isdigit(c)) {
				loc0 = l.ix;
				st = state::DIGIT;
			} else switch (c) {
			case ' ', '\r', '\f', '\v' =>
				l.loc.character += 1;
			case '\t' =>
				l.loc.character += 8;
			case '\n' =>
				const lastloc = l.loc;
				const tok = mktok(tokid::NEWLINE, loc0, l.loc);
				l.loc.character = 0;
				l.loc.line += 1;
				l.ix += 1;
				return tok;
			case '@' =>
				const lastloc = l.loc;
				l.loc.character += 1;
				l.ix += 1;
				return mktok(tokid::AT, loc0, lastloc);
			case ',' =>
				const lastloc = l.loc;
				l.loc.character += 1;
				l.ix += 1;
				return mktok(tokid::COMMA, loc0, l.loc);
			case '\0' =>
				return void: EOF;
			};

		case state::NAME =>
			if (isname(c)) l.loc.character += 1
			else match (iskeyword(l.arch, l.src[loc0..l.ix])) {
			case let k: (tokid, u32) =>
				return mktokex(k.0, k.1, loc0, l.loc);
			case =>
				return mktokex(tokid::NAME,
					l.ix, loc0, l.loc);
			};

		case state::DIGIT =>
			if (ascii::isdigit(c)) l.loc.character += 1
			else return mktokex(tokid::NUMBER, l.ix, loc0, l.loc);

		case state::ZERO =>
			fmt::fatal("Hexa-octal-binary numbers not implemented");
		};
	};

	if (l.ix == len(l.src)) {
		switch (st) {
		case state::NONE => void;
		case state::NAME =>
			match (iskeyword(l.arch, l.src[loc0..l.ix])) {
			case let k: (tokid, u32) =>
				return mktokex(k.0, k.1, loc0, l.loc);
			case =>
				return mktokex(tokid::NAME, l.ix, loc0, l.loc);
			};
		case state::DIGIT, state::ZERO, state::HEXADECIMAL =>
			return mktokex(tokid::NUMBER, l.ix, loc0, l.loc);
		};

		l.ix += 1;
	};

	return EOF;
};

fn iskeyword(arch: isa::arch, name: []rune) ((tokid, u32) | void) = {
	const name = fromrunes_fast(name);

	switch (arch) {
	case isa::arch::RISCV32, isa::arch::RISCV64 =>
		match (isa::riscv::isreg(name)) {
		case let data: u32 => return (tokid::REGISTER, data);
		case => void;
		};
		match (isa::riscv::isinst(name)) {
		case let data: u32 => return (tokid::INSTRUCTION, data);
		case => void;
		};

	case => fmt::fatal("ISA Not Implemented");
	};

	return isbuiltin(name);
};

// Turns a slice of runes into a string.
//
// This version of `fromrunes` uses a static array of bytes instead of an
// dynamic slice used by [[strings::fromrunes]]. This way of handling strings
// is quite limited (limited to 256 characters). But as there is no reason
// an identifier's name to be of that size, it is suitable.
fn fromrunes_fast(rs: []rune) str = {
	static let bytes: [256]u8 = [0...];
	let numbs = 0z;
	for (let i = 0z; i < len(rs); i += 1) {
		const bs = utf8::encoderune(rs[i]);
		const start = numbs; numbs += len(bs);
		bytes[start..numbs] = bs;
	};
	return strings::fromutf8_unsafe(bytes[0..numbs]);
};

fn isname(c: rune) bool =
	if (ascii::isalnum(c) || c == '_' || c == '.') true
	else false;

fn isnamestart(c: rune) bool =
	if (ascii::isalpha(c) || c == '_' || c == '.' || c == '\\') true
	else false;

fn mktok(id: tokid, loc: size, loc_usr: location) token =
	return token {
		id = id,
		extra = void,
		loc = loc,
		loc_usr = loc_usr,
	};

fn mktokex(
	id: tokid,
	ex: (u8 | u16 | u32 | u64 | i8 | i16 | i32 | i64 | size),
	loc: size,
	loc_usr: location
) token =
	return token {
		id = id,
		extra = ex,
		loc = loc,
		loc_usr = loc_usr,
	};

// Gets the name/identifier of an token of type: [[tokid::INSTRUCTION]],
// [[tokid::NUMBER]], [[tokid::SECTION]], or [[tokid::NAME]].
export fn tok_getname(l: *lexer, tok: token) str =
	switch (tok.id) {
	case tokid::INSTRUCTION, tokid::NUMBER, tokid::SECTION, tokid::NAME =>
		return strings::fromrunes(l.src[tok.loc..tok.extra as size]);
	case =>
		// Unreachable unless stupid...
		fmt::fatal("given token does not have a name");
	};

// Checks if a given `name` is a builtin keyword. a builtin keyword is a word
// which doesn't change between architectures (ISAs).
//
// Optimized to check the length first.
export fn isbuiltin(name: str) ((tokid, u32) | void) =
	switch (len(name)) {
	case 4 =>
		switch (name) {
		case "\\ref" => return (tokid::REFERENCE, 0);
		case => return;
		};
	case 5 =>
		switch (name) {
		case => return;
		case "\\func" => return (tokid::REFERENCE, 1);

		case "\\defb" => return (tokid::DEFINE, 1);
		case "\\defd" => return (tokid::DEFINE, 2);
		case "\\defq" => return (tokid::DEFINE, 4);
		case "\\defo" => return (tokid::DEFINE, 8);

		case "\\resb" => return (tokid::RESERVE, 1);
		case "\\resd" => return (tokid::RESERVE, 2);
		case "\\resq" => return (tokid::RESERVE, 4);
		case "\\reso" => return (tokid::RESERVE, 8);
		};
	case 6 =>
		switch (name) {
		case => return;
		};
	case 8 =>
		switch (name) {
		case "\\section" => return (tokid::SECTION, 0);
		case => return;
		};
	case => return;
	};

// <--------------------------------------------------------------------------->
// TEST SECTION
// <--------------------------------------------------------------------------->

@test fn lex_builtin() void = {
	const src = `, @ \db \dw \dd \dq \ref local global notype \section `
		`\declare function`;
	const src = strings::toutf8(src);

	const exp_tokids = [tokid::COMMA, tokid::AT, tokid::DEFINE,
		tokid::DEFINE, tokid::DEFINE, tokid::DEFINE, tokid::REFERENCE,
		tokid::DECLARE_BIND, tokid::DECLARE_BIND, tokid::DECLARE_TYPE,
		tokid::SECTION, tokid::DECLARE, tokid::DECLARE_TYPE];
	const exp_data: [_]size = [0, 0, 8, 16, 32, 64, 0, 0, 1, 0, 0, 0, 2];

	let lxr = init(src, isa::arch::RISCV64, "TEST FILE")!; defer fini(&lxr);
	for (let i = 0z; i < len(exp_data); i += 1) match (scan(&lxr)) {
	case let tok: token =>
		assert(tok.id == exp_tokids[i], "token `id` field is wrong");
		assert(tok.extra == exp_data[i], "token `data` field is wrong");
	case EOF =>
		break;
	};
};

@test fn lex_riscv() void = {
	const src = 
		// registers
		`x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 `
		`x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 ra sp `
		`gp tp t0 t1 t2 s0 fp s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 `
		`s6 s7 s8 s9 t3 t4 t5 t6 zero `
		// instructions
		`wfi addi ecall`;
	const src = strings::toutf8(src);

	const exp_tokids = [
		// x0 -> x17
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,

		// x18 - sp
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER,

		// gp -> s5
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER,

		// s6 -> zero
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,
		tokid::REGISTER, tokid::REGISTER, tokid::REGISTER,

		tokid::INSTRUCTION, tokid::INSTRUCTION, tokid::INSTRUCTION,
	];
	const exp_data: [_]size = [
		riscv::REG_X0, riscv::REG_X1, riscv::REG_X2, riscv::REG_X3,
		riscv::REG_X4, riscv::REG_X5, riscv::REG_X6, riscv::REG_X7,
		riscv::REG_X8, riscv::REG_X9, riscv::REG_X10, riscv::REG_X11,
		riscv::REG_X12, riscv::REG_X13, riscv::REG_X14, riscv::REG_X15,
		riscv::REG_X16, riscv::REG_X17, riscv::REG_X18, riscv::REG_X19,
		riscv::REG_X20, riscv::REG_X21, riscv::REG_X22, riscv::REG_X23,
		riscv::REG_X24, riscv::REG_X25, riscv::REG_X26, riscv::REG_X27,
		riscv::REG_X28, riscv::REG_X29, riscv::REG_X30, riscv::REG_X31,
		riscv::REG_RA, riscv::REG_SP, riscv::REG_GP, riscv::REG_TP,
		riscv::REG_T0, riscv::REG_T1, riscv::REG_T2, riscv::REG_S0,
		riscv::REG_FP, riscv::REG_S1, riscv::REG_A0, riscv::REG_A1,
		riscv::REG_A2, riscv::REG_A3, riscv::REG_A4, riscv::REG_A5,
		riscv::REG_A6, riscv::REG_A7, riscv::REG_S2, riscv::REG_S3,
		riscv::REG_S4, riscv::REG_S5, riscv::REG_S6, riscv::REG_S7,
		riscv::REG_S8, riscv::REG_S9, riscv::REG_T3, riscv::REG_T4,
		riscv::REG_T5, riscv::REG_T6, riscv::REG_ZERO,

		riscv::INST_WFI, riscv::INST_ADDI, riscv::INST_ECALL
	];

	let lxr = init(src, isa::arch::RISCV64, "TEST FILE")!; defer fini(&lxr);
	for (let i = 0z; i < len(exp_data); i += 1) match (scan(&lxr)) {
	case let tok: token =>
		assert(tok.id == exp_tokids[i], "token `id` field is wrong");
		assert(tok.extra == exp_data[i], "token `data` field is wrong");
	case EOF =>
		break;
	};
};
