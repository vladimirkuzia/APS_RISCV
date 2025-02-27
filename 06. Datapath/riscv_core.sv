module riscv_core(
    input  logic        clk_i,
    input  logic        rst_i,
    
    input  logic        stall_i,
    input  logic [31:0] instr_i,
    input  logic [31:0] mem_rd_i,
    
    output logic [31:0] instr_addr_o,
    output logic [31:0] mem_addr_o,
    output logic [2:0]  mem_size_o,
    output logic        mem_req_o,
    output logic        mem_we_o,
    output logic [31:0] mem_wd_o,
    
    input  logic        irq_req_i,
    output logic        irq_ret_o
);
    
logic [31:0] pc;
logic [31:0] adder_pc;

logic [31:0] imm_I;
logic [31:0] imm_U;
logic [31:0] imm_S;
logic [31:0] imm_B;
logic [31:0] imm_J;
logic [31:0] imm_Z;

logic [4:0]  RA1;
logic [4:0]  RA2;
logic [4:0]  WA;
logic [31:0] RD1;
logic [31:0] RD2;
logic [31:0] wb_data;

logic [1:0] a_sel;
logic [2:0] b_sel;
logic [4:0] alu_op;
logic [2:0] csr_op;
logic       csr_we;
logic       mem_req;
logic       mem_we;
logic       rf_we;
logic       gpr_we;
logic [1:0] wb_sel;
logic       illegal_instr;
logic       branch; 
logic       jal;
logic       jalr;
logic       mret;

logic [31:0] first_operand;
logic [31:0] second_operand;
logic [31:0] alu_res;
logic        alu_flag;

logic irq;
logic pc_enable;

logic [31:0] adder1_second;
logic [31:0] adder1_result;
logic [31:0] adder2_result;

assign imm_I = {{20{instr_i[31]}}, instr_i[31:20]};
assign imm_U = { instr_i[31:12]  ,   12'h00};
assign imm_S = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
assign imm_B = {{20{instr_i[31]}}, instr_i[7]    , instr_i[30:25], instr_i[11:8 ], 1'b0};
assign imm_J = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20]   , instr_i[30:21], 1'b0};
assign imm_Z = {{27{1'b0}}       , instr_i[19:15]};

assign RA1   = instr_i[19:15];
assign RA2   = instr_i[24:20];
assign WA    = instr_i[11:07];

logic        trap;
logic [31:0] csr_wd;
logic [31:0] mie;
logic [31:0] mepc;
logic [31:0] mtvec;
logic [31:0] mcause;
logic [31:0] irq_cause;

assign mcause    = illegal_instr ? 32'h00000002 : irq_cause;
assign trap      = irq | illegal_instr;
assign pc_enable = ~stall_i | trap;

always_ff @(posedge clk_i) begin
    if (pc_enable) begin
        if (rst_i) pc <= 0;
        else pc <= adder_pc;
    end
end

always_comb begin
    case (a_sel)
        0: first_operand = RD1;
        1: first_operand = pc;
        2: first_operand = 32'b0;
        default: first_operand = 32'b0;
    endcase
end

always_comb begin
    case (b_sel)
        0: second_operand = RD2;
        1: second_operand = imm_I;
        2: second_operand = imm_U;
        3: second_operand = imm_S;
        4: second_operand = 32'd4;
        default: second_operand = 32'd4;
    endcase
end

always_comb begin
    case (wb_sel)
        0: wb_data = alu_res;
        1: wb_data = mem_rd_i;
        2: wb_data = csr_wd;
        default: wb_data = alu_res;
    endcase
end

logic  jump;
assign jump = jal | (branch & alu_flag);

always_comb begin
    case (jump)
        0: adder1_second = 32'd4;
        1: adder1_second = branch ? imm_B : imm_J;
    endcase
end

always_comb begin
    if (mret) adder_pc = mepc;
    else begin
        if (trap) adder_pc = mtvec;
        else begin
            if (jalr) adder_pc = {adder1_result[31:1],1'b0};
            else      adder_pc = adder2_result;
        end
    end
end

rf_riscv rf (
    .clk_i          (clk_i),
    .write_enable_i (rf_we),
    .write_addr_i   (WA),
    .read_addr1_i   (RA1),
    .read_addr2_i   (RA2),
    .write_data_i   (wb_data),
    .read_data1_o   (RD1),
    .read_data2_o   (RD2)
);

decoder_riscv decoder(
    .fetched_instr_i(instr_i),
    .a_sel_o        (a_sel),
    .b_sel_o        (b_sel),
    .alu_op_o       (alu_op),
    .csr_op_o       (csr_op),
    .csr_we_o       (csr_we),
    .mem_req_o      (mem_req),
    .mem_we_o       (mem_we),
    .mem_size_o     (mem_size_o),
    .gpr_we_o       (gpr_we),
    .wb_sel_o       (wb_sel),
    .illegal_instr_o(illegal_instr),
    .branch_o       (branch),
    .jal_o          (jal),
    .jalr_o         (jalr),
    .mret_o         (mret)
);

alu_riscv alu (
    .a_i            (first_operand),
    .b_i            (second_operand),
    .alu_op_i       (alu_op),
    .flag_o         (alu_flag),
    .result_o       (alu_res)
);

fulladder32 adder1 (
    .a_i            (pc),
    .b_i            (adder1_second),
    .sum_o          (adder2_result),
    .carry_i        (1'b0)
);

fulladder32 adder2 (
    .a_i            (RD1),
    .b_i            (imm_I),
    .sum_o          (adder1_result),
    .carry_i        (1'b0)
);

csr_controller csr (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .trap_i         (trap),
    .opcode_i       (csr_op),
    .addr_i         (instr_i[31:20]),
    .pc_i           (pc),
    .mcause_i       (mcause),
    .rs1_data_i     (RD1),
    .imm_data_i     (imm_Z),
    .write_enable_i (csr_we),
    .read_data_o    (csr_wd),
    .mie_o          (mie),
    .mepc_o         (mepc),
    .mtvec_o        (mtvec)
);

interrupt_controller irc (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .exception_i    (illegal_instr),
    .irq_req_i      (irq_req_i),
    .mie_i          (mie[0]),
    .mret_i         (mret),
    .irq_ret_o      (irq_ret_o),
    .irq_cause_o    (irq_cause),
    .irq_o          (irq)
);

assign instr_addr_o = pc;
assign mem_addr_o   = alu_res;
assign mem_wd_o     = RD2;
assign mem_req_o    = ~trap & mem_req;
assign mem_we_o     = ~trap & mem_we;
assign rf_we        = gpr_we & ~(stall_i | trap);
    
endmodule