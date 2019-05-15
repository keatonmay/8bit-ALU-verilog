//////////
// MUX
///////////

// Basic 2x1 mux

module mux_2to1(
	input [7:0]a,
	input [7:0]b,
	input selection,
	output reg [7:0] out
);
	reg x;
	
	always @* begin
		x = selection;
		
		case(x)
		1'b0: out = a;
		1'b1: out = b;	
		endcase
	end
endmodule

// 8x1 mux used for final output of the ALU

module mux_8to1(
	input [2:0] operation,
	input [7:0] sum,
	input [7:0] difference,
	input [7:0] sl,
	input [7:0] sr,
	input [7:0] and_8bit,
	input [7:0] or_8bit,
	input [7:0] xor_8bit,
	input [7:0] not_8bit,
	output reg [7:0] out
);
	
	reg [2:0] x;
	
	always @* begin
		x = operation;
		
		case(x[2:0])
			3'b000: out = sum;
			3'b001: out = difference;
			3'b010: out = sl;
			3'b011: out = sr;
			3'b100: out = and_8bit;
			3'b101: out = or_8bit;
			3'b110: out = xor_8bit;
			3'b111: out = not_8bit;
		endcase
	end

endmodule

// 8x1 mux for the carry bit. output is 0 in all but two cases (addition and subtraction opcode)

module mux_carry(
	input [2:0]operation,
	input add_carry,
	input sub_carry,
	output reg carry
);

	reg [2:0] x;
	
	always @* begin
		x = operation;
		
		case(x[2:0])
			3'b000: carry = add_carry;
			3'b001: carry = sub_carry;
			default: carry = 0;
		endcase
	end

endmodule

///////////
// Register
////////////


// D flip-flop

module dff(
	input clk,
	input d,
	output q
);

reg A;

always @(posedge clk)
	begin
		A <= d;
	end
	
	assign q = A;

endmodule

// register of d flip-flops - instantiates 8 d flip flops as a register

module register(
	input clk,
	input [7:0] d,
	output [7:0] q
);

	dff d0(clk, d[0], q[0]);
	dff d1(clk, d[1], q[1]);
	dff d2(clk, d[2], q[2]);
	dff d3(clk, d[3], q[3]);
	dff d4(clk, d[4], q[4]);
	dff d5(clk, d[5], q[5]);
	dff d6(clk, d[6], q[6]);
	dff d7(clk, d[7], q[7]);

endmodule

///////////
// Adder
//////////

module Add_half (
	input a, b,
	output c_out, sum
);

	xor G1 (sum, a, b);
	and G2 (c_out, a, b);

endmodule

module Add_full (
	input a, b, c_in,
	output c_out, sum
);

	wire w1, w2, w3;

	Add_half M1 (a, b, w1, w2);
	Add_half M2 (w2, c_in, w3, sum);
	or (c_out, w1, w3);

endmodule

module Adder_subtracter (
	input [7:0] a, b,
	input M, 
	output [7:0] sum,
	output c_out
);

	wire [7:0] x; 				// xor result for each full adder
	wire c_in1, c_in2, c_in3, c_in4, c_in5, c_in6, c_in7;
	integer i;
	

	//result of these xors is fed into the full adder along with a and carry (x[i] is the resultant)
	xor G0 (x[0], b[0], M);
	xor G1 (x[1], b[1], M);
	xor G2 (x[2], b[2], M);
	xor G3 (x[3], b[3], M);
	xor G4 (x[4], b[4], M);
	xor G5 (x[5], b[5], M);
	xor G6 (x[6], b[6], M);
	xor G7 (x[7], b[7], M);
	
	
	//get result of each full adder with carry bit
	Add_full m0 (.a(a[0]), .b(x[0]), .c_in(M), .sum(sum[0]), .c_out(c_in1));
	Add_full m1 (.a(a[1]), .b(x[1]), .c_in(c_in1), .sum(sum[1]), .c_out(c_in2));
	Add_full m2 (.a(a[2]), .b(x[2]), .c_in(c_in2), .sum(sum[2]), .c_out(c_in3));
	Add_full m3 (.a(a[3]), .b(x[3]), .c_in(c_in3), .sum(sum[3]), .c_out(c_in4));
	Add_full m4 (.a(a[4]), .b(x[4]), .c_in(c_in4), .sum(sum[4]), .c_out(c_in5));
	Add_full m5 (.a(a[5]), .b(x[5]), .c_in(c_in5), .sum(sum[5]), .c_out(c_in6));
	Add_full m6 (.a(a[6]), .b(x[6]), .c_in(c_in6), .sum(sum[6]), .c_out(c_in7));
	Add_full m7 (.a(a[7]), .b(x[7]), .c_in(c_in7), .sum(sum[7]), .c_out(c_out));
	
