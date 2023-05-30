use hash::fnv;
use fmt;
use isa;

export def BUCKETS: u8 = 64;

export type ident = enum size {
	SECTION,
	REFERENCE,
	FUNCTION,
};

export type entry = struct {
	ident: ident,
	name: str,
	loc: isa::addr, // location inside of the binary file.
	sz: isa::addr,
};

export type item = struct {
	hash: u32,
	ent: entry,
};

export type hashmap = [BUCKETS][]item;

// Appends the given entry to the provided hashmap. Returns the entry's hash.
export fn add(hm: *hashmap, name: str, ent: entry) u32 = {
	const h = fnv::string32(name);
	const it = item{
		hash = h,
		ent = ent,
	};
	append(hm[h % BUCKETS], it);

	return h;
};

export fn get(hm: hashmap, name: str) (*item | void) = {
	const h = fnv::string32(name);
	return find(hm, h);
};

export fn find(hm: hashmap, hash: u32) (*item | void) = {
	const b = hash % BUCKETS;
	for (let i = 0z; i < len(hm[b]); i += 1) {
		if (hm[b][i].hash == hash) return &hm[b][i];
	};
};

export fn finish(hm: *hashmap) void = {
	for (let i = 0z; i < BUCKETS; i += 1) free(hm[i]);
};
