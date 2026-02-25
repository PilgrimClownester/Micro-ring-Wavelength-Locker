// ===========================================================
// 修改版：支持使能控制的 Stage-2 FIR 硬件模块
// 架构：对称型 + CSD 无乘法逻辑
// 采样率转换：50kHz -> 200kHz (4x 插值级联项)
// ===========================================================

module fir_stage2 (
    input  wire                   clk,      // 3.2MHz 主时钟
    input  wire                   rst_n,
    input  wire                   en,       // 200kHz 使能信号 (由顶层产生)
    input  wire signed [15:0]    data_in, 
    output reg  signed [15:0]    data_out  // 修改为寄存器型输出
);

// 1. 移位寄存器流水线 (仅在 en 有效时工作)
reg signed [15:0] shift_reg [0:41];
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i=0; i<42; i=i+1) shift_reg[i] <= 0;
    end else if (en) begin
        shift_reg[0] <= data_in;
        for (i=1; i<42; i=i+1) shift_reg[i] <= shift_reg[i-1];
    end
end

// 2. 对称项预加 (组合逻辑，随寄存器自动更新)
wire signed [16:0] pre_sum_0 = shift_reg[0] + shift_reg[41];
wire signed [16:0] pre_sum_1 = shift_reg[1] + shift_reg[40];
wire signed [16:0] pre_sum_2 = shift_reg[2] + shift_reg[39];
wire signed [16:0] pre_sum_3 = shift_reg[3] + shift_reg[38];
wire signed [16:0] pre_sum_4 = shift_reg[4] + shift_reg[37];
wire signed [16:0] pre_sum_5 = shift_reg[5] + shift_reg[36];
wire signed [16:0] pre_sum_6 = shift_reg[6] + shift_reg[35];
wire signed [16:0] pre_sum_7 = shift_reg[7] + shift_reg[34];
wire signed [16:0] pre_sum_8 = shift_reg[8] + shift_reg[33];
wire signed [16:0] pre_sum_9 = shift_reg[9] + shift_reg[32];
wire signed [16:0] pre_sum_10 = shift_reg[10] + shift_reg[31];
wire signed [16:0] pre_sum_11 = shift_reg[11] + shift_reg[30];
wire signed [16:0] pre_sum_12 = shift_reg[12] + shift_reg[29];
wire signed [16:0] pre_sum_13 = shift_reg[13] + shift_reg[28];
wire signed [16:0] pre_sum_14 = shift_reg[14] + shift_reg[27];
wire signed [16:0] pre_sum_15 = shift_reg[15] + shift_reg[26];
wire signed [16:0] pre_sum_16 = shift_reg[16] + shift_reg[25];
wire signed [16:0] pre_sum_17 = shift_reg[17] + shift_reg[24];
wire signed [16:0] pre_sum_18 = shift_reg[18] + shift_reg[23];
wire signed [16:0] pre_sum_19 = shift_reg[19] + shift_reg[22];
wire signed [16:0] pre_sum_20 = shift_reg[20] + shift_reg[21];

// 3. CSD 无乘法器计算层
wire signed [34:0] prod_0 = (pre_sum_0 << 2);
wire signed [34:0] prod_1 = (pre_sum_1 << 5) - (pre_sum_1 << 3) - pre_sum_1;
wire signed [34:0] prod_2 = (pre_sum_2 << 6) - (pre_sum_2 << 4) + pre_sum_2;
wire signed [34:0] prod_3 = (pre_sum_3 << 6) - (pre_sum_3 << 3);
wire signed [34:0] prod_4 = -(pre_sum_4 << 3);
wire signed [34:0] prod_5 = -(pre_sum_5 << 7) - (pre_sum_5 << 5) - (pre_sum_5 << 3) + (pre_sum_5 << 1);
wire signed [34:0] prod_6 = -(pre_sum_6 << 9) + (pre_sum_6 << 7) + (pre_sum_6 << 5) - (pre_sum_6 << 1);
wire signed [34:0] prod_7 = -(pre_sum_7 << 9) + (pre_sum_7 << 7) - (pre_sum_7 << 3) + (pre_sum_7 << 1);
wire signed [34:0] prod_8 = -(pre_sum_8 << 6) - (pre_sum_8 << 2) - pre_sum_8;
wire signed [34:0] prod_9 = (pre_sum_9 << 9) + (pre_sum_9 << 7) - (pre_sum_9 << 1);
wire signed [34:0] prod_10 = (pre_sum_10 << 11) - (pre_sum_10 << 9) - (pre_sum_10 << 7) - (pre_sum_10 << 3);
wire signed [34:0] prod_11 = (pre_sum_11 << 11) - (pre_sum_11 << 9) + (pre_sum_11 << 5) - (pre_sum_11 << 3);
wire signed [34:0] prod_12 = (pre_sum_12 << 9) - (pre_sum_12 << 3) - (pre_sum_12 << 1);
wire signed [34:0] prod_13 = -(pre_sum_13 << 11) + (pre_sum_13 << 8) + (pre_sum_13 << 4);
wire signed [34:0] prod_14 = -(pre_sum_14 << 12) - (pre_sum_14 << 7) - (pre_sum_14 << 5) + (pre_sum_14 << 3) - pre_sum_14;
wire signed [34:0] prod_15 = -(pre_sum_15 << 12) - (pre_sum_15 << 10) + (pre_sum_15 << 7) - (pre_sum_15 << 5) - (pre_sum_15 << 3);
wire signed [34:0] prod_16 = -(pre_sum_16 << 11) - (pre_sum_16 << 8) + (pre_sum_16 << 6) + (pre_sum_16 << 2) - pre_sum_16;
wire signed [34:0] prod_17 = (pre_sum_17 << 12) + (pre_sum_17 << 10) - (pre_sum_17 << 8) - (pre_sum_17 << 5) + (pre_sum_17 << 3) - pre_sum_17;
wire signed [34:0] prod_18 = (pre_sum_18 << 14) - (pre_sum_18 << 11) + (pre_sum_18 << 9) + (pre_sum_18 << 6) - (pre_sum_18 << 4);
wire signed [34:0] prod_19 = (pre_sum_19 << 15) - (pre_sum_19 << 13) + (pre_sum_19 << 8) + pre_sum_19;
wire signed [34:0] prod_20 = (pre_sum_20 << 15) - (pre_sum_20 << 11) + (pre_sum_20 << 8) + (pre_sum_20 << 5) + (pre_sum_20 << 3) + pre_sum_20;

// 4. 累加逻辑
wire signed [34:0] full_sum = 
    prod_0 + prod_1 + prod_2 + prod_3 + prod_4 + prod_5 + prod_6 + prod_7 + prod_8 + prod_9 + 
    prod_10 + prod_11 + prod_12 + prod_13 + prod_14 + prod_15 + prod_16 + prod_17 + prod_18 + prod_19 + 
    prod_20;

// 输出锁存与四舍五入截断 (仅在 en 有效时更新结果)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 16'd0;
    end else if (en) begin
        data_out <= (full_sum + (1 << 16)) >>> 17;
    end
end

endmodule