// ===========================================================
// 修改版：支持使能控制的 Stage-1 Halfband FIR
// 适用于 128x 插值链级联
// ===========================================================

module fir_stage1 (
    input  wire                   clk,      // 3.2MHz 主时钟
    input  wire                   rst_n,
    input  wire                   en,       // 使能信号 (由顶层计数器产生，50kHz 频率)
    input  wire signed [15:0]    data_in, 
    output reg  signed [15:0]    data_out  // 修改为 reg，方便数据保持
);

// 1. 移位寄存器流水线
reg signed [15:0] shift_reg [0:101];
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i=0; i<102; i=i+1) shift_reg[i] <= 0;
    end else if (en) begin  // 只有在使能有效时才进行移位
        shift_reg[0] <= data_in;
        for (i=1; i<102; i=i+1) shift_reg[i] <= shift_reg[i-1];
    end
end

// 2. 对称项预加 (组合逻辑，随 shift_reg 自动变化)
wire signed [16:0] pre_sum_0 = shift_reg[0] + shift_reg[101];
wire signed [16:0] pre_sum_1 = shift_reg[1] + shift_reg[100];
wire signed [16:0] pre_sum_2 = shift_reg[2] + shift_reg[99];
wire signed [16:0] pre_sum_3 = shift_reg[3] + shift_reg[98];
wire signed [16:0] pre_sum_4 = shift_reg[4] + shift_reg[97];
wire signed [16:0] pre_sum_5 = shift_reg[5] + shift_reg[96];
wire signed [16:0] pre_sum_6 = shift_reg[6] + shift_reg[95];
wire signed [16:0] pre_sum_7 = shift_reg[7] + shift_reg[94];
wire signed [16:0] pre_sum_8 = shift_reg[8] + shift_reg[93];
wire signed [16:0] pre_sum_9 = shift_reg[9] + shift_reg[92];
wire signed [16:0] pre_sum_10 = shift_reg[10] + shift_reg[91];
wire signed [16:0] pre_sum_11 = shift_reg[11] + shift_reg[90];
wire signed [16:0] pre_sum_12 = shift_reg[12] + shift_reg[89];
wire signed [16:0] pre_sum_13 = shift_reg[13] + shift_reg[88];
wire signed [16:0] pre_sum_14 = shift_reg[14] + shift_reg[87];
wire signed [16:0] pre_sum_15 = shift_reg[15] + shift_reg[86];
wire signed [16:0] pre_sum_16 = shift_reg[16] + shift_reg[85];
wire signed [16:0] pre_sum_17 = shift_reg[17] + shift_reg[84];
wire signed [16:0] pre_sum_18 = shift_reg[18] + shift_reg[83];
wire signed [16:0] pre_sum_19 = shift_reg[19] + shift_reg[82];
wire signed [16:0] pre_sum_20 = shift_reg[20] + shift_reg[81];
wire signed [16:0] pre_sum_21 = shift_reg[21] + shift_reg[80];
wire signed [16:0] pre_sum_22 = shift_reg[22] + shift_reg[79];
wire signed [16:0] pre_sum_23 = shift_reg[23] + shift_reg[78];
wire signed [16:0] pre_sum_24 = shift_reg[24] + shift_reg[77];
wire signed [16:0] pre_sum_25 = shift_reg[25] + shift_reg[76];
wire signed [16:0] pre_sum_26 = shift_reg[26] + shift_reg[75];
wire signed [16:0] pre_sum_27 = shift_reg[27] + shift_reg[74];
wire signed [16:0] pre_sum_28 = shift_reg[28] + shift_reg[73];
wire signed [16:0] pre_sum_29 = shift_reg[29] + shift_reg[72];
wire signed [16:0] pre_sum_30 = shift_reg[30] + shift_reg[71];
wire signed [16:0] pre_sum_31 = shift_reg[31] + shift_reg[70];
wire signed [16:0] pre_sum_32 = shift_reg[32] + shift_reg[69];
wire signed [16:0] pre_sum_33 = shift_reg[33] + shift_reg[68];
wire signed [16:0] pre_sum_34 = shift_reg[34] + shift_reg[67];
wire signed [16:0] pre_sum_35 = shift_reg[35] + shift_reg[66];
wire signed [16:0] pre_sum_36 = shift_reg[36] + shift_reg[65];
wire signed [16:0] pre_sum_37 = shift_reg[37] + shift_reg[64];
wire signed [16:0] pre_sum_38 = shift_reg[38] + shift_reg[63];
wire signed [16:0] pre_sum_39 = shift_reg[39] + shift_reg[62];
wire signed [16:0] pre_sum_40 = shift_reg[40] + shift_reg[61];
wire signed [16:0] pre_sum_41 = shift_reg[41] + shift_reg[60];
wire signed [16:0] pre_sum_42 = shift_reg[42] + shift_reg[59];
wire signed [16:0] pre_sum_43 = shift_reg[43] + shift_reg[58];
wire signed [16:0] pre_sum_44 = shift_reg[44] + shift_reg[57];
wire signed [16:0] pre_sum_45 = shift_reg[45] + shift_reg[56];
wire signed [16:0] pre_sum_46 = shift_reg[46] + shift_reg[55];
wire signed [16:0] pre_sum_47 = shift_reg[47] + shift_reg[54];
wire signed [16:0] pre_sum_48 = shift_reg[48] + shift_reg[53];
wire signed [16:0] pre_sum_49 = shift_reg[49] + shift_reg[52];
wire signed [16:0] pre_sum_50 = shift_reg[50] + shift_reg[51];

