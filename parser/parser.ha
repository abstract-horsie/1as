use fmt;
use strings;
use strconv;
use lexer;
use endian;
use io::{EOF};
use isa;
use util;
use map;

export fn init(l: *lexer::lexer) parser = {
	return parser {
		lexer = l,
		table = [[]...],
		state = state::NONE,
	};
};

export fn fini(p: *parser) void = map::finish(&p.table);

export fn parse(p: *parser) ([]leaf | []error) = {
	let ast: []leaf = [];
	let errs: []error = [];

	for (true) match (next(p)) {
	case let l: leaf => append(ast, l);
	case let e: error => append(errs, e);
	case EOF => break;
	};

	if (len(errs) != 0) {
		free(ast);
		return errs;
	} else {
		return ast;
	};
};

export fn next(p: *parser) (leaf | EOF | error) = {
	let builder = leaf{id = leafid::END_OF_STATEMENT, nothing = 0};
	for (true) {
		const tok = match(lexer::scan(p.lexer)) {
		case let t: lexer::token => yield t;
		case EOF => return EOF;
		};
		switch (p.state) {
		case state::NONE =>
			switch (tok.id) {
			case lexer::tokid::INSTRUCTION =>
				p.state = state::INSTRUCTION;
				const op = isa::mkinstbase(
					p.lexer.arch, tok.extra as u32);
				builder = leaf{
					id = leafid::INSTRUCTION,
					inst = l_inst{
						base = op,
						ops = [],
					},
				};
			case lexer::tokid::SECTION =>
				p.state = state::SECTION;
			case lexer::tokid::DEFINE =>
				p.state = state::DEFINE;
				return leaf{
					id = leafid::DEFINE,
					ref = tok.extra: u32,
					...
				};
			case lexer::tokid::REFERENCE =>
				p.state = state::REFERENCE;
			case lexer::tokid::DEFINE =>
				builder = leaf{
					id = leafid::DEFINE,
					define = l_def{
						align = tok.extra: u8,
						...
						},
				};
				switch (tok.extra: u8) {
				case 1 => builder.define.data._1 = [];
				case 2 => builder.define.data._2 = [];
				case 4 => builder.define.data._4 = [];
				case 8 => builder.define.data._8 = [];
				};
				p.state = state::DEFINE;
			case =>
				return (tok.loc_usr, tok.id, 0): expected_toplevel;
			};

		case state::INSTRUCTION =>
			switch (tok.id) {
			case lexer::tokid::REGISTER =>
				p.state = state::INST_SEP;
				append(builder.inst.ops, tok.extra: u8: isa::register);
			case lexer::tokid::NUMBER =>
				p.state = state::INST_SEP;
				const imm = lexer::tok_getname(p.lexer, tok);
				// TODO: Check for errors.
				const imm = strconv::stoi16(imm) as i16;
				append(builder.inst.ops, imm);
			case lexer::tokid::NAME =>
				p.state = state::INST_SEP;
				const name = lexer::tok_getname(p.lexer, tok);
				append(builder.inst.ops, name);
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_op;
			};

		case state::INST_SEP =>
			switch (tok.id) {
			case lexer::tokid::COMMA =>
				p.state = state::INSTRUCTION;
			case lexer::tokid::NEWLINE =>
				p.state = state::NONE;
				return builder;
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_sep;
			};

		case state::SECTION =>
			switch (tok.id) {
			case lexer::tokid::NAME =>
				p.state = state::NEWLINE;
				const nm = lexer::tok_getname(p.lexer, tok);
				match (map::get(p.table, nm)) {
				case let item: *map::item =>
					item.ent.name = nm;
					item.ent.ident = map::ident::SECTION;
					return leaf{
						id = leafid::SECTION,
						section = item.hash,
					};
				case =>
					const ent = map::entry{
						ident = map::ident::SECTION,
						name = nm,
						...
					};
					const h = map::add(
						&p.table, nm, ent);
					return leaf{
						id = leafid::SECTION,
						section = h,
					};
				};
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_name;
			};

		case state::REFERENCE =>
			switch (tok.id) {
			case lexer::tokid::NAME =>
				p.state = state::NEWLINE;
				const nm = lexer::tok_getname(p.lexer, tok);
				match (map::get(p.table, nm)) {
				case let item: *map::item =>
					item.ent.name = nm;
					item.ent.ident = map::ident::REFERENCE;
					return leaf{
						id = leafid::REFERENCE,
						ref = item.hash,
					};

				case =>
					const ent = map::entry{
						ident = map::ident::REFERENCE,
						name = nm,
						...
					};
					const h = map::add(
						&p.table, nm, ent);
					return leaf{
						id = leafid::REFERENCE,
						ref = h,
					};
				};
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_name;
			};

		case state::DEFINE =>
			switch (tok.id) {
			case lexer::tokid::NUMBER =>
				const imm = lexer::tok_getname(p.lexer, tok);
				switch (builder.define.align) {
				case 1 =>
					const imm = strconv::stou8(imm) as u8;
					append(builder.define.data._1, imm);
				case 2 =>
					const imm = strconv::stou16(imm) as u16;
					append(builder.define.data._2, imm);
				case 4 =>
					const imm = strconv::stou32(imm) as u32;
					append(builder.define.data._4, imm);
				case 8 =>
					const imm = strconv::stou64(imm) as u64;
					append(builder.define.data._8, imm);
				};
				p.state = state::DEF_SEP;
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_num;
			};

		case state::DEF_SEP =>
			switch (tok.id) {
			case lexer::tokid::COMMA =>
				p.state = state::DEFINE;
			case lexer::tokid::NEWLINE =>
				p.state = state::NONE;
				return builder;
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_sep;
			};

		case state::NEWLINE =>
			switch (tok.id) {
			case lexer::tokid::NEWLINE =>
				p.state = state::NONE;
				//return leaf{id = leafid::END_OF_STATEMENT, ...};
			case =>
				p.state = state::NONE;
				return (tok.loc_usr, tok.id, 0): expected_newline;
			};
		};
	};

	return EOF;
};
