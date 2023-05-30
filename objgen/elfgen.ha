use isa;
use map;
use fmt;
use format::elf;
use format::elf32;

export fn elf_gensect(
	arch: isa::arch,
	ent: map::entry
) (elf::section64 | elf32::section) = {
	switch (arch) {
	case isa::arch::RISCV32 => return elf_gensect32(ent);
	case isa::arch::RISCV64 => return elf_gensect64(ent);
	case => fmt::fatal("false");
	};
};

export fn elf_gensect32(ent: map::entry) elf32::section = {
	assert(ent.ident == map::ident::SECTION);
	return elf32::section{
		sh_type = elf::sht::PROGBITS,
		sh_offset = ent.loc as u32,
		sh_size = ent.sz as u32,
		...
	};
};

export fn elf_gensect64(ent: map::entry) elf::section64 = {
	assert(ent.ident == map::ident::SECTION);
	return elf::section64{
		sh_offset = ent.loc as u64,
		sh_size = ent.sz as u64,
		...
	};
};

export fn elf_gensym(
	arch: isa::arch,
	ent: map::entry
) (elf::sym64 | elf32::sym) = {
	switch (arch) {
	case isa::arch::RISCV32 => return elf_gensym32(ent);
	case isa::arch::RISCV64 => return elf_gensym32(ent);
	case => fmt::fatal("true");
	};
};

export fn elf_gensym32(ent: map::entry) elf32::sym = {
	assert(ent.ident == map::ident::REFERENCE);
	return elf32::sym{
		st_size = ent.sz as u32,
		...
	};
};

export fn elf_gensym64(ent: map::entry) elf::sym64 = {
	assert(ent.ident == map::ident::REFERENCE);
	return elf::sym64{
		st_size = ent.sz as u64,
		...
	};
};
