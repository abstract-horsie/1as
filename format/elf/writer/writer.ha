use format::elf;
use format::elf32;
use fmt;
use io;
use strio;

export type writer = struct {
	class: elf::ident_class, // 32-bit or 64-bit;
	// TODO: Program headers (also implement in elf32);
	union {
		_32: struct {
			hdr: elf32::header,
			sects: []elf32::section,
			syms: []elf32::sym,
		},
		_64: struct {
			hdr: elf::header64,
			sects: []elf::section64,
			syms: []elf::sym64,
		},
	},
	codes: [][]u8, // divided by sections with the same indice;
	shstrtab: []str,
	symstrtab: []str,
};

export fn init(
	cls: elf::ident_class,
	etype: elf::elf_type,
	data: elf::ident_data,
	mach: elf::elf_machine,
	osabi: elf::ident_abi,
) writer = {
	switch (cls) {
	case elf::ident_class::ELF32 =>
		static let hdr = elf32::header{
			e_ident = [
				0x7F, 'E', 'L', 'F',
				elf::ident_class::ELF32,
				0, elf::EV_CURRENT: u8, 0...
			],
			e_version = elf::EV_CURRENT,
			e_ehsize = size(elf32::header): u16,
			e_shentsize = size(elf32::section): u16,
			...
		};
		hdr.e_ident[elf::EI_DATA] = data;
		hdr.e_ident[elf::EI_OSABI] = osabi;
		hdr.e_type = etype;
		hdr.e_machine = mach;

		return writer{
			class = cls,
			_32 = struct {
				hdr: elf32::header = hdr,
				sects: []elf32::section = [],
				syms: []elf32::sym = [],
			},
			codes = [],
			shstrtab = [],
			symstrtab = [],
		};
	case elf::ident_class::ELF64 =>
		static let hdr = elf::header64{
			e_ident = [
				0x7F, 'E', 'L', 'F',
				elf::ident_class::ELF64,
				0, elf::EV_CURRENT: u8, 0...
			],
			e_version = elf::EV_CURRENT,
			e_ehsize = size(elf::header64): u16,
			e_shentsize = size(elf::section64): u16,
			...
		};
		hdr.e_ident[elf::EI_DATA] = data;
		hdr.e_ident[elf::EI_OSABI] = osabi;
		hdr.e_type = etype;
		hdr.e_machine = mach;

		return writer{
			class = cls,
			_64 = struct {
				hdr: elf::header64 = hdr,
				sects: []elf::section64 = [],
				syms: []elf::sym64 = [],
			},
			codes = [],
			shstrtab = [],
			symstrtab = [],
		};
	};
};

export fn fini(w: *writer) void = {
	free(w.codes);
	free(w.shstrtab);
	free(w.symstrtab);
	switch (w.class) {
	case elf::ident_class::ELF32 =>
		free(w._32.sects);
		free(w._32.syms);
	case elf::ident_class::ELF64 =>
		free(w._64.sects);
		free(w._64.syms);
	};
};

export fn writesect(
	w: *writer,
	ent: (elf::section64 | elf32::section),
	code: []u8,
	name: str,
) void = {
	switch (w.class) {
	case elf::ident_class::ELF32 =>
		const ent = ent as elf32::section;
		append(w._32.sects, ent);
		fmt::println("hel")!;
	case elf::ident_class::ELF64 =>
		const ent = ent as elf::section64;
		append(w._64.sects, ent);
	};
	append(w.codes, code);
	append(w.shstrtab, name);
};

export fn writesym(
	w: *writer,
	ent: (elf::sym64 | elf32::sym),
	name: str,
) void = {
	switch (w.class) {
	case elf::ident_class::ELF32 =>
		const ent = ent as elf32::sym;
		append(w._32.syms, ent);
	case elf::ident_class::ELF64 =>
		const ent = ent as elf::sym64;
		append(w._64.syms, ent);
	};
	append(w.symstrtab, name);
};

