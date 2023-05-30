use bufio;
use io;
use isa;
use isa::riscv::*;
use fmt;
use endian;
use util;

export fn riscv_inst(
	out: *bufio::memstream,
	base: u32,
	ops: []isa::operand,
) size = {
	let inst: [4]u8 = [0...];

	switch (base) {
	// 3 Operand Instructions
	case INST_ADDI =>
		if (len(ops) != 3)
			fmt::fatal("Not given enough operands (needed 3)");

		const rd = ops[0] as isa::register: u8;
		const rs1 = ops[1] as isa::register: u8;
		const imm = ops[2] as i16;
		const op = inst_itype(base, rd, rs1, imm);
		util::oputu32(util::order::LITTLE, inst[0..], op);

	// 0 Operand Instructions
	case INST_ECALL, INST_WFI =>
		util::oputu32(util::order::LITTLE, inst[0..], base);

	case =>
		fmt::fatal("GIVEN INST:", base);
	};

	// TODO: if (io::write(&out, inst) != 4);
	return io::write(out, inst)!;
};

// Generates an I-Type Instruction.
fn inst_itype(base: u32, rd: u8, rs1: u8, imm: i16) u32 =
	((imm: u32) << 20) | ((rs1: u32) << 15) | ((rd: u32) << 7) | base;
