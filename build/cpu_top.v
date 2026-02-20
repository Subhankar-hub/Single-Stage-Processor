module alu (
	a,
	b,
	op,
	result
);
	reg _sv2v_0;
	input wire [31:0] a;
	input wire [31:0] b;
	input wire [2:0] op;
	output reg [31:0] result;
	always @(*) begin
		if (_sv2v_0)
			;
		case (op)
			3'd1: result = a + b;
			3'd2: result = a - b;
			default: result = 32'h00000000;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module regfile (
	clk,
	rst_n,
	rs1_addr,
	rs2_addr,
	rs1_data,
	rs2_data,
	we,
	rd_addr,
	rd_data,
	tb_rd_addr,
	tb_rd_data
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	localparam signed [31:0] isa_defs_pkg_REG_ADDR_W = 3;
	input wire [2:0] rs1_addr;
	input wire [2:0] rs2_addr;
	output reg [31:0] rs1_data;
	output reg [31:0] rs2_data;
	input wire we;
	input wire [2:0] rd_addr;
	input wire [31:0] rd_data;
	input wire [2:0] tb_rd_addr;
	output reg [31:0] tb_rd_data;
	localparam signed [31:0] isa_defs_pkg_REG_COUNT = 8;
	reg [31:0] regs [0:7];
	integer i;
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			for (i = 0; i < isa_defs_pkg_REG_COUNT; i = i + 1)
				regs[i] <= 32'h00000000;
		else begin
			if (we && (rd_addr != {3 {1'sb0}}))
				regs[rd_addr] <= rd_data;
			regs[0] <= 32'h00000000;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		rs1_data = regs[rs1_addr];
		rs2_data = regs[rs2_addr];
		tb_rd_data = regs[tb_rd_addr];
	end
	initial _sv2v_0 = 0;
endmodule
module control_unit (
	instr,
	is_rtype,
	is_itype,
	is_nop,
	alu_op,
	reg_write_en,
	mem_read,
	mem_write,
	rd_addr,
	rs1_addr,
	rs2_addr,
	imm16
);
	reg _sv2v_0;
	input wire [31:0] instr;
	output reg is_rtype;
	output reg is_itype;
	output reg is_nop;
	output reg [2:0] alu_op;
	output reg reg_write_en;
	output reg mem_read;
	output reg mem_write;
	localparam signed [31:0] isa_defs_pkg_REG_ADDR_W = 3;
	output wire [2:0] rd_addr;
	output wire [2:0] rs1_addr;
	output wire [2:0] rs2_addr;
	localparam signed [31:0] isa_defs_pkg_IMM_W = 16;
	output wire signed [15:0] imm16;
	localparam signed [31:0] isa_defs_pkg_OPCODE_W = 6;
	wire [5:0] opcode;
	localparam signed [31:0] isa_defs_pkg_INS_OPCODE_LSB = 26;
	localparam signed [31:0] isa_defs_pkg_INS_OPCODE_MSB = 31;
	function automatic [5:0] isa_defs_pkg_get_opcode;
		input reg [31:0] instr;
		isa_defs_pkg_get_opcode = instr[isa_defs_pkg_INS_OPCODE_MSB:isa_defs_pkg_INS_OPCODE_LSB];
	endfunction
	assign opcode = isa_defs_pkg_get_opcode(instr);
	localparam [5:0] isa_defs_pkg_OPC_ADD = 6'b000001;
	localparam [5:0] isa_defs_pkg_OPC_SUB = 6'b000010;
	localparam signed [31:0] isa_defs_pkg_INS_I_RD_RS2_LSB = 23;
	localparam signed [31:0] isa_defs_pkg_INS_I_RD_RS2_MSB = 25;
	function automatic [2:0] isa_defs_pkg_get_itype_rd_or_rs2;
		input reg [31:0] instr;
		isa_defs_pkg_get_itype_rd_or_rs2 = instr[isa_defs_pkg_INS_I_RD_RS2_MSB:isa_defs_pkg_INS_I_RD_RS2_LSB];
	endfunction
	localparam signed [31:0] isa_defs_pkg_INS_R_RD_LSB = 23;
	localparam signed [31:0] isa_defs_pkg_INS_R_RD_MSB = 25;
	function automatic [2:0] isa_defs_pkg_get_rtype_rd;
		input reg [31:0] instr;
		isa_defs_pkg_get_rtype_rd = instr[isa_defs_pkg_INS_R_RD_MSB:isa_defs_pkg_INS_R_RD_LSB];
	endfunction
	assign rd_addr = ((opcode == 6'b000001) || (opcode == 6'b000010) ? isa_defs_pkg_get_rtype_rd(instr) : isa_defs_pkg_get_itype_rd_or_rs2(instr));
	localparam signed [31:0] isa_defs_pkg_INS_I_RS1_LSB = 20;
	localparam signed [31:0] isa_defs_pkg_INS_I_RS1_MSB = 22;
	function automatic [2:0] isa_defs_pkg_get_itype_rs1;
		input reg [31:0] instr;
		isa_defs_pkg_get_itype_rs1 = instr[isa_defs_pkg_INS_I_RS1_MSB:isa_defs_pkg_INS_I_RS1_LSB];
	endfunction
	localparam signed [31:0] isa_defs_pkg_INS_R_RS1_LSB = 20;
	localparam signed [31:0] isa_defs_pkg_INS_R_RS1_MSB = 22;
	function automatic [2:0] isa_defs_pkg_get_rtype_rs1;
		input reg [31:0] instr;
		isa_defs_pkg_get_rtype_rs1 = instr[isa_defs_pkg_INS_R_RS1_MSB:isa_defs_pkg_INS_R_RS1_LSB];
	endfunction
	assign rs1_addr = ((opcode == 6'b000001) || (opcode == 6'b000010) ? isa_defs_pkg_get_rtype_rs1(instr) : isa_defs_pkg_get_itype_rs1(instr));
	localparam signed [31:0] isa_defs_pkg_INS_R_RS2_LSB = 17;
	localparam signed [31:0] isa_defs_pkg_INS_R_RS2_MSB = 19;
	function automatic [2:0] isa_defs_pkg_get_rtype_rs2;
		input reg [31:0] instr;
		isa_defs_pkg_get_rtype_rs2 = instr[isa_defs_pkg_INS_R_RS2_MSB:isa_defs_pkg_INS_R_RS2_LSB];
	endfunction
	assign rs2_addr = ((opcode == 6'b000001) || (opcode == 6'b000010) ? isa_defs_pkg_get_rtype_rs2(instr) : isa_defs_pkg_get_itype_rd_or_rs2(instr));
	localparam signed [31:0] isa_defs_pkg_INS_I_IMM_LSB = 4;
	localparam signed [31:0] isa_defs_pkg_INS_I_IMM_MSB = 19;
	function automatic signed [15:0] isa_defs_pkg_get_itype_imm16;
		input reg [31:0] instr;
		isa_defs_pkg_get_itype_imm16 = instr[isa_defs_pkg_INS_I_IMM_MSB:isa_defs_pkg_INS_I_IMM_LSB];
	endfunction
	assign imm16 = isa_defs_pkg_get_itype_imm16(instr);
	localparam [5:0] isa_defs_pkg_OPC_ADDI = 6'b000011;
	localparam [5:0] isa_defs_pkg_OPC_LOAD = 6'b000100;
	localparam [5:0] isa_defs_pkg_OPC_NOP = 6'b000000;
	localparam [5:0] isa_defs_pkg_OPC_STORE = 6'b000101;
	always @(*) begin
		if (_sv2v_0)
			;
		is_rtype = 1'b0;
		is_itype = 1'b0;
		is_nop = 1'b0;
		alu_op = 3'd0;
		reg_write_en = 1'b0;
		mem_read = 1'b0;
		mem_write = 1'b0;
		(* full_case, parallel_case *)
		case (opcode)
			isa_defs_pkg_OPC_NOP: is_nop = 1'b1;
			isa_defs_pkg_OPC_ADD: begin
				is_rtype = 1'b1;
				alu_op = 3'd1;
				reg_write_en = 1'b1;
			end
			isa_defs_pkg_OPC_SUB: begin
				is_rtype = 1'b1;
				alu_op = 3'd2;
				reg_write_en = 1'b1;
			end
			isa_defs_pkg_OPC_ADDI: begin
				is_itype = 1'b1;
				alu_op = 3'd1;
				reg_write_en = 1'b1;
			end
			isa_defs_pkg_OPC_LOAD: begin
				is_itype = 1'b1;
				mem_read = 1'b1;
				reg_write_en = 1'b1;
			end
			isa_defs_pkg_OPC_STORE: begin
				is_itype = 1'b1;
				mem_write = 1'b1;
			end
			default: is_nop = 1'b1;
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
module instruction_memory (
	clk,
	rst_n,
	addr_word,
	instr_out,
	tb_we,
	tb_addr,
	tb_wdata
);
	reg _sv2v_0;
	parameter signed [31:0] DEPTH = 1024;
	input wire clk;
	input wire rst_n;
	input wire [31:0] addr_word;
	output reg [31:0] instr_out;
	input wire tb_we;
	input wire [$clog2(DEPTH) - 1:0] tb_addr;
	input wire [31:0] tb_wdata;
	reg [31:0] mem [0:DEPTH - 1];
	always @(*) begin
		if (_sv2v_0)
			;
		if (addr_word < DEPTH)
			instr_out = mem[addr_word];
		else
			instr_out = 32'h00000000;
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			;
		else if (tb_we)
			mem[tb_addr] <= tb_wdata;
	initial _sv2v_0 = 0;
endmodule
module data_memory (
	clk,
	rst_n,
	cpu_we,
	cpu_addr,
	cpu_wdata,
	cpu_rdata,
	tb_we,
	tb_addr,
	tb_wdata,
	tb_re,
	tb_rdata
);
	reg _sv2v_0;
	parameter signed [31:0] DEPTH = 1024;
	input wire clk;
	input wire rst_n;
	input wire cpu_we;
	input wire [$clog2(DEPTH) - 1:0] cpu_addr;
	input wire [31:0] cpu_wdata;
	output reg [31:0] cpu_rdata;
	input wire tb_we;
	input wire [$clog2(DEPTH) - 1:0] tb_addr;
	input wire [31:0] tb_wdata;
	input wire tb_re;
	output reg [31:0] tb_rdata;
	reg [31:0] mem [0:DEPTH - 1];
	always @(*) begin
		if (_sv2v_0)
			;
		if (cpu_addr < DEPTH)
			cpu_rdata = mem[cpu_addr];
		else
			cpu_rdata = 32'h00000000;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (tb_re && (tb_addr < DEPTH))
			tb_rdata = mem[tb_addr];
		else
			tb_rdata = 32'h00000000;
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			;
		else if (cpu_we && (cpu_addr < DEPTH))
			mem[cpu_addr] <= cpu_wdata;
		else if (tb_we && (tb_addr < DEPTH))
			mem[tb_addr] <= tb_wdata;
	initial _sv2v_0 = 0;
endmodule
module cpu_top (
	clk,
	rst_n,
	tb_imem_we,
	tb_imem_addr,
	tb_imem_wdata,
	tb_dmem_we,
	tb_dmem_addr,
	tb_dmem_wdata,
	tb_dmem_re,
	tb_dmem_rdata,
	tb_reg_rd_addr,
	tb_reg_rd_data,
	pc_out,
	current_instr
);
	reg _sv2v_0;
	parameter signed [31:0] IMEM_DEPTH = 1024;
	parameter signed [31:0] DMEM_DEPTH = 1024;
	input wire clk;
	input wire rst_n;
	input wire tb_imem_we;
	input wire [$clog2(IMEM_DEPTH) - 1:0] tb_imem_addr;
	input wire [31:0] tb_imem_wdata;
	input wire tb_dmem_we;
	input wire [$clog2(DMEM_DEPTH) - 1:0] tb_dmem_addr;
	input wire [31:0] tb_dmem_wdata;
	input wire tb_dmem_re;
	output wire [31:0] tb_dmem_rdata;
	localparam signed [31:0] isa_defs_pkg_REG_ADDR_W = 3;
	input wire [2:0] tb_reg_rd_addr;
	output wire [31:0] tb_reg_rd_data;
	output wire [31:0] pc_out;
	output wire [31:0] current_instr;
	reg [31:0] pc;
	assign pc_out = pc;
	wire [31:0] instr;
	instruction_memory #(.DEPTH(IMEM_DEPTH)) imem(
		.clk(clk),
		.rst_n(rst_n),
		.addr_word(pc),
		.instr_out(instr),
		.tb_we(tb_imem_we),
		.tb_addr(tb_imem_addr),
		.tb_wdata(tb_imem_wdata)
	);
	assign current_instr = instr;
	wire is_rtype;
	wire is_itype;
	wire is_nop;
	wire [2:0] alu_op;
	wire reg_write_en;
	wire mem_read;
	wire mem_write;
	wire [2:0] rd_addr;
	wire [2:0] rs1_addr;
	wire [2:0] rs2_addr;
	localparam signed [31:0] isa_defs_pkg_IMM_W = 16;
	wire signed [15:0] imm16;
	control_unit cu(
		.instr(instr),
		.is_rtype(is_rtype),
		.is_itype(is_itype),
		.is_nop(is_nop),
		.alu_op(alu_op),
		.reg_write_en(reg_write_en),
		.mem_read(mem_read),
		.mem_write(mem_write),
		.rd_addr(rd_addr),
		.rs1_addr(rs1_addr),
		.rs2_addr(rs2_addr),
		.imm16(imm16)
	);
	wire [31:0] rs1_val;
	wire [31:0] rs2_val;
	reg [31:0] write_back_data;
	regfile rf(
		.clk(clk),
		.rst_n(rst_n),
		.rs1_addr(rs1_addr),
		.rs2_addr(rs2_addr),
		.rs1_data(rs1_val),
		.rs2_data(rs2_val),
		.we(reg_write_en),
		.rd_addr(rd_addr),
		.rd_data(write_back_data),
		.tb_rd_addr(tb_reg_rd_addr),
		.tb_rd_data(tb_reg_rd_data)
	);
	reg [31:0] alu_b_operand;
	always @(*) begin
		if (_sv2v_0)
			;
		if (is_itype)
			alu_b_operand = {{16 {imm16[15]}}, imm16};
		else
			alu_b_operand = rs2_val;
	end
	wire [31:0] alu_result;
	alu alu_inst(
		.a(rs1_val),
		.b(alu_b_operand),
		.op(alu_op),
		.result(alu_result)
	);
	wire [31:0] dmem_rdata;
	data_memory #(.DEPTH(DMEM_DEPTH)) dmem(
		.clk(clk),
		.rst_n(rst_n),
		.cpu_we(mem_write),
		.cpu_addr(alu_result[$clog2(DMEM_DEPTH) - 1:0]),
		.cpu_wdata(rs2_val),
		.cpu_rdata(dmem_rdata),
		.tb_we(tb_dmem_we),
		.tb_addr(tb_dmem_addr),
		.tb_wdata(tb_dmem_wdata),
		.tb_re(tb_dmem_re),
		.tb_rdata(tb_dmem_rdata)
	);
	always @(*) begin
		if (_sv2v_0)
			;
		if (mem_read)
			write_back_data = dmem_rdata;
		else
			write_back_data = alu_result;
	end
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			pc <= 32'h00000000;
		else
			pc <= pc + 1;
	initial _sv2v_0 = 0;
endmodule