export fn _32newto(h: io::handle, w: writer) (void | io::error) = {
	const usr_sect_ix = len(w._32.sects): u16;
	let is_syms = len(w._32.syms) != 0,
		is_usr_shstrtab = false,
		is_usr_symstrtab = false;
	let ix_usr_shstrtab = 0u16;

	let shstrtab_ixs: []u32 = [];
	let shstrtab_len = 2u32;
	for (let i = 0u16; i < len(w.shstrtab); i += 1) {
		const s = w.shstrtab[i];
		const s_len = len(s): u32;
		switch (s_len) {
		case 9 =>
			if (s == ".shstrtab") {
				is_usr_shstrtab = true;
				ix_usr_shstrtab = i;
			};
		case 10 =>
			if (s == ".symstrtab")
				is_usr_symstrtab = true;
		case 7 =>
			if (s == ".strtab")
				is_usr_symstrtab = true;
		case =>
			void;
		};
		append(shstrtab_ixs, shstrtab_len);
		shstrtab_len += s_len + 1;
	};
	
	let symstrtab_len = 0u32;
	let symtab_len = 0u32;
	if (is_syms) {
		symstrtab_len = 2u32;
		symtab_len = ((1 + len(w._32.syms)) * size(elf32::sym)): u32;
		for (let i = 0u16; i < len(w.symstrtab); i += 1) {
			const s_len = len(w.symstrtab[i]): u32;
			symstrtab_len += s_len + 1;
		};
		static const symstrtab_name = ".symstrtab",
			symstrtab_name_len = len(".symstrtab"): u32,
			symtab_name = ".symtab",
			symtab_name_len = len(".symtab"): u32;

		const symstrtab_ix = len(w.shstrtab): u16;
		append(w.shstrtab, symstrtab_name);
		append(shstrtab_ixs, shstrtab_len);
		shstrtab_len += symstrtab_name_len + 1;

		const symtab_ix = len(w.shstrtab);
		append(w.shstrtab, symtab_name);
		append(shstrtab_ixs, shstrtab_len);
		shstrtab_len += symtab_name_len + 1;

		const symstrtab = elf32::section{
			sh_name = shstrtab_ixs[symstrtab_ix],
			sh_type = elf::sht::STRTAB,
			sh_flags = elf::shf::NONE,
			sh_offset = size(elf32::header): u32,
			sh_size = symstrtab_len,
			...
		};

		const symtab = elf32::section{
			sh_name = shstrtab_ixs[symtab_ix],
			sh_type = elf::sht::SYMTAB,
			sh_flags = elf::shf::NONE,
			sh_offset = symstrtab_len + size(elf32::header): u32,
			sh_size = symtab_len,
			sh_link = symstrtab_ix + 1,
			...
		};

		append(w._32.sects, symstrtab);
		append(w._32.sects, symtab);
	};

	if (!is_usr_shstrtab) {
		static const shstrtab_name = ".shstrtab",
			shstrtab_name_len = len(".shstrtab"): u32;
		const shstrtab_ix = len(w.shstrtab): u16;
		append(w.shstrtab, shstrtab_name);
		append(shstrtab_ixs, shstrtab_len);
		shstrtab_len += shstrtab_name_len + 1;

		const _offset = 
			size(elf32::header): u32
				+ symstrtab_len
				+ symtab_len;

		const shstrtab = elf32::section{
			sh_name = shstrtab_ixs[shstrtab_ix],
			sh_type = elf::sht::STRTAB,
			sh_flags = elf::shf::NONE,
			sh_offset = _offset,
			sh_size = shstrtab_len,
			...
		};
		append(w._32.sects, shstrtab);
	};

	const _sh_offset = ((1 + len(w.shstrtab)) * size(elf32::section)): u32;
	const _offset =
		size(elf32::header): u32
			+ symstrtab_len
			+ symtab_len
			+ shstrtab_len
			+ _sh_offset;
	for (let i = 0u16; i < usr_sect_ix; i += 1) {
		w._32.sects[i].sh_offset += _offset;
	};

	w._32.hdr.e_shnum = (1 + len(w.shstrtab)): u16;
	w._32.hdr.e_shoff = _offset - _sh_offset;
	w._32.hdr.e_shstrndx =
		if (is_usr_shstrtab) ix_usr_shstrtab + 1
		else len(w.shstrtab): u16;

	io::writeitem(h, &w._32.hdr, size(elf32::header))?;

	if (is_syms) io::writeitem(h, &0u16, 2)?;
	for (let i = 0u16; i < len(w.symstrtab); i += 1) {
		strio::concat(h, w.symstrtab[i])?;
		io::writeitem(h, &0u8, 1)?;
	};
	if (is_syms) io::writeitem(h, &elf32::sym{...}, size(elf32::sym))?;
	io::writeitems(h, w._32.syms, size(elf32::sym))?;

	io::writeitem(h, &0u16, 2)?;
	for (let i = 0u16; i < len(w.shstrtab); i += 1) {
		strio::concat(h, w.shstrtab[i])?;
		io::writeitem(h, &0u8, 1)?;
	};
	io::writeitem(h, &elf32::section{...}, size(elf32::section))?;
	io::writeitems(h, w._32.sects, size(elf32::section))?;
	for (let i = 0u16; i < len(w.codes); i += 1)
		io::write(h, w.codes[i])?;
};

