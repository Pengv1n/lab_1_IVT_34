`define I 3'd0
`define K 3'd1
`define S 3'd2
`define L 3'd3
`define F 3'd4

module kuznechik_cipher(
    input               clk_i,      // Тактовый сигнал
                        resetn_i,   // Синхронный сигнал сброса с активным уровнем LOW
                        request_i,  // Сигнал запроса на начало шифрования
                        ack_i,      // Сигнал подтверждения приема зашифрованных данных
                [127:0] data_i,     // Шифруемые данные

    output              busy_o,     // Сигнал, сообщающий о невозможности приёма
                                    // очередного запроса на шифрование, поскольку
                                    // модуль в процессе шифрования предыдущего
                                    // запроса
           reg          valid_o,    // Сигнал готовности зашифрованных данных
           reg  [127:0] data_o      // Зашифрованные данные
);

reg [127:0] key_mem [0:9];

reg [7:0] S_box_mem [0:255];

reg [7:0] L_mul_16_mem  [0:255];
reg [7:0] L_mul_32_mem  [0:255];
reg [7:0] L_mul_133_mem [0:255]; 
reg [7:0] L_mul_148_mem [0:255];
reg [7:0] L_mul_192_mem [0:255];
reg [7:0] L_mul_194_mem [0:255];
reg [7:0] L_mul_251_mem [0:255];

initial begin
    $readmemh("keys.mem",key_mem );
    $readmemh("S_box.mem",S_box_mem );

    $readmemh("L_16.mem", L_mul_16_mem );
    $readmemh("L_32.mem", L_mul_32_mem );
    $readmemh("L_133.mem",L_mul_133_mem);
    $readmemh("L_148.mem",L_mul_148_mem);
    $readmemh("L_192.mem",L_mul_192_mem);
    $readmemh("L_194.mem",L_mul_194_mem);
    $readmemh("L_251.mem",L_mul_251_mem);
end

//-------------------------------------------------------------------------------

reg [2:0] state;
integer i;
reg [7:0] tmp;
integer num_rnd;

assign busy_o = !(state == `I || state == `F) || ((request_i == 1) && (state == `I || state == `F));

always @(posedge clk_i) begin
    if (!resetn_i) begin
        i       = 0;
        state   <= `I;
        num_rnd = 0;
        tmp     <= 0;
        data_o  <= 0;
        valid_o <= 0;
    end
end
 
always @(posedge clk_i) begin
    if (resetn_i) begin
        case (state)
        
            `I: begin
                if (request_i) begin
                    data_o <= data_i;
                    state <= `K;
                end
            end
            
            `K: begin
                    if (resetn_i) begin
                        data_o <= data_o ^ key_mem[num_rnd];
                    end
                    if (num_rnd == 9) begin
                        state <= `F;
                        valid_o <= 1'b1;
                        num_rnd = 0;
                    end
                    else
                        state <= `S;
                end
            
            `S: begin
            if (resetn_i) begin
                        data_o[127:120] <= S_box_mem[data_o[127:120]];
                        data_o[119:112] <= S_box_mem [data_o[119:112]];
                        data_o[111:104] <= S_box_mem[data_o[111:104]];
                        data_o[103:96]  <= S_box_mem[data_o[103:96]];
                        data_o[95:88]   <= S_box_mem[data_o[95:88]];
                        data_o[87:80]   <= S_box_mem[data_o[87:80]];
                        data_o[79:72]   <= S_box_mem[data_o[79:72]];
                        data_o[71:64]   <= S_box_mem[data_o[71:64]];
                        data_o[63:56]   <= S_box_mem[data_o[63:56]];
                        data_o[55:48]   <= S_box_mem[data_o[55:48]];
                        data_o[47:40]   <= S_box_mem[data_o[47:40]];
                        data_o[39:32]   <= S_box_mem[data_o[39:32]];
                        data_o[31:24]   <= S_box_mem[data_o[31:24]];
                        data_o[23:16]   <= S_box_mem[data_o[23:16]];
                        data_o[15:8]    <= S_box_mem[data_o[15:8]];
                        data_o[7:0]     <= S_box_mem[data_o[7:0]];
                    end
                state <= `L;
            end
            
            `L: begin
                if (i == 15) begin
                    i = 0;
                    state <= `K;
                    num_rnd = num_rnd + 1;
                    tmp <= 0;
                end
                else
                    i = i + 1;
                    if (resetn_i) begin
                        tmp = tmp ^ L_mul_148_mem[data_o[127:120]]
                                  ^ L_mul_32_mem [data_o[119:112]]
                                  ^ L_mul_133_mem[data_o[111:104]]
                                  ^ L_mul_16_mem [data_o[103:96]]
                                  ^ L_mul_194_mem[data_o[95:88]]
                                  ^ L_mul_192_mem[data_o[87:80]]
                                  ^ data_o[79:72]
                                  ^ L_mul_251_mem[data_o[71:64]]
                                  ^ data_o[63:56]
                                  ^ L_mul_192_mem[data_o[55:48]]
                                  ^ L_mul_194_mem[data_o[47:40]]
                                  ^ L_mul_16_mem [data_o[39:32]]
                                  ^ L_mul_133_mem[data_o[31:24]]
                                  ^ L_mul_32_mem [data_o[23:16]]
                                  ^ L_mul_148_mem[data_o[15:8]]
                                  ^ data_o[7:0];
                        data_o <= data_o >> 8;
                        data_o[127:120] <= tmp;
                        tmp <= 0;
                        end
            end
            
            `F: begin
                if (request_i) begin
                    state <= `K;
                    data_o <= data_i;
                    valid_o <= 1'b0;
                end
                else begin
                    if (ack_i) begin
                        state <= `I;
                        valid_o <= 1'b0;
                    end
                end
            end
        endcase
    end
end

endmodule
