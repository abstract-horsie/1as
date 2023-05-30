use fmt;
use bufio;
use isa;
use isa::riscv;
use isa::gen;
use io;
use lexer;
use parser;
use strconv;
use endian;
use map;
use util;

export fn init(arch: isa::arch, ast: []parser::leaf, tab: map::hashmap) codegen = {
	return codegen{
		ast = ast,
		symtab = tab,
		code = bufio::dynamic(io::mode::WRITE),
		ctx = context{
			arch = arch,
			addr = isa::addr_init(arch),
			buf = [0...],
		}
	};
};

export fn fini(g: *codegen) void = io::close(&g.code)!;

export fn gen(g: *codegen) []u8 = {
	let lastsect: u32 = 0;
	let lastref: u32 = 0;
	for (let i = 0z; i < len(g.ast); i += 1) {
		const leaf = g.ast[i];
		switch (leaf.id) {
		case parser::leafid::INSTRUCTION =>
			let ops: []isa::operand = alloc([], len(leaf.inst.ops));
			defer free(ops);
			for (let i = 0z; i < len(leaf.inst.ops); i += 1) {
				match (leaf.inst.ops[i]) {
				case let n: isa::operand =>
					append(ops, n);
				case =>
					fmt::fatal("Identifiers not supported as arguments");
				};
			};
			isa::addr_addto(
				&g.ctx.addr,
				isa::gen::inst(g.ctx.arch, &g.code,
					leaf.inst.base, ops)
			);

		case parser::leafid::REFERENCE =>
			let it = map::find(g.symtab, leaf.ref) as *map::item;
			it.ent.loc = g.ctx.addr;
			if (lastref != 0) {
				let lit = map::find(g.symtab, lastref)
					as *map::item;
				lit.ent.sz = isa::addr_diff(
					g.ctx.addr, lit.ent.loc);
			} else {
				lastref = it.hash;
			};

		case parser::leafid::SECTION =>
			let it = map::find(g.symtab, leaf.section)
				as *map::item;
			it.ent.loc = g.ctx.addr;
			if (lastsect == 0) {
				lastsect = it.hash;
			} else {
				let lit = map::find(g.symtab, lastsect)
					as *map::item;
				lit.ent.sz = isa::addr_diff(
					g.ctx.addr, lit.ent.loc);
			};
			if (lastref != 0) {
				let lit = map::find(g.symtab, lastref)
					as *map::item;
				lit.ent.sz = isa::addr_diff(
					g.ctx.addr, lit.ent.loc);
			};

		case parser::leafid::DEFINE =>
			switch (leaf.define.align) {
			case 1 =>
				io::write(&g.code, leaf.define.data._1)!;
				const len_def = len(leaf.define.data._1);
				isa::addr_addto(&g.ctx.addr, len_def);
			case => fmt::fatal("not ok lol");
			};

		case =>
			fmt::fatal("ok lol");
		};
	};

	return bufio::buffer(&g.code);
};
