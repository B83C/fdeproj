// Behavioral simulation models for UFDE+ BRAM primitives
// Based on IP Generator templates

// Single Port RAMB4_S1 - 512 x 1
module RAMB4_S1 (
    input CLK,
    input [8:0] ADDR,
    input DI,
    output DO,
    input WE,
    input EN,
    input RST
);
    reg [0:511] mem;
    reg do_reg;
    
    always @(posedge CLK) begin
        if (WE && EN) begin
            mem[ADDR] <= DI;
        end
        if (EN) begin
            do_reg <= mem[ADDR];
        end
    end
    
    assign DO = do_reg;
endmodule

// Single Port RAMB4_S2 - 256 x 2
module RAMB4_S2 (
    input CLK,
    input [7:0] ADDR,
    input [1:0] DI,
    output [1:0] DO,
    input WE,
    input EN,
    input RST
);
    reg [1:0] mem [0:255];
    reg [1:0] do_reg;
    
    always @(posedge CLK) begin
        if (WE && EN) begin
            mem[ADDR] <= DI;
        end
        if (EN) begin
            do_reg <= mem[ADDR];
        end
    end
    
    assign DO = do_reg;
endmodule

// Single Port RAMB4_S4 - 128 x 4
module RAMB4_S4 #(
    parameter [255:0] INIT_00 = 256'h0,
    parameter [255:0] INIT_01 = 256'h0
)(
    input CLK,
    input [6:0] ADDR,
    input [3:0] DI,
    output [3:0] DO,
    input WE,
    input EN,
    input RST
);
    reg [3:0] mem [0:127];
    reg [3:0] do_reg;
    
    initial begin
        mem[0] = INIT_00[3:0];
        mem[1] = INIT_00[7:4];
        mem[2] = INIT_00[11:8];
        mem[3] = INIT_00[15:12];
        mem[4] = INIT_00[19:16];
        mem[5] = INIT_00[23:20];
        mem[6] = INIT_00[27:24];
        mem[7] = INIT_00[31:28];
        mem[8] = INIT_00[35:32];
        mem[9] = INIT_00[39:36];
        mem[10] = INIT_00[43:40];
        mem[11] = INIT_00[47:44];
        mem[12] = INIT_00[51:48];
        mem[13] = INIT_00[55:52];
        mem[14] = INIT_00[59:56];
        mem[15] = INIT_00[63:60];
        mem[16] = INIT_00[67:64];
        mem[17] = INIT_00[71:68];
        mem[18] = INIT_00[75:72];
        mem[19] = INIT_00[79:76];
        mem[20] = INIT_00[83:80];
        mem[21] = INIT_00[87:84];
        mem[22] = INIT_00[91:88];
        mem[23] = INIT_00[95:92];
        mem[24] = INIT_00[99:96];
        mem[25] = INIT_00[103:100];
        mem[26] = INIT_00[107:104];
        mem[27] = INIT_00[111:108];
        mem[28] = INIT_00[115:112];
        mem[29] = INIT_00[119:116];
        mem[30] = INIT_00[123:120];
        mem[31] = INIT_00[127:124];
        mem[32] = INIT_00[131:128];
        mem[33] = INIT_00[135:132];
        mem[34] = INIT_00[139:136];
        mem[35] = INIT_00[143:140];
        mem[36] = INIT_00[147:144];
        mem[37] = INIT_00[151:148];
        mem[38] = INIT_00[155:152];
        mem[39] = INIT_00[159:156];
        mem[40] = INIT_00[163:160];
        mem[41] = INIT_00[167:164];
        mem[42] = INIT_00[171:168];
        mem[43] = INIT_00[175:172];
        mem[44] = INIT_00[179:176];
        mem[45] = INIT_00[183:180];
        mem[46] = INIT_00[187:184];
        mem[47] = INIT_00[191:188];
        mem[48] = INIT_00[195:192];
        mem[49] = INIT_00[199:196];
        mem[50] = INIT_00[203:200];
        mem[51] = INIT_00[207:204];
        mem[52] = INIT_00[211:208];
        mem[53] = INIT_00[215:212];
        mem[54] = INIT_00[219:216];
        mem[55] = INIT_00[223:220];
        mem[56] = INIT_00[227:224];
        mem[57] = INIT_00[231:228];
        mem[58] = INIT_00[235:232];
        mem[59] = INIT_00[239:236];
        mem[60] = INIT_00[243:240];
        mem[61] = INIT_00[247:244];
        mem[62] = INIT_00[251:248];
        mem[63] = INIT_00[255:252];
        mem[64] = INIT_01[3:0];
        mem[65] = INIT_01[7:4];
        mem[66] = INIT_01[11:8];
        mem[67] = INIT_01[15:12];
        mem[68] = INIT_01[19:16];
        mem[69] = INIT_01[23:20];
        mem[70] = INIT_01[27:24];
        mem[71] = INIT_01[31:28];
        mem[72] = INIT_01[35:32];
        mem[73] = INIT_01[39:36];
        mem[74] = INIT_01[43:40];
        mem[75] = INIT_01[47:44];
        mem[76] = INIT_01[51:48];
        mem[77] = INIT_01[55:52];
        mem[78] = INIT_01[59:56];
        mem[79] = INIT_01[63:60];
        mem[80] = INIT_01[67:64];
        mem[81] = INIT_01[71:68];
        mem[82] = INIT_01[75:72];
        mem[83] = INIT_01[79:76];
        mem[84] = INIT_01[83:80];
        mem[85] = INIT_01[87:84];
        mem[86] = INIT_01[91:88];
        mem[87] = INIT_01[95:92];
        mem[88] = INIT_01[99:96];
        mem[89] = INIT_01[103:100];
        mem[90] = INIT_01[107:104];
        mem[91] = INIT_01[111:108];
        mem[92] = INIT_01[115:112];
        mem[93] = INIT_01[119:116];
        mem[94] = INIT_01[123:120];
        mem[95] = INIT_01[127:124];
        mem[96] = INIT_01[131:128];
        mem[97] = INIT_01[135:132];
        mem[98] = INIT_01[139:136];
        mem[99] = INIT_01[143:140];
        mem[100] = INIT_01[147:144];
        mem[101] = INIT_01[151:148];
        mem[102] = INIT_01[155:152];
        mem[103] = INIT_01[159:156];
        mem[104] = INIT_01[163:160];
        mem[105] = INIT_01[167:164];
        mem[106] = INIT_01[171:168];
        mem[107] = INIT_01[175:172];
        mem[108] = INIT_01[179:176];
        mem[109] = INIT_01[183:180];
        mem[110] = INIT_01[187:184];
        mem[111] = INIT_01[191:188];
        mem[112] = INIT_01[195:192];
        mem[113] = INIT_01[199:196];
        mem[114] = INIT_01[203:200];
        mem[115] = INIT_01[207:204];
        mem[116] = INIT_01[211:208];
        mem[117] = INIT_01[215:212];
        mem[118] = INIT_01[219:216];
        mem[119] = INIT_01[223:220];
        mem[120] = INIT_01[227:224];
        mem[121] = INIT_01[231:228];
        mem[122] = INIT_01[235:232];
        mem[123] = INIT_01[239:236];
        mem[124] = INIT_01[243:240];
        mem[125] = INIT_01[247:244];
        mem[126] = INIT_01[251:248];
        mem[127] = INIT_01[255:252];
    end
    
    always @(posedge CLK) begin
        if (WE && EN) begin
            mem[ADDR] <= DI;
        end
        if (EN) begin
            do_reg <= mem[ADDR];
        end
    end
    
    assign DO = do_reg;
