module  \$_DFF_N_ (input D, C, output Q); DFFNHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CKN(C)); endmodule
module  \$_DFF_P_ (input D, C, output Q); DFFHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C)); endmodule

// module  \$adff (input C, D, R, output Q); DFFRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .RN(R)); endmodule
// module  \$adffe (input C, D, E, R, output Q); DFFRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .RN(R)); endmodule
// module  \$sdffe (input C, D, E, R, output Q); EDFFTRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .E(E), .RN(R)); endmodule

module  \$_DFFE_PP_ (input D, C, E, output Q); EDFFHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .E(E)); endmodule
module  \$_DFFE_PN_ (input D, C, E, output Q); EDFFHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .E(!E)); endmodule

module  \$_DFF_PN0_ (input D, C, R, output Q); DFFRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .RN(R)); endmodule
module  \$_DFF_PN1_ (input D, C, R, output Q); DFFSHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .SN(R)); endmodule
module  \$_DFF_PP0_ (input D, C, R, output Q); DFFRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .RN(!R)); endmodule
module  \$_DFF_PP1_ (input D, C, R, output Q); DFFSHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .SN(!R)); endmodule

module  \$dff (output Q, input D, C);
  parameter WIDTH = 1;
  parameter CLK_POLARITY = 1;
  DFFHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C));
endmodule

module  \$mux (output Y, input A, input B, input S);
  parameter WIDTH = 1;
  parameter LUT = 0;
  LUT2 _TECHMAP_REPLACE_ (.ADR0(A), .ADR1(S), .O(Y));
endmodule

module  \$_DFF_NN0_ (input D, C, R, output Q); DFFNRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CKN(C), .RN(R)); endmodule
module  \$_DFF_NN1_ (input D, C, R, output Q); DFFNSHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CKN(C), .SN(R)); endmodule
module  \$_DFF_NP0_ (input D, C, R, output Q); DFFNRHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CKN(C), .RN(!R)); endmodule
module  \$_DFF_NP1_ (input D, C, R, output Q); DFFNSHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CKN(C), .SN(!R)); endmodule

module  \$_SDFFCE_PP0P_ (input C, D, E, R, output Q); EDFFHQ _TECHMAP_REPLACE_ (.D(D), .Q(Q), .CK(C), .E(E)); endmodule

module  \$_LUT_2 (output Y, input A0, A1); LUT2 _TECHMAP_REPLACE_ (.ADR0(A0), .ADR1(A1), .O(Y)); endmodule
module  \$_LUT_3 (output Y, input A0, A1, A2); LUT3 _TECHMAP_REPLACE_ (.ADR0(A0), .ADR1(A1), .ADR2(A2), .O(Y)); endmodule
module  \$_LUT_4 (output Y, input A0, A1, A2, A3); LUT4 _TECHMAP_REPLACE_ (.ADR0(A0), .ADR1(A1), .ADR2(A2), .ADR3(A3), .O(Y)); endmodule

`ifndef NO_LUT
module \$lut (A, Y);
  parameter WIDTH = 0;
  parameter LUT = 0;

  input [WIDTH-1:0] A;
  output Y;

  generate

    if (WIDTH == 1) begin
      LUT2 #(.LUT_INIT(LUT)) _TECHMAP_REPLACE_ (.O(Y),
        .ADR0(A[0]), .ADR1(A[0]));
    end else

    if (WIDTH == 2) begin
      LUT2 #(.LUT_INIT(LUT)) _TECHMAP_REPLACE_ (.O(Y),
        .ADR0(A[0]), .ADR1(A[1]));
    end else

    if (WIDTH == 3) begin
      LUT3 #(.LUT_INIT(LUT)) _TECHMAP_REPLACE_ (.O(Y),
        .ADR0(A[0]), .ADR1(A[1]), .ADR2(A[2]));
    end else

    if (WIDTH == 4) begin
      LUT4 #(.LUT_INIT(LUT)) _TECHMAP_REPLACE_ (.O(Y),
        .ADR0(A[0]), .ADR1(A[1]), .ADR2(A[2]), .ADR3(A[3]));
    end else 

    if (WIDTH == 5) begin
      LUT5 #(.LUT_INIT(LUT)) _TECHMAP_REPLACE_ (.O(Y),
        .ADR0(A[0]), .ADR1(A[1]), .ADR2(A[2]), .ADR3(A[3]), .ADR4(A[4]));
    end else 

    begin
      wire _TECHMAP_FAIL_ = 1;
    end
  endgenerate
endmodule
`endif
