module decoder_riscv (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);

    import riscv_pkg::*;
    import alu_opcodes_pkg::*; 
    import csr_pkg::*;
    
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [1:0] opcode_check;
    logic [4:0] opcode;

    assign funct7       = fetched_instr_i[31:25];
    assign funct3       = fetched_instr_i[14:12];
    assign opcode_check = fetched_instr_i[1:0];
    assign opcode       = fetched_instr_i[6:2];
    
    always_comb begin
        a_sel_o         <= 0;
        b_sel_o         <= 0;
        alu_op_o        <= 0;
        csr_op_o        <= 0;
        csr_we_o        <= 0;
        mem_req_o       <= 0;
        mem_we_o        <= 0;
        mem_size_o      <= 0;
        gpr_we_o        <= 0;
        wb_sel_o        <= 0;
        illegal_instr_o <= 0;
        branch_o        <= 0;
        jal_o           <= 0;
        jalr_o          <= 0;
        mret_o          <= 0;
        
        if (opcode_check != 2'b11) illegal_instr_o <= 1;
        else begin
        case(opcode)
        
            OP_OPCODE: begin
                if (funct7 != 7'b0000000) illegal_instr_o <= 1;
                else gpr_we_o <= 1;
                wb_sel_o <= 0;
                
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000) begin 
                            alu_op_o        <= ALU_SUB;
                            illegal_instr_o <= 0;
                            gpr_we_o        <= 1;
                        end
                        else  alu_op_o <= ALU_ADD;
                    end
                    
                    3'b001:
                        alu_op_o <= ALU_SLL;
                    
                    3'b010: 
                        alu_op_o <= ALU_SLTS;
                    
                    3'b011:  
                        alu_op_o <= ALU_SLTU;
                        
                    3'b100: 
                        alu_op_o <= ALU_XOR;
                        
                    3'b101: begin
                        if (funct7 == 7'b0100000) begin
                            alu_op_o        <= ALU_SRA;
                            illegal_instr_o <= 0;
                            gpr_we_o        <= 1;
                        end
                        else alu_op_o <= ALU_SRL;
                    end
                    
                    3'b110:
                        alu_op_o <= ALU_OR;
                        
                    3'b111:  
                        alu_op_o <= ALU_AND;
                endcase
            end
            
            OP_IMM_OPCODE: begin
                b_sel_o     <= 1;
                mem_size_o  <= 3'b010;
                gpr_we_o    <= 1;
                wb_sel_o    <= 0;
                
                case (funct3)
                    3'b000: 
                        alu_op_o <= ALU_ADD;
                    
                    3'b010: 
                        alu_op_o <= ALU_SLTS;
                    
                    3'b011:  
                        alu_op_o <= ALU_SLTU;
                        
                    3'b100: 
                        alu_op_o <= ALU_XOR;
                    
                    3'b110:
                        alu_op_o <= ALU_OR;
                        
                    3'b111:  
                        alu_op_o <= ALU_AND;
                        
                    3'b001: begin
                        if (funct7 == 7'b0000000) alu_op_o <= ALU_SLL;
                        else begin
                            illegal_instr_o <= 1;
                            gpr_we_o        <= 0;
                        end
                    end
                        
                    3'b101: begin
                        if (funct7 == 7'b0000000) alu_op_o <= ALU_SRL;
                        else if (funct7 == 7'b0100000) alu_op_o <= ALU_SRA;
                        else begin
                            illegal_instr_o <= 1;
                            gpr_we_o        <= 0;
                        end
                    end
                endcase
            end
            
            LUI_OPCODE: begin
                gpr_we_o <= 1;
                a_sel_o  <= 2;
                b_sel_o  <= 2;
            end
            
            LOAD_OPCODE: begin
                if (funct3 != 3 && funct3 < 6) begin
                    b_sel_o     <= 1;
                    gpr_we_o    <= 1;
                    mem_size_o  <= funct3;
                    mem_req_o   <= 1;
                    wb_sel_o    <= 1;
                end
                else illegal_instr_o <= 1;
            end
            
            STORE_OPCODE: begin
                if (funct3 < 3) begin
                    b_sel_o     <= 3;
                    mem_size_o  <= funct3;
                    mem_req_o   <= 1;
                    mem_we_o    <= 1;
                end
                else illegal_instr_o <= 1;
            end
            
            BRANCH_OPCODE: begin
                branch_o <= 1;
                
                case (funct3)
                    3'b000: alu_op_o <= ALU_EQ;
                    
                    3'b001: alu_op_o <= ALU_NE;
                    
                    3'b100: alu_op_o <= ALU_LTS;
                    
                    3'b101: alu_op_o <= ALU_GES;
                    
                    3'b110: alu_op_o <= ALU_LTU;
                    
                    3'b111: alu_op_o <= ALU_GEU;
                    
                    default: begin
                        illegal_instr_o <= 1;
                        branch_o        <= 0;
                    end
                endcase
            end
            
            JAL_OPCODE: begin
                jal_o    <= 1;
                a_sel_o  <= 1;
                b_sel_o  <= 4;
                gpr_we_o <= 1;
            end
            
            JALR_OPCODE: begin
                if (funct3 == 3'b000) begin
                    jalr_o   <= 1;
                    a_sel_o  <= 1;
                    b_sel_o  <= 4;
                    gpr_we_o <= 1;
                end
                else illegal_instr_o <= 1;
            end
            
            AUIPC_OPCODE: begin
                gpr_we_o <= 1;
                a_sel_o  <= 1;
                b_sel_o  <= 2;
            end
            
            MISC_MEM_OPCODE: begin
                if (funct3 != 3'b000) illegal_instr_o <= 1;
            end
             
            SYSTEM_OPCODE: begin
                gpr_we_o <= 1;
                csr_we_o <= 1;
                wb_sel_o <= 2;
                
                case (funct3)
                    3'b000: begin
                        gpr_we_o <= 0;
                        csr_we_o <= 0;
                        
                        if (fetched_instr_i == 32'b00110000001000000000000001110011) mret_o <= 1;
                        else begin 
                            illegal_instr_o <= 1;
                        end
                    end
                        
                    3'b001: csr_op_o <= CSR_RW;
                    
                    3'b010: csr_op_o <= CSR_RS;
                    
                    3'b011: csr_op_o <= CSR_RC;
                    
                    3'b101: csr_op_o <= CSR_RWI;
                    
                    3'b110: csr_op_o <= CSR_RSI;
                    
                    3'b111: csr_op_o <= CSR_RCI;
                    
                    default: begin
                        illegal_instr_o <= 1;
                        gpr_we_o        <= 0;
                        csr_we_o        <= 0;
                    end
                        
                endcase
            end           
            default:
                illegal_instr_o <= 1;
        endcase
        end
    end
endmodule