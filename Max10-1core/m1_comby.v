module m1_comby (

input wire [31:0]	a,
input wire [31:0]	b,
input wire [31:0]	c,
input wire [31:0]	d,
input wire [31:0]	e,
input wire [31:0]	f,
input wire [31:0]	g,
input wire [31:0]	h,
input wire [31:0]	k,
input wire [31:0]	wt_in,
//
output wire [31:0] t1t2,
output wire [31:0] dt1
);
//
wire [31:0]	t1;
wire [31:0]	t2;
wire [31:0]	big_sigma0;
wire [31:0]	big_sigma1;
wire [31:0]	ch;
wire [31:0]	maj;



assign t1 = h + big_sigma1 + ch + k + wt_in;//
assign t2 = big_sigma0 + maj;
assign t1t2 = t1 + t2;
assign dt1 = d + t1;
//
assign big_sigma0 = {a[1:0],a[31:2]} ^ {a[12:0],a[31:13]} ^ {a[21:0],a[31:22]};
assign big_sigma1 = {e[5:0],e[31:6]} ^ {e[10:0],e[31:11]} ^ {e[24:0],e[31:25]};
//
assign ch = (e & f) ^ (~e & g);
assign maj = (a & b) ^ (a & c) ^ (b & c);


endmodule
