use endian;
use isa;

export type order = enum {
	LITTLE,
	BIG,
};

fn is_host(o: order) bool = {
	switch (o) {
	case order::LITTLE => if (endian::host == &endian::little) return true;
	case order::BIG => if (endian::host == &endian::big) return true;
	};
	return false;
};

export fn get_tgtorder(arch: isa::arch) order = {
	switch (arch) {
	case => return order::LITTLE;
	};
};

export fn oputu16(o: order, out: []u8, in: u16) void =
	if (is_host(o)) endian::beputu16(out, in)
	else endian::leputu16(out, in);

export fn oputu32(o: order, out: []u8, in: u32) void =
	if (is_host(o)) endian::beputu32(out, in)
	else endian::leputu32(out, in);

export fn oputu64(o: order, out: []u8, in: u64) void =
	if (is_host(o)) endian::beputu64(out, in)
	else endian::leputu64(out, in);