endmodule

/////////////////////
// Shifting functions
//////////////////////

////////// Shift Left

module shift_left(
	input [7:0] a,
	output [7:0] res
);

	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=7; i>0; i=i-1)
			R[i] = a[i-1];
		R[0] = 0;
	end
	
	assign res = R;

endmodule


/////////// Shift Right

module shift_right(
	input [7:0] a,
	output [7:0] res
);

	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=0; i<7; i=i+1)
			R[i] = a[i+1];
		R[7] = 0;
	end
	
	
	
	assign res = R;

endmodule

//////////
// Logical Funtions
//////////

//////// AND - ands 2 inputs of 8 bits

module AND_8bit(
	input [7:0] a,
	input [7:0] b,
	output [7:0] a_and_b
);
	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=0; i<8; i=i+1)
			R[i] = a[i] & b[i];
	end
	
	assign a_and_b = R;
	

endmodule

////////// OR- ors 2 inputs of 8 bits

module OR_8bit(
	input [7:0] a,
	input [7:0] b,
	output [7:0] a_or_b
);

	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=0; i<8; i=i+1)
			R[i] = a[i] | b[i];
	end
	
	assign a_or_b = R;

endmodule

////////// XOR - xors 2 inputs of 8 bits

module XOR_8bit(
	input [7:0] a,
	input [7:0] b,
	output [7:0] a_xor_b
);

	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=0; i<8; i=i+1)
			R[i] = a[i] ^ b[i];
	end
	
	assign a_xor_b = R;

endmodule

////////// NOT - nots 1 inputs of 8 bits

module NOT_8bit(
	input [7:0] a,
	output [7:0] a_not
);

	integer i;
	
	reg [7:0] R;
	
	always @* begin
		for (i=0; i<8; i=i+1)
			R[i] = ~a[i];
	end
	
	assign a_not = R;
	
endmodule

//////////////
// ALU
/////////////

