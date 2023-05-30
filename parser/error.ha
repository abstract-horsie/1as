use lexer;
use strings;
use fmt;

// Parser error type.
export type error = !(expected_toplevel | expected_name | expected_op | 
	expected_num | expected_sep | expected_newline);

// Thrown when the parser expected another token (or tokens), but got a
// unexpected one.
//export type expected = !(lexer::location, lexer::tokid, []lexer::tokid);
export type expected = !struct {
	loc: lexer::location,
	saw: lexer::tokid,
	exp: []lexer::tokid,
};

export type expected_toplevel = !(lexer::location, lexer::tokid, u32);
export type expected_name = !(lexer::location, lexer::tokid, u32);
export type expected_op = !(lexer::location, lexer::tokid, u32);
export type expected_num = !(lexer::location, lexer::tokid, u32);
export type expected_sep = !(lexer::location, lexer::tokid, u32);
export type expected_newline = !(lexer::location, lexer::tokid, u32);
type cast_err = !(lexer::location, lexer::tokid, u32);

// Turns [[error]] into a user-readable string.
export fn strerror(err: error) str = {
	static let buf: [4096]u8 = [0...];

	const mesg: (lexer::location, str, lexer::tokid) = match (err) {
	case let e: expected_toplevel =>
		yield (e.0, "Expected a top-level expression", e.1);
	case let e: expected_name =>
		yield (e.0, "Expected an name", e.1);
	case let e: expected_op =>
		yield (e.0, "Expected an operand", e.1);
	case let e: expected_num =>
		yield (e.0, "Expected a number", e.1);
	case let e: expected_sep =>
		yield (
			e.0,
			"Expected a comma or a termination of the statement",
			e.1
		);
	case let e: expected_newline =>
		yield (e.0, "Expected a termination of the statement", e.1);
	};

	const _str = fmt::bsprintf(buf[..],
		"[{}:{}]: {} but found a/an {}",
		mesg.0.line,
		mesg.0.character,
		mesg.1,
		lexer::strtokid(mesg.2));

	return _str;
};

