use strings;

export fn isreg(name: str) (u32 | void) =
	switch (len(name)) {
	case 2 =>
		switch (name) {
		case "x0" => return REG_X0;
		case "x1" => return REG_X1;
		case "x2" => return REG_X2;
		case "x3" => return REG_X3;
		case "x4" => return REG_X4;
		case "x5" => return REG_X5;
		case "x6" => return REG_X6;
		case "x7" => return REG_X7;
		case "x8" => return REG_X8;
		case "x9" => return REG_X9;
		case "ra" => return REG_RA;
		case "sp" => return REG_SP;
		case "gp" => return REG_GP;
		case "tp" => return REG_TP;
		case "t0" => return REG_T0;
		case "t1" => return REG_T1;
		case "t2" => return REG_T2;
		case "s0" => return REG_S0;
		case "fp" => return REG_FP;
		case "s1" => return REG_S1;
		case "a0" => return REG_A0;
		case "a1" => return REG_A1;
		case "a2" => return REG_A2;
		case "a3" => return REG_A3;
		case "a4" => return REG_A4;
		case "a5" => return REG_A5;
		case "a6" => return REG_A6;
		case "a7" => return REG_A7;
		case "s2" => return REG_S2;
		case "s3" => return REG_S3;
		case "s4" => return REG_S4;
		case "s5" => return REG_S5;
		case "s6" => return REG_S6;
		case "s7" => return REG_S7;
		case "s8" => return REG_S8;
		case "s9" => return REG_S9;
		case "t3" => return REG_T3;
		case "t4" => return REG_T4;
		case "t5" => return REG_T5;
		case "t6" => return REG_T6;
		case => return;
		};
	case 3 =>
		switch (name) {
		case "x10" => return REG_X10;
		case "x11" => return REG_X11;
		case "x12" => return REG_X12;
		case "x13" => return REG_X13;
		case "x14" => return REG_X14;
		case "x15" => return REG_X15;
		case "x16" => return REG_X16;
		case "x17" => return REG_X17;
		case "x18" => return REG_X18;
		case "x19" => return REG_X19;
		case "x20" => return REG_X20;
		case "x21" => return REG_X21;
		case "x22" => return REG_X22;
		case "x23" => return REG_X23;
		case "x24" => return REG_X24;
		case "x25" => return REG_X25;
		case "x26" => return REG_X26;
		case "x27" => return REG_X27;
		case "x28" => return REG_X28;
		case "x29" => return REG_X29;
		case "x30" => return REG_X30;
		case "x31" => return REG_X31;
		case "s10" => return REG_S10;
		case "s11" => return REG_S11;
		case => return;
		};
	case 4 =>
		switch (name) {
		case "zero" => return REG_ZERO;
		case => return;
		};
	case => return;
	};

export fn isinst(name: str) (u32 | void) =
	switch (len(name)) {
	case 3 =>
		switch (name) {
		case "wfi" => return INST_WFI;
		case => return;
		};
	case 4 =>
		switch (name) {
		case "addi" => return INST_ADDI;
		case "ecall" => return INST_ECALL;
		case => return;
		};
	case 5 =>
		switch (name) {
		case "ecall" => return INST_ECALL;
		case => return;
		};
	case => return;
	};