endmodule

// Single Port RAMB4_S8 - 64 x 8
module RAMB4_S8 (
    input CLK,
    input [5:0] ADDR,
    input [7:0] DI,
    output [7:0] DO,
    input WE,
    input EN,
    input RST
);
    reg [7:0] mem [0:63];
    reg [7:0] do_reg;
    
    always @(posedge CLK) begin
        if (WE && EN) begin
            mem[ADDR] <= DI;
        end
        if (EN) begin
            do_reg <= mem[ADDR];
        end
    end
    
    assign DO = do_reg;
endmodule

// Single Port RAMB4_S16 - 32 x 16
module RAMB4_S16 (
    input CLK,
    input [4:0] ADDR,
    input [15:0] DI,
    output [15:0] DO,
    input WE,
    input EN,
    input RST
);
    reg [15:0] mem [0:31];
    reg [15:0] do_reg;
    
    always @(posedge CLK) begin
        if (WE && EN) begin
            mem[ADDR] <= DI;
        end
        if (EN) begin
            do_reg <= mem[ADDR];
        end
    end
    
    assign DO = do_reg;
endmodule

// Dual Port RAMB4_S1_S1 - 512 x 1 (both ports 1-bit)
module RAMB4_S1_S1 (
    input CLKA, CLKB,
    input [8:0] ADDRA, ADDRB,
    input DIA, DIB,
    output DOA, DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [0:511] mem;
    reg doa_reg, dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S1_S2 - Port A: 512x1, Port B: 256x2
module RAMB4_S1_S2 (
    input CLKA, CLKB,
    input [8:0] ADDRA,
    input [7:0] ADDRB,
    input DIA,
    input [1:0] DIB,
    output DOA,
    output [1:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [0:511] mem_a;
    reg [1:0] mem_b [0:255];
    reg doa_reg;
    reg [1:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S1_S4 - Port A: 512x1, Port B: 128x4
module RAMB4_S1_S4 (
    input CLKA, CLKB,
    input [8:0] ADDRA,
    input [6:0] ADDRB,
    input DIA,
    input [3:0] DIB,
    output DOA,
    output [3:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [0:511] mem_a;
    reg [3:0] mem_b [0:127];
    reg doa_reg;
    reg [3:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S1_S8 - Port A: 512x1, Port B: 64x8
module RAMB4_S1_S8 (
    input CLKA, CLKB,
    input [8:0] ADDRA,
    input [5:0] ADDRB,
    input DIA,
    input [7:0] DIB,
    output DOA,
    output [7:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [0:511] mem_a;
    reg [7:0] mem_b [0:63];
    reg doa_reg;
    reg [7:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S1_S16 - Port A: 512x1, Port B: 32x16
module RAMB4_S1_S16 (
    input CLKA, CLKB,
    input [8:0] ADDRA,
    input [4:0] ADDRB,
    input DIA,
    input [15:0] DIB,
    output DOA,
    output [15:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [0:511] mem_a;
    reg [15:0] mem_b [0:31];
    reg doa_reg;
    reg [15:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S2_S2 - 256 x 2 (both ports 2-bit)
module RAMB4_S2_S2 (
    input CLKA, CLKB,
    input [7:0] ADDRA, ADDRB,
    input [1:0] DIA, DIB,
    output [1:0] DOA, DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [1:0] mem [0:255];
    reg [1:0] doa_reg, dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S2_S4 - Port A: 256x2, Port B: 128x4
module RAMB4_S2_S4 (
    input CLKA, CLKB,
    input [7:0] ADDRA,
    input [6:0] ADDRB,
    input [1:0] DIA,
    input [3:0] DIB,
    output [1:0] DOA,
    output [3:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [1:0] mem_a [0:255];
    reg [3:0] mem_b [0:127];
    reg [1:0] doa_reg;
    reg [3:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S2_S8 - Port A: 256x2, Port B: 64x8
module RAMB4_S2_S8 (
    input CLKA, CLKB,
    input [7:0] ADDRA,
    input [5:0] ADDRB,
    input [1:0] DIA,
    input [7:0] DIB,
    output [1:0] DOA,
    output [7:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [1:0] mem_a [0:255];
    reg [7:0] mem_b [0:63];
    reg [1:0] doa_reg;
    reg [7:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S2_S16 - Port A: 256x2, Port B: 32x16
module RAMB4_S2_S16 (
    input CLKA, CLKB,
    input [7:0] ADDRA,
    input [4:0] ADDRB,
    input [1:0] DIA,
    input [15:0] DIB,
    output [1:0] DOA,
    output [15:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [1:0] mem_a [0:255];
    reg [15:0] mem_b [0:31];
    reg [1:0] doa_reg;
    reg [15:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S4_S4 - 128 x 4 (both ports 4-bit)
module RAMB4_S4_S4 (
    input CLKA, CLKB,
    input [6:0] ADDRA, ADDRB,
    input [3:0] DIA, DIB,
    output [3:0] DOA, DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [3:0] mem [0:127];
    reg [3:0] doa_reg, dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S4_S8 - Port A: 128x4, Port B: 64x8
module RAMB4_S4_S8 (
    input CLKA, CLKB,
    input [6:0] ADDRA,
    input [5:0] ADDRB,
    input [3:0] DIA,
    input [7:0] DIB,
    output [3:0] DOA,
    output [7:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [3:0] mem_a [0:127];
    reg [7:0] mem_b [0:63];
    reg [3:0] doa_reg;
    reg [7:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S4_S16 - Port A: 128x4, Port B: 32x16
module RAMB4_S4_S16 (
    input CLKA, CLKB,
    input [6:0] ADDRA,
    input [4:0] ADDRB,
    input [3:0] DIA,
    input [15:0] DIB,
    output [3:0] DOA,
    output [15:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [3:0] mem_a [0:127];
    reg [15:0] mem_b [0:31];
    reg [3:0] doa_reg;
    reg [15:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S8_S8 - 64 x 8 (both ports 8-bit)
module RAMB4_S8_S8 (
    input CLKA, CLKB,
    input [5:0] ADDRA, ADDRB,
    input [7:0] DIA, DIB,
    output [7:0] DOA, DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [7:0] mem [0:63];
    reg [7:0] doa_reg, dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S8_S16 - Port A: 64x8, Port B: 32x16
module RAMB4_S8_S16 (
    input CLKA, CLKB,
    input [5:0] ADDRA,
    input [4:0] ADDRB,
    input [7:0] DIA,
    input [15:0] DIB,
    output [7:0] DOA,
    output [15:0] DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [7:0] mem_a [0:63];
    reg [15:0] mem_b [0:31];
    reg [7:0] doa_reg;
    reg [15:0] dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem_a[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem_a[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem_b[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem_b[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule

// Dual Port RAMB4_S16_S16 - 32 x 16 (both ports 16-bit)
module RAMB4_S16_S16 (
    input CLKA, CLKB,
    input [4:0] ADDRA, ADDRB,
    input [15:0] DIA, DIB,
    output [15:0] DOA, DOB,
    input WEA, WEB,
    input ENA, ENB,
    input RSTA, RSTB
);
    reg [15:0] mem [0:31];
    reg [15:0] doa_reg, dob_reg;
    
    always @(posedge CLKA) begin
        if (WEA && ENA) begin
            mem[ADDRA] <= DIA;
        end
        if (ENA) begin
            doa_reg <= mem[ADDRA];
        end
    end
    
    always @(posedge CLKB) begin
        if (WEB && ENB) begin
            mem[ADDRB] <= DIB;
        end
        if (ENB) begin
            dob_reg <= mem[ADDRB];
        end
    end
    
    assign DOA = doa_reg;
    assign DOB = dob_reg;
endmodule
