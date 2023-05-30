use bufio;
use strconv;
use strings;
use endian;
use parser;
use isa;
use map;

export type codegen = struct {
	ast: []parser::leaf,
	symtab: map::hashmap,
	code: bufio::memstream,
	ctx: context,
	// TODO: jump table
};

export type context = struct {
	arch: isa::arch,
	addr: isa::addr,
	buf: [16]u8,
};
