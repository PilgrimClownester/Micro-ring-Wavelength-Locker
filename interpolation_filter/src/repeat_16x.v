module repeat_16x (
    input  wire                   clk,      // 3.2MHz 主时钟
    input  wire                   rst_n,
    input  wire signed [15:0]    din,      // 来自 Stage-2 的 200kHz 数据
    input  wire                   en_200k,  // 每 16 个主时钟跳一次的高电平使能
    output reg  signed [15:0]    dout      // 最终 3.2MHz 输出
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) dout <= 16'd0;
        else if (en_200k) dout <= din; // 只有 200kHz 采样时刻更新，其余时刻保持
    end
endmodule