// 3. CSD 无乘法器计算层 (组合逻辑)
wire signed [34:0] prod_0 = -pre_sum_0;
wire signed [34:0] prod_1 = pre_sum_1;
wire signed [34:0] prod_2 = (pre_sum_2 << 2) - pre_sum_2;
wire signed [34:0] prod_3 = -(pre_sum_3 << 2) + pre_sum_3;
wire signed [34:0] prod_4 = -(pre_sum_4 << 2) - pre_sum_4;
wire signed [34:0] prod_5 = (pre_sum_5 << 3) - (pre_sum_5 << 1);
wire signed [34:0] prod_6 = (pre_sum_6 << 3) + (pre_sum_6 << 1);
wire signed [34:0] prod_7 = -(pre_sum_7 << 4) + (pre_sum_7 << 2) + pre_sum_7;
wire signed [34:0] prod_8 = -(pre_sum_8 << 4) - pre_sum_8;
wire signed [34:0] prod_9 = (pre_sum_9 << 4) + (pre_sum_9 << 2) - pre_sum_9;
wire signed [34:0] prod_10 = (pre_sum_10 << 5) - (pre_sum_10 << 2);
wire signed [34:0] prod_11 = -(pre_sum_11 << 5) + (pre_sum_11 << 1);
wire signed [34:0] prod_12 = -(pre_sum_12 << 6) + (pre_sum_12 << 4) + (pre_sum_12 << 2) + pre_sum_12;
wire signed [34:0] prod_13 = (pre_sum_13 << 6) - (pre_sum_13 << 4) - pre_sum_13;
wire signed [34:0] prod_14 = (pre_sum_14 << 6);
wire signed [34:0] prod_15 = -(pre_sum_15 << 6) - (pre_sum_15 << 2) - pre_sum_15;
wire signed [34:0] prod_16 = -(pre_sum_16 << 7) + (pre_sum_16 << 5) + (pre_sum_16 << 2) - pre_sum_16;
wire signed [34:0] prod_17 = (pre_sum_17 << 7) - (pre_sum_17 << 5) + (pre_sum_17 << 2);
wire signed [34:0] prod_18 = (pre_sum_18 << 7) + (pre_sum_18 << 2) - pre_sum_18;
wire signed [34:0] prod_19 = -(pre_sum_19 << 7) - (pre_sum_19 << 4) + (pre_sum_19 << 2) - pre_sum_19;
wire signed [34:0] prod_20 = -(pre_sum_20 << 8) + (pre_sum_20 << 6) + (pre_sum_20 << 4) - (pre_sum_20 << 2) - pre_sum_20;
wire signed [34:0] prod_21 = (pre_sum_21 << 8) - (pre_sum_21 << 6) + (pre_sum_21 << 1);
wire signed [34:0] prod_22 = (pre_sum_22 << 8) - (pre_sum_22 << 4) + (pre_sum_22 << 2);
wire signed [34:0] prod_23 = -(pre_sum_23 << 8) - (pre_sum_23 << 3) + (pre_sum_23 << 1);
wire signed [34:0] prod_24 = -(pre_sum_24 << 8) - (pre_sum_24 << 6) - (pre_sum_24 << 2) - pre_sum_24;
wire signed [34:0] prod_25 = (pre_sum_25 << 9) - (pre_sum_25 << 7) - (pre_sum_25 << 5) - (pre_sum_25 << 2);
wire signed [34:0] prod_26 = (pre_sum_26 << 9) - (pre_sum_26 << 7) + (pre_sum_26 << 5) + (pre_sum_26 << 3) + (pre_sum_26 << 1);
wire signed [34:0] prod_27 = -(pre_sum_27 << 9) + (pre_sum_27 << 6) - (pre_sum_27 << 3);
wire signed [34:0] prod_28 = -(pre_sum_28 << 9) - (pre_sum_28 << 5) - (pre_sum_28 << 3);
wire signed [34:0] prod_29 = (pre_sum_29 << 9) + (pre_sum_29 << 6) + (pre_sum_29 << 4) - pre_sum_29;
wire signed [34:0] prod_30 = (pre_sum_30 << 10) - (pre_sum_30 << 8) - (pre_sum_30 << 6) + (pre_sum_30 << 2) - pre_sum_30;
wire signed [34:0] prod_31 = -(pre_sum_31 << 10) + (pre_sum_31 << 8) + (pre_sum_31 << 3);
wire signed [34:0] prod_32 = -(pre_sum_32 << 10) + (pre_sum_32 << 7) - (pre_sum_32 << 2);
wire signed [34:0] prod_33 = (pre_sum_33 << 10) - (pre_sum_33 << 6) + (pre_sum_33 << 3) + pre_sum_33;
wire signed [34:0] prod_34 = (pre_sum_34 << 10) + (pre_sum_34 << 7) - (pre_sum_34 << 4) + (pre_sum_34 << 2);
wire signed [34:0] prod_35 = -(pre_sum_35 << 10) - (pre_sum_35 << 8) + (pre_sum_35 << 6) - (pre_sum_35 << 4) - (pre_sum_35 << 1);
wire signed [34:0] prod_36 = -(pre_sum_36 << 11) + (pre_sum_36 << 9) + (pre_sum_36 << 7) - (pre_sum_36 << 5) - (pre_sum_36 << 2) + pre_sum_36;
wire signed [34:0] prod_37 = (pre_sum_37 << 11) - (pre_sum_37 << 9) + (pre_sum_37 << 5) + (pre_sum_37 << 2);
wire signed [34:0] prod_38 = (pre_sum_38 << 11) - (pre_sum_38 << 8) + (pre_sum_38 << 6) - (pre_sum_38 << 4) - (pre_sum_38 << 2) - pre_sum_38;
wire signed [34:0] prod_39 = -(pre_sum_39 << 11) + (pre_sum_39 << 5) - (pre_sum_39 << 1);
wire signed [34:0] prod_40 = -(pre_sum_40 << 11) - (pre_sum_40 << 8) - (pre_sum_40 << 6) + (pre_sum_40 << 3) + pre_sum_40;
wire signed [34:0] prod_41 = (pre_sum_41 << 11) + (pre_sum_41 << 9) + (pre_sum_41 << 6) + (pre_sum_41 << 3) + pre_sum_41;
wire signed [34:0] prod_42 = (pre_sum_42 << 12) - (pre_sum_42 << 10) + (pre_sum_42 << 5) - (pre_sum_42 << 1);
wire signed [34:0] prod_43 = -(pre_sum_43 << 12) + (pre_sum_43 << 9) + (pre_sum_43 << 5) + (pre_sum_43 << 3) + pre_sum_43;
wire signed [34:0] prod_44 = -(pre_sum_44 << 12) - (pre_sum_44 << 7) - (pre_sum_44 << 5) - (pre_sum_44 << 2) + pre_sum_44;
wire signed [34:0] prod_45 = (pre_sum_45 << 12) + (pre_sum_45 << 10) - (pre_sum_45 << 6) + (pre_sum_45 << 3) - (pre_sum_45 << 1);
wire signed [34:0] prod_46 = (pre_sum_46 << 13) - (pre_sum_46 << 11) + (pre_sum_46 << 8) - (pre_sum_46 << 5) + (pre_sum_46 << 1);
wire signed [34:0] prod_47 = -(pre_sum_47 << 13) - (pre_sum_47 << 5) + (pre_sum_47 << 2) - pre_sum_47;
wire signed [34:0] prod_48 = -(pre_sum_48 << 14) + (pre_sum_48 << 12) + (pre_sum_48 << 9) + (pre_sum_48 << 6);
wire signed [34:0] prod_49 = (pre_sum_49 << 14) + (pre_sum_49 << 12) - (pre_sum_49 << 10) + (pre_sum_49 << 7) - (pre_sum_49 << 5) + (pre_sum_49 << 3) - (pre_sum_49 << 1);
wire signed [34:0] prod_50 = (pre_sum_50 << 16) - (pre_sum_50 << 13) + (pre_sum_50 << 11) - (pre_sum_50 << 9) + (pre_sum_50 << 7) + (pre_sum_50 << 2) + pre_sum_50;

// 4. 最终累加逻辑 (只有在使能有效时才计算并更新输出寄存器)
wire signed [34:0] full_sum = 
    prod_0 + prod_1 + prod_2 + prod_3 + prod_4 + prod_5 + prod_6 + prod_7 + prod_8 + prod_9 + 
    prod_10 + prod_11 + prod_12 + prod_13 + prod_14 + prod_15 + prod_16 + prod_17 + prod_18 + prod_19 + 
    prod_20 + prod_21 + prod_22 + prod_23 + prod_24 + prod_25 + prod_26 + prod_27 + prod_28 + prod_29 + 
    prod_30 + prod_31 + prod_32 + prod_33 + prod_34 + prod_35 + prod_36 + prod_37 + prod_38 + prod_39 + 
    prod_40 + prod_41 + prod_42 + prod_43 + prod_44 + prod_45 + prod_46 + prod_47 + prod_48 + prod_49 + 
    prod_50;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 16'd0;
    end else if (en) begin
        // 四舍五入截断逻辑 (从 Q17 还原) 并存入输出寄存器
        data_out <= (full_sum + (1 << 16)) >>> 17;
    end
end

endmodule