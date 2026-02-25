`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: sdm_cifb_3rd_4bit
// Description: Optimized 3rd Order 4-bit SDM (CRFB Topology)
//              Coefficients optimized with multi-term CSD for high precision.
//              Math Format: Q8.24 (1 Sign, 7 Int, 24 Frac)
//////////////////////////////////////////////////////////////////////////////////

module sdm_cifb_3rd_4bit(
    input  wire        clk,        // 3.2 MHz
    input  wire        rst_n,      
    input  wire signed [31:0] din, // Q8.24
    output wire signed [3:0]  dout // 4-bit Signed Integer
    );

    reg signed [31:0] int1, int2, int3;
    wire signed [31:0] v_fb;
    
    // 【DAC 反馈符号位扩展】
   // 【DAC 反馈符号位扩展：缩小 8 倍，让 dout=8 时才等于 1.0】
    assign v_fb = {{7{dout[3]}}, dout, 21'd0};

    //=======================================================
    // 3. 优化后的高精度 CSD 系数计算 (均通过移位实现)
    //=======================================================
    
    // a1 = b1 ≈ 0.01025 (误差从 14.7% 降至 0.52%)
    wire signed [31:0] term_a1_din = (din >>> 7)  + (din >>> 9)  + (din >>> 11);
    wire signed [31:0] term_a1_fb  = (v_fb >>> 7) + (v_fb >>> 9) + (v_fb >>> 11);

    // a2 ≈ 0.0239 (误差从 1.68% 降至 0.53%)
    wire signed [31:0] term_a2 = (v_fb >>> 5) - (v_fb >>> 7) + (v_fb >>> 11);

    // c1 ≈ 0.39746 (误差从 1.74% 降至 0.01%)
    wire signed [31:0] term_c1 = (int1 >>> 1) - (int1 >>> 3) + (int1 >>> 6) + (int1 >>> 7) - (int1 >>> 10);

    // c2 ≈ 0.80468 (误差从 6.71% 降至 0.08%)
    wire signed [31:0] term_c2 = int2 - (int2 >>> 2) + (int2 >>> 4) - (int2 >>> 7);

    // g1 ≈ 0.0004958 (误差从 1.38% 降至 0.14%)
    wire signed [31:0] term_g1 = (int3 >>> 11) + (int3 >>> 17);

    // a3 ≈ 0.046875 (误差保持 0.21%)
    wire signed [31:0] term_a3 = (v_fb >>> 4) - (v_fb >>> 6);

    // c3 ≈ 19.75 (误差保持 0.06%)
    wire signed [31:0] term_c3 = (int3 << 4) + (int3 << 2) - (int3 >>> 2);

    //=======================================================
    // 4. 环路累加逻辑 (CRFB 结构)
    //=======================================================
    wire signed [31:0] sum_int1 = term_a1_din - term_a1_fb;
    wire signed [31:0] sum_int2 = term_c1 - term_a2 - term_g1;
    wire signed [31:0] sum_int3 = term_c2 - term_a3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int1 <= 32'd0; int2 <= 32'd0; int3 <= 32'd0;
        end else begin
            int1 <= int1 + sum_int1;
            int2 <= int2 + sum_int2;
            int3 <= int3 + sum_int3;
        end
    end

   //=======================================================
    // 5. 量化器 (带饱和截断)
    //=======================================================
    wire signed [31:0] quantizer_in = term_c3;
    
    // 【提取整数部分并放大 8 倍】
    wire signed [7:0]  int_part = quantizer_in[28:21];

    assign dout = (int_part > 8'sd7)  ? 4'sd7 :
                  (int_part < -8'sd8) ? -4'sd8 :
                  int_part[3:0];
endmodule