use bufio;
use isa;
use isa::riscv;

export fn inst(
	arch: isa::arch,
	out: *bufio::memstream,
	inst: ([]u8 | u32),
	ops: []isa::operand,
) size = {
	switch (arch) {
	case isa::arch::RISCV32, isa::arch::RISCV64 =>
		return riscv_inst(out, inst as u32, ops);
	};
};
