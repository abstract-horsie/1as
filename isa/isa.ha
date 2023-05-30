use fmt;
use bufio;
use math;

export type arch = enum u8 {
	RISCV32,
	RISCV64,
	X86,
	X86_64,
	AARCH32,
	AARCH64,
};

export type addr = (u64 | u32 | u16 | u8);
export type addr_rep = struct {
	id: uint,
	data: union {
		_u8: u8,
		_u16: u16,
		_u32: u32,
		_u64: u64,
	},
};

export type register = u8;
export type operand = (u8 | u16 | u32 | u64 | i8 | i16 | i32 | i64 | register);

// Makes a instruction baseplate. Returned slices MUST be deallocated (freed).
// Slices are returned when the ISA is a complex instruction set (CISC), and
// a `u32` is returned when the ISA is a reduced instruction set (RISC).
export fn mkinstbase(isa: arch, inst_hint: u32) ([]u8 | u32) =
	switch (isa) {
	case arch::RISCV32, arch::RISCV64, arch::AARCH32, arch::AARCH64 =>
		return inst_hint;
	case =>
		fmt::fatal("x86 (and x64) is not yet supported...");
	};

export fn addr_init(isa: arch) addr = {
	switch (isa) {
	case arch::RISCV32, arch::AARCH32, arch::X86 => return 0: u32;
	case arch::RISCV64, arch::AARCH64, arch::X86_64 => return 0: u64;
	};
};

export fn addr_diff(a: addr, b: addr) addr = {
	match (a) {
	case let a32: u32 =>
		match (b) {
		case let b32: u32 => return a32 - b32;
		case => fmt::fatal("Ok");
		};
	case => fmt::fatal("Ok");
	};
};

export fn addr_addto(a: *addr, b: addr) void = {
	match (*a) {
	case let a8: u8 =>
		return *a = a8 + (b as u8);
	case let a16: u16 =>
		return *a = a16 + (b as u16);
	case let a32: u32 =>
		return *a = a32 + (b as u32);
	case let a64: u64 =>
		return *a = a64 + (b as u64);
	};
};