export fn writeto(h: io::handle, w: writer) (void | io::error) = {
	switch (w.class) {
	case elf::ident_class::ELF32 =>
		let codelen = 0u32;
		for (let i = 0u16; i < len(w.codes); i += 1)
			codelen += len(w.codes[i]): u32;
		let symstrtab_sz = 2u32;
		for (let i = 0u16; i < len(w.symstrtab); i += 1)
			symstrtab_sz += 1 + len(w.symstrtab[i]): u32;
		let shstrtab_sz = 2u32;
		for (let i = 0u16; i < len(w.shstrtab); i += 1)
			shstrtab_sz += 1 + len(w.shstrtab[i]): u32;

		const sects = w._32.sects;
		const syms = w._32.syms;

		let _offset = size(elf32::header): u32
			+ ((len(sects) + 2) * size(elf32::section)): u32;

		// Setup ELF header for correct output.
		let hdr = w._32.hdr;
		hdr.e_shstrndx = (len(sects) + 1): u16;
		hdr.e_shnum = (len(sects) + 2): u16;
		if (len(syms) != 0) {
			hdr.e_shnum += 2;
			hdr.e_shstrndx += 2;
			_offset += ((len(syms) + 1) * size(elf32::sym)): u32;
		};
		// WRITE
		io::writeitem(h, &hdr, size(elf32::header))?;

		// Null entry;
		io::writeitem(h, &elf32::section{...}, size(elf32::section))?;
		for (let i = 0u16; i < len(sects); i += 1) {
			fmt::println("hello")!;
			// Setup ELF sections for correct offsets.
			let sect = sects[i];
			sect.sh_offset += _offset;
			// WRITE;
			io::writeitem(h, &sect, size(elf32::section))?;
		};

		let shstrtab = elf32::section{
			sh_name = (len(sects) + 2): u16,
			sh_type = elf::sht::STRTAB,
			sh_flags = elf::shf::NONE,
			sh_offset = _offset + codelen + symstrtab_sz,
			sh_size = shstrtab_sz + len(".shstrtab\0"): u32,
			...
		};

		if (len(syms) != 0) {
			// Setup ELF section to find the symbol table
			let symtab_sz = ((len(syms) + 1)
				* size(elf32::sym)): u32;

			let symtab = elf32::section{
				sh_name = (len(sects) + 1): u16,
				sh_type = elf::sht::SYMTAB,
				sh_flags = elf::shf::NONE,
				sh_offset = _offset - symtab_sz,
				sh_size = symtab_sz,
				sh_link = (len(sects) + 2): u16, // strtab;
				sh_info = 0,
				sh_entsize = size(elf32::sym): u32,
				sh_addralign = size(elf32::sym): u32,
				...
			};
			let symstrtab = elf32::section{
				sh_name = (len(sects) + 2): u16,
				sh_type = elf::sht::STRTAB,
				sh_offset = _offset + codelen,
				sh_size = symstrtab_sz,
				...
			};
			io::writeitem(h, &symtab, size(elf32::section))?;
			io::writeitem(h, &symstrtab, size(elf32::section))?;
			io::writeitem(h, &shstrtab, size(elf32::section))?;

			// Null entry;
			io::writeitem(h, &elf32::sym{...}, size(elf32::sym))?;
			// WRITE;
			io::writeitems(h, syms, size(elf32::sym))?;
		} else io::writeitem(h, &shstrtab, size(elf32::section))?;

	case elf::ident_class::ELF64 =>
		let codelen = 0u64;
		for (let i = 0u16; i < len(w.codes); i += 1)
			codelen += len(w.codes[i]): u64;
		let symstrtab_sz = 0u64;
		for (let i = 0u16; i < len(w.symstrtab); i += 1)
			symstrtab_sz += len(w.symstrtab[i]): u64;
		let shstrtab_sz = 0u64;
		for (let i = 0u16; i < len(w.shstrtab); i += 1)
			shstrtab_sz += len(w.shstrtab[i]): u64;

		const sects = w._64.sects;
		const syms = w._64.syms;

		const _offset = size(elf::header64): u64
			+ ((len(sects) + 1) * size(elf::section64)): u64
			+ ((len(syms) + 1) * size(elf::sym64)): u64;

		// Setup ELF header for correct output.
		let hdr = w._64.hdr;
		hdr.e_shstrndx = (len(sects) + 3): u16;
		hdr.e_shnum = (len(sects) + 3): u16;
		// WRITE
		io::writeitem(h, &hdr, size(elf::header64))?;

		io::writeitem(h, &elf::section64{...}, size(elf::section64))?;
		for (let i = 0u16; i < len(sects); i += 1) {
			let sect = sects[i];
			sect.sh_offset += _offset;
			io::writeitem(h, &sect, size(elf::section64))?;
		};

		let shstrtab = elf::section64{
			sh_name = (len(sects) + 1): u16,
			sh_type = elf::sht::STRTAB,
			sh_flags = elf::shf::NONE,
			sh_offset = _offset + codelen + symstrtab_sz,
			sh_size = shstrtab_sz + len(".shstrtab\0"): u64,
			...
		};

		if (len(syms) != 0) {
			// Setup ELF section to find the symbol table
			let symtab_sz = ((len(syms) + 1)
				* size(elf::sym64)): u32;

			let symtab = elf::section64{
				sh_name = (len(sects) + 1): u16,
				sh_type = elf::sht::SYMTAB,
				sh_flags = elf::shf::NONE,
				sh_offset = _offset - symtab_sz,
				sh_size = symtab_sz,
				sh_link = (len(sects) + 2): u16, // strtab;
				sh_info = 0,
				sh_entsize = size(elf::sym64): u32,
				sh_addralign = size(elf::sym64): u32,
				...
			};
			let symstrtab = elf::section64{
				sh_name = (len(sects) + 2): u16,
				sh_type = elf::sht::STRTAB,
				sh_offset = _offset + codelen,
				sh_size = symstrtab_sz,
				...
			};
			io::writeitem(h, &symtab, size(elf::section64))?;
			io::writeitem(h, &symstrtab, size(elf::section64))?;
			io::writeitem(h, &shstrtab, size(elf::section64))?;

			// Null entry;
			io::writeitem(h, &elf::sym64{...}, size(elf::sym64))?;
			// WRITE;
			io::writeitems(h, syms, size(elf::sym64))?;
			append(w.shstrtab, ".symtab");
			append(w.shstrtab, ".symstrtab");
		} else io::writeitem(h, &shstrtab, size(elf::section64))?;
	};

	for (let i = 0u16; i < len(w.codes); i += 1)
		io::write(h, w.codes[i])?;
	io::write(h, [0, 0])?; // Null entry;
	for (let i = 0u16; i < len(w.symstrtab); i += 1) {
		strio::concat(h, w.symstrtab[i])?;
		io::write(h, [0])?;
	};
	io::write(h, [0, 0])?; // Null entry;
	for (let i = 0u16; i < len(w.shstrtab); i += 1) {
		strio::concat(h, w.shstrtab[i])?;
		io::write(h, [0])?;
	};
	strio::concat(h, ".shstrtab\0")?;
};
