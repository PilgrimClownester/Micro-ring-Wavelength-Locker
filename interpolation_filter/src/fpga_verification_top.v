// ===========================================================
// 项目名称：128倍插值滤波器 FPGA 硬件验证顶层
// 针对芯片：Zynq-7020 (XC7Z020)
// 验证工具：DDS Compiler (信号源) + ILA (实时波形观测)
// 时钟策略：32MHz 原生时钟 -> 逻辑分频 3.2MHz 主时钟
// ===========================================================

module fpga_top (
    input  wire        sys_clk,    // 板载时钟 (通常为 50MHz 或 125MHz)
    input  wire        sys_rst_n   // 板载复位按键
);

    // -------------------------------------------------------
    // 1. 时钟管理 (Clocking Wizard)
    // -------------------------------------------------------
    wire clk_32M;    // 硬件生成的 32MHz
    wire locked;     // 时钟稳定标志
    
    // 调用 Clocking Wizard IP
    // Input: sys_clk, Output1: 32.0MHz
    clk_wiz_0 u_clk_wiz (
        .clk_in1  (sys_clk),
        .clk_out1 (clk_32M),
        .resetn   (sys_rst_n),
        .locked   (locked)
    );

    // -------------------------------------------------------
    // 2. 逻辑分频：32MHz -> 3.2MHz
    // -------------------------------------------------------
    reg [3:0] div_cnt;
    reg       clk_3_2M;

    always @(posedge clk_32M or negedge locked) begin
        if (!locked) begin
            div_cnt  <= 4'd0;
            clk_3_2M <= 1'b0;
        end else begin
            if (div_cnt == 4'd4) begin // 10分频计数
                div_cnt  <= 4'd0;
                clk_3_2M <= ~clk_3_2M;
            end else begin
                div_cnt  <= div_cnt + 4'd1;
            end
        end
    end

    // -------------------------------------------------------
    // 3. DDS 信号源 (产生 25kHz 测试正弦波)
    // -------------------------------------------------------
    wire [15:0] dds_tdata;
    wire        dds_tvalid;

    // DDS 配置提醒：
    // SFDR: 96dB, System Clock: 3.2MHz, Frequency: 0.025MHz
    dds_compiler_0 u_dds_source (
        .aclk                (clk_3_2M), 
        .m_axis_data_tvalid  (dds_tvalid),
        .m_axis_data_tdata   (dds_tdata) 
    );
    // -------------------------------------------------------
    // 4. 插值滤波器顶层级联 (你的核心设计)
    // -------------------------------------------------------
    wire signed [15:0] filter_in;
    wire signed [15:0] filter_out;
    
    // 输入数据直接来自 DDS
    assign filter_in = dds_tdata;

    // 实例化你之前的 interpolation_top.v
    interpolation_top u_interp_filter (
        .clk      (clk_3_2M), // 使用分频后的 3.2MHz
        .rst_n    (locked),
        .data_in  (filter_in),
        .data_out (filter_out)
    );

    // -------------------------------------------------------
    // 5. ILA 在线逻辑分析仪 (用于上板抓信号)
    // -------------------------------------------------------
    // ILA 配置提醒：
    // Probe 0: 位宽 16 (观测输入)
    // Probe 1: 位宽 16 (观测输出)
    ila_0 u_ila_debug (
        .clk    (clk_3_2M), // 采样时钟必须与数据同步
        .probe0 (filter_in),
        .probe1 (filter_out)
    );

endmodule