module alu(
	input [7:0] a,
	input [7:0] b,
	input [4:0] operation,
	input clk,
	output [7:0] out,
	output [7:0] q,
	output carry_out
);
	wire carry_out_add; // the 2 carry outs are fed to a mux which displays the appropriate carry based on chosen opcode
	wire carry_out_sub;
	wire [7:0] a_res; // a_res and b_res are the values we feed to our various functions. this could either be the a or b input, or the value of the register could be fed in to the functions
	wire [7:0] b_res;
	wire [7:0] adder_sum; // adder_sum and adder_dif are the result of the 2 instantiated adders
	wire [7:0] adder_diff;
	wire [7:0] sl_res; // result of shift functions
	wire [7:0] sr_res;
	wire [7:0] and_res; // result of logical functions
	wire [7:0] or_res;
	wire [7:0] xor_res;
	wire [7:0] not_res;
	
	
	
	mux_2to1 a_value(a, q, operation[4], a_res); // these muxes determine if we want to use a,b inputs or substitute our register value for a or b or both
	mux_2to1 b_value(b, q, operation[3], b_res);
	
	Adder_subtracter add(a_res, b_res, 1'b0, adder_sum, carry_out_add); // 2 instantiations of adders whose output goes to the final 8x1 mux
	Adder_subtracter sub(a_res, b_res, 1'b1, adder_diff, carry_out_sub);
	shift_left sl(a_res, sl_res); // Shifts always applied to a value (register or a input) only
	shift_right sr(a_res, sr_res);
	AND_8bit resultant_and(a_res, b_res, and_res);
	OR_8bit resultant_or(a_res, b_res, or_res);
	XOR_8bit resultant_xor(a_res, b_res, xor_res);
	NOT_8bit resultant_not(a_res, not_res);
	
	mux_carry carry_value(operation[2:0], carry_out_add, carry_out_sub, carry_out); // carry out should only be displayed for addition and subtraction, the other functions do not have overflow
	
	// this mux takes the results of all of the functions and determines the output based on opcode. the result is then saved to the register.
	mux_8to1 final_out(operation[2:0], adder_sum, adder_diff, sl_res, sr_res, and_res, or_res, xor_res, not_res, out); 
	register r1(clk, out, q);
	
	
endmodule

////////////////////////////////
////////////////////////////////
// Test Bench
/////////////////////////////////
////////////////////////////////

module Test_Bench;
	
	reg [7:0] a, b;
	reg [4:0] op; // the 2 most significant bits of opcode determine whether the ALU will use inputs (a,b) or the current register value. 10000, for instance means to add the current register value to b, 11000 means to add register to register.
	reg [35*8:0] desc;
	reg clk;
	wire [7:0] alu_out;
	wire c_out;
	wire [7:0] q_out;
	integer f = 0;
	
	// instantiate ALU
	
	alu a_s(a, b, op, clk, alu_out, q_out, c_out);
	
initial begin
	clk = 0;
	forever #5 clk = ~clk;
end




// test cases
	
initial begin
	#1 op = 5'b00000; a = 15; b = 181;
	#10 op = 5'b00000; a = 42; b = 22;
	#10 op = 5'b10000; a = 38; b = 100;
	#10 op = 5'b11000; a = 10; b = 5;
	#10 op = 5'b00000; a = 10; b = 5;
	#10 op = 5'b10000; a = 10; b = 127;
	#10 op = 5'b01000; a = 42; b = 5;
	#10 op = 5'b00001; a = 200; b = 11;
	#10 op = 5'b10001; a = 24; b = 150;
	#10 op = 5'b00001; a = 166; b = 242;
	#10 op = 5'b11001; a = 28; b = 13;
	#10 op = 5'b00001; a = 255; b = 10;
	#10 op = 5'b10001; a = 10; b = 128;
	#10 op = 5'b01001; a = 249; b = 5;
	#10 op = 5'b00010; a = 37; b = 223;
	#10 op = 5'b00010; a = 82; b = 123;
	#10 op = 5'b01010; a = 201; b = 111;
	#10 op = 5'b00010; a = 145; b = 255;
	#10 op = 5'b00010; a = 177; b = 185;
	#10 op = 5'b10010; a = 26; b = 18;
	#10 op = 5'b01010; a = 93; b = 26;
	#10 op = 5'b00011; a = 42; b = 103;
	#10 op = 5'b00011; a = 252; b = 66;
	#10 op = 5'b10011; a = 49; b = 149;
	#10 op = 5'b00011; a = 100; b = 108;
	#10 op = 5'b00011; a = 79; b = 19;
	#10 op = 5'b10011; a = 36; b = 122;
	#10 op = 5'b01011; a = 87; b = 233;
	#10 op = 5'b00100; a = 181; b = 103;
	#10 op = 5'b00100; a = 42; b = 68;
	#10 op = 5'b11100; a = 81; b = 36;
	#10 op = 5'b00100; a = 92; b = 64;
	#10 op = 5'b00100; a = 254; b = 146;
	#10 op = 5'b10100; a = 216; b = 39;
	#10 op = 5'b01100; a = 176; b = 200;
	#10 op = 5'b10101; a = 204; b = 10;
	#10 op = 5'b01101; a = 80; b = 16;
	#10 op = 5'b00101; a = 209; b = 106;
	#10 op = 5'b00101; a = 155; b = 101;
	#10 op = 5'b00101; a = 244; b = 103;
	#10 op = 5'b10101; a = 237; b = 7;
	#10 op = 5'b01101; a = 15; b = 111;
	#10 op = 5'b00110; a = 147; b = 214;
	#10 op = 5'b00110; a = 141; b = 1;
	#10 op = 5'b10110; a = 255; b = 0;
	#10 op = 5'b00110; a = 113; b = 178;
	#10 op = 5'b00110; a = 1; b = 10;
	#10 op = 5'b10110; a = 26; b = 13;
	#10 op = 5'b01110; a = 187; b = 166;
	#10 op = 5'b00111; a = 133; b = 4;
	#10 op = 5'b01111; a = 141; b = 106;
	#10 op = 5'b00111; a = 222; b = 6;
	#10 op = 5'b00111; a = 18; b = 7;
	#10 op = 5'b00111; a = 0; b = 10;
	#10 op = 5'b10111; a = 113; b = 253;
	#10 op = 5'b01111; a = 255; b = 10;
	#10 op = 5'b00111; a = 255; b = 10;
	
end

// assigns description to output based on opcode
initial begin
	forever
		#2
		case(op)
			5'b00000: desc = "add a and b";
			5'b00001: desc = "subtract b from a";
			5'b00010: desc = "shift a left";
			5'b00011: desc = "shift a right";
			5'b00100: desc = "and a and b";
			5'b00101: desc = "or a and b";
			5'b00110: desc = "xor a and b";
			5'b00111: desc = "not a";
			5'b01000: desc = "add a and register";
			5'b01001: desc = "subtract register from a";
			5'b01010: desc = "shift a left";
			5'b01011: desc = "shift a right";
			5'b01100: desc = "and a and register";
			5'b01101: desc = "or a and register";
			5'b01110: desc = "xor a and register";
			5'b01111: desc = "not a";
			5'b10000: desc = "add register and b";
			5'b10001: desc = "subtract b from register";
			5'b10010: desc = "shift register left";
			5'b10011: desc = "shift register right";
			5'b10100: desc = "and register and b";
			5'b10101: desc = "or register and b";
			5'b10110: desc = "xor register and b";
			5'b10111: desc = "not register";
			5'b11000: desc = "add register and register";
			5'b11001: desc = "subtract register from register";
			5'b11010: desc = "shift register left";
			5'b11011: desc = "shift register right";
			5'b11100: desc = "and register and register";
			5'b11101: desc = "or register and register";
			5'b11110: desc = "xor register and register";
			5'b11111: desc = "not register";
		endcase
end


// output formatting

initial begin
	
	f = $fopen("output.txt","w");	
		$fwrite(f,"+--------------+--------------+--------------+-----+--------------+--------------+-----------------------------------+\n");
		$fwrite(f,"|A             |B             |Register      |OP   |Result        |Carry/Overflow|Description                        |\n");
		$fwrite(f,"|--------------+--------------+--------------+-----+--------------+--------------+-----------------------------------+\n");
	#4  $fwrite(f,"|%8b (%3d)|%8b (%3d)|%8b (%3d)|%5b|%8b (%3d)|%14b|%35s|\n", a, a, b, b, q_out, q_out, op, alu_out, alu_out, c_out, desc);
		
	
	forever
		
		#10
		$fwrite(f,"|%8b (%3d)|%8b (%3d)|%8b (%3d)|%5b|%8b (%3d)|%14b|%35s|\n", a, a, b, b, q_out, q_out, op, alu_out, alu_out, c_out, desc);
	
	
	$fclose(f);
end

initial #565 $finish;

endmodule