`timescale 1ns / 1ps

module cic_decimator_4th #(
    parameter R = 80  // 降采样率 (3.2MHz / 80 = 40kHz)
)(
    input  wire        clk,        // 3.2 MHz 采样时钟
    input  wire        rst_n,      
    input  wire signed [3:0]  din, // 来自 SDM 的输出
    
    output reg  signed [31:0] dout,     // 滤波后的高精度输出
    output reg         out_valid   // 降采样后的数据有效标志
);

    // 符号位扩展
    wire signed [31:0] din_ext = {{28{din[3]}}, din}; 

    // 1. 积分器级 (Running @ 3.2MHz)
    reg signed [31:0] i1, i2, i3, i4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin i1<=0; i2<=0; i3<=0; i4<=0; end
        else begin
            i1 <= i1 + din_ext;
            i2 <= i2 + i1;
            i3 <= i3 + i2;
            i4 <= i4 + i3;
        end
    end

    // 2. 降采样控制
    reg [6:0] cnt;
    reg       dec_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin cnt <= 0; dec_en <= 0; end
        else if (cnt == R-1) begin cnt <= 0; dec_en <= 1; end
        else begin cnt <= cnt + 1; dec_en <= 0; end
    end

    // 3. 梳状器级 (Running @ 40kHz)
    reg signed [31:0] c1_d, c2_d, c3_d, c4_d;
    reg signed [31:0] c1, c2, c3, c4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c1_d<=0; c2_d<=0; c3_d<=0; c4_d<=0;
            dout<=0; out_valid<=0;
        end else begin
            out_valid <= dec_en;
            if (dec_en) begin
                c1   <= i4 - c1_d;   c1_d <= i4;
                c2   <= c1 - c2_d;   c2_d <= c1;
                c3   <= c2 - c3_d;   c3_d <= c2;
                c4   <= c3 - c4_d;   c4_d <= c3;
                dout <= c4;
            end
        end
    end
endmodule