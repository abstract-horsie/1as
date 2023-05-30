use format::elf;

export type header = struct {
	e_ident: [elf::EI_NIDENT]u8,
	e_type: elf::elf_type,
	e_machine: elf::elf_machine,
	e_version: u32,
	e_entry: u32,
	e_phoff: u32,
	e_shoff: u32,
	e_flags: u32,
	e_ehsize: u16,
	e_phentsize: u16,
	e_phnum: u16,
	e_shentsize: u16,
	e_shnum: u16,
	e_shstrndx: u16,
};

export type section = struct {
	sh_name: u32,
	sh_type: u32,
	sh_flags: u32,
	sh_addr: u32,
	sh_offset: u32,
	sh_size: u32,
	sh_link: u32,
	sh_info: u32,
	sh_addralign: u32,
	sh_entsize: u32,
};

export type sym = struct {
	st_name: u32,
	st_value: u32,
	st_size: u32,
	st_info: u8,
	st_other: u8,
	st_shndx: u16,
};
