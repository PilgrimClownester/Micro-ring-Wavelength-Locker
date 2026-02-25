// ===========================================================
// 128x 插值链顶层级联模块
// 输入: 25kHz, 输出: 3.2MHz
// 架构: Stage1(2x FIR) -> Stage2(4x FIR) -> Stage3(16x Repeat)
// ===========================================================

module interpolation_top (
    input  wire                   clk,      // 3.2MHz 主时钟
    input  wire                   rst_n,
    input  wire signed [15:0]    data_in,  // 来自外部的 25kHz 原始采样
    output wire signed [15:0]    data_out  // 最终 3.2MHz 输出
);

    // --- 1. 计数器生成各种采样时刻 (0-127 循环) ---
    reg [6:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 7'd0;
        else cnt <= cnt + 7'd1;
    end

    // 使能信号定义
    wire en_50k  = (cnt[5:0] == 6'd0);   // 每 64 个 clk 跳一次 (Stage-1 计算时刻)
    wire en_200k = (cnt[3:0] == 4'd0);   // 每 16 个 clk 跳一次 (Stage-2 计算时刻)

    // --- 2. Stage-1 (2x FIR) 补零逻辑 ---
    // 输入 25kHz -> 输出 50kHz. 
    // 在 50kHz 的节拍下：第1次喂 data_in，第2次喂 0.
    reg signed [15:0] s1_input;
    always @(*) begin
        if (cnt == 7'd0)      s1_input = data_in; // 有效采样时刻
        else if (cnt == 7'd64) s1_input = 16'd0;   // 插零时刻
        else                   s1_input = 16'd0;
    end

    wire signed [15:0] s1_out;
    fir_stage1 u_stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_50k),
        .data_in(s1_input),
        .data_out(s1_out)
    );

    // --- 3. Stage-2 (4x FIR) 补零逻辑 ---
    // 输入 50kHz -> 输出 200kHz.
    // 在 200kHz 的节拍下：第1次喂 s1_out，后3次喂 0.
    reg signed [15:0] s2_input;
    always @(*) begin
        // Stage-1 输出只在 cnt=0 和 cnt=64 更新
        if (cnt == 7'd0 || cnt == 7'd64) 
            s2_input = s1_out;
        else if (cnt[3:0] == 4'd0)       
            s2_input = 16'd0; // 其余 200kHz 节拍补零
        else                             
            s2_input = 16'd0;
    end

    wire signed [15:0] s2_out;
    fir_stage2 u_stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(en_200k),
        .data_in(s2_input),
        .data_out(s2_out)
    );

    // --- 4. Stage-3 (16x Repeat) 采样保持 ---
    // 输入 200kHz -> 输出 3.2MHz.
    // 每一个 200kHz 产生的值重复输出 16 次
    reg signed [15:0] s3_hold;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) s3_hold <= 16'd0;
        else if (en_200k) s3_hold <= s2_out; // 保持 Stage-2 算完的结果
    end

    assign data_out = s3_hold;

endmodule