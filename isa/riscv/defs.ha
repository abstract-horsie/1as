// Instruction types
export def INST_TYPE_LOAD: u32       = 0b0000011;
export def INST_TYPE_STORE: u32      = 0b0100011;
export def INST_TYPE_MADD: u32       = 0b1000011;
export def INST_TYPE_BRANCH: u32     = 0b1100011;
export def INST_TYPE_LOAD_FP: u32    = 0b0000111;
export def INST_TYPE_STORE_FP: u32   = 0b0100111;
export def INST_TYPE_MSUB: u32       = 0b1000111;
export def INST_TYPE_JALR: u32       = 0b1100111;
export def INST_TYPE_CUSTOM_0: u32   = 0b0001011;
export def INST_TYPE_CUSTOM_1: u32   = 0b0101011;
export def INST_TYPE_NMSUB: u32      = 0b1001011;
export def INST_TYPE_RESERVED_0: u32 = 0b1101011;
export def INST_TYPE_MISC_MEM: u32   = 0b0001111;
export def INST_TYPE_AMO: u32        = 0b0101111;
export def INST_TYPE_NMADD: u32      = 0b1001111;
export def INST_TYPE_JAL: u32        = 0b1101111;
export def INST_TYPE_OP_IMM: u32     = 0b0010011;
export def INST_TYPE_OP: u32         = 0b0110011;
export def INST_TYPE_OP_FP: u32      = 0b1010011;
export def INST_TYPE_SYSTEM: u32     = 0b1110011;
export def INST_TYPE_AUIPC: u32      = 0b0010111;
export def INST_TYPE_LUI: u32        = 0b0110111;
export def INST_TYPE_RESERVED_1: u32 = 0b1010111;
export def INST_TYPE_RESERVED_2: u32 = 0b1110111;
export def INST_TYPE_OP_IMM_32: u32  = 0b0011011;
export def INST_TYPE_OP_32: u32      = 0b0111011;
export def INST_TYPE_CUSTOM_2: u32   = 0b1011011;
export def INST_TYPE_CUSTOM_3: u32   = 0b1111011;

// Instructions
export def INST_ADDI:  u32 = (0b000 << 12) | INST_TYPE_OP_IMM;

export def INST_ECALL: u32  = (0b0000000000000000000000000 << 7) |
	INST_TYPE_SYSTEM;
export def INST_WFI: u32    = (0b0001000001010000000000000 << 7) |
	INST_TYPE_SYSTEM;

// Registers
export def REG_X0: u32  = 0x00;
export def REG_X1: u32  = 0x01;
export def REG_X2: u32  = 0x02;
export def REG_X3: u32  = 0x03;
export def REG_X4: u32  = 0x04;
export def REG_X5: u32  = 0x05;
export def REG_X6: u32  = 0x06;
export def REG_X7: u32  = 0x07;
export def REG_X8: u32  = 0x08;
export def REG_X9: u32  = 0x09;
export def REG_X10: u32 = 0x0A;
export def REG_X11: u32 = 0x0B;
export def REG_X12: u32 = 0x0C;
export def REG_X13: u32 = 0x0D;
export def REG_X14: u32 = 0x0E;
export def REG_X15: u32 = 0x0F;
export def REG_X16: u32 = 0x10;
export def REG_X17: u32 = 0x11;
export def REG_X18: u32 = 0x12;
export def REG_X19: u32 = 0x13;
export def REG_X20: u32 = 0x14;
export def REG_X21: u32 = 0x15;
export def REG_X22: u32 = 0x16;
export def REG_X23: u32 = 0x17;
export def REG_X24: u32 = 0x18;
export def REG_X25: u32 = 0x19;
export def REG_X26: u32 = 0x1A;
export def REG_X27: u32 = 0x1B;
export def REG_X28: u32 = 0x1C;
export def REG_X29: u32 = 0x1D;
export def REG_X30: u32 = 0x1E;
export def REG_X31: u32 = 0x1F;

// Named Registers
export def REG_ZERO: u32 = REG_X0; // Hard-wired zero;
export def REG_RA: u32   = REG_X1; // (R)eturn (A)ddress;
export def REG_SP: u32   = REG_X2; // (S)tack (P)ointer;
export def REG_GP: u32   = REG_X3; // (G)lobal (P)ointer;
export def REG_TP: u32   = REG_X4; // (T)hread (P)ointer;
export def REG_T0: u32   = REG_X5; // Temporary / Alt link reg;
export def REG_T1: u32   = REG_X6; // Temporary;
export def REG_T2: u32   = REG_X7; // Temporary;
export def REG_S0: u32   = REG_X8; // Saved register;
export def REG_FP: u32   = REG_X8; // (F)rame (P)ointer (same register as above);
export def REG_S1: u32   = REG_X9; // Saved register;

// Function arguments;
export def REG_A0: u32 = REG_X10; // Arg / Return value;
export def REG_A1: u32 = REG_X11; // Arg / Return value;
export def REG_A2: u32 = REG_X12;
export def REG_A3: u32 = REG_X13;
export def REG_A4: u32 = REG_X14;
export def REG_A5: u32 = REG_X15;
export def REG_A6: u32 = REG_X16;
export def REG_A7: u32 = REG_X17;

// Saved registers;
export def REG_S2: u32  = REG_X18;
export def REG_S3: u32  = REG_X19;
export def REG_S4: u32  = REG_X20;
export def REG_S5: u32  = REG_X21;
export def REG_S6: u32  = REG_X22;
export def REG_S7: u32  = REG_X23;
export def REG_S8: u32  = REG_X24;
export def REG_S9: u32  = REG_X25;
export def REG_S10: u32 = REG_X26;
export def REG_S11: u32 = REG_X27;

// Temporaries;
export def REG_T3: u32 = REG_X28;
export def REG_T4: u32 = REG_X29;
export def REG_T5: u32 = REG_X30;
export def REG_T6: u32 = REG_X31;
