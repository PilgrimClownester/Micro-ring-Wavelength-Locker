`timescale 1ns / 1ps

module tb_sdm_behav;

    parameter CLK_PERIOD = 312.5; 
    real PI = 3.1415926535897932;
    real FREQ_SIG = 10000;    
    real AMP      = 0.7;        
    real SCALE_FACTOR = 16777216.0;

    reg clk;
    reg rst_n;
    reg signed [31:0] din;
    wire signed [3:0] dout; // SDM输出
    
    // --- 新增：滤波器输出信号 ---
    wire signed [31:0] filter_out;
    wire               filter_valid;

    integer file_handle;
    real time_stamp;
    real sin_val;
    integer i;

    // 1. 实例化 SDM 调制器
    sdm_cifb_3rd_4bit u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout)
    );

    // 2. 实例化 CIC 滤波器 (接在 SDM 后面)
    cic_decimator_4th u_filter (
        .clk(clk),
        .rst_n(rst_n),
        .din(dout),          // 输入是 SDM 的输出
        .dout(filter_out),   // 得到滤波后的高精度信号
        .out_valid(filter_valid)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 0;
        din = 0;
        time_stamp = 0;
        file_handle = $fopen("sdm_output_data.txt", "w");
        
        #1000;
        rst_n = 1;
        
        $display("Simulation Started...");

        // 为了看到滤波器稳定的效果，我们多跑一点点，跑 16384 个点
        for (i = 0; i < 16384; i = i + 1) begin
            @(posedge clk); 
            sin_val = AMP * $sin(2.0 * PI * FREQ_SIG * time_stamp);
            din = $rtoi(sin_val * SCALE_FACTOR);
            time_stamp = time_stamp + (1.0 / 3200000.0);
            
            #1; 
            $fdisplay(file_handle, "%d", dout);
        end

        $display("Simulation Finished.");
        $fclose(file_handle);
        $finish;
    end

endmodule