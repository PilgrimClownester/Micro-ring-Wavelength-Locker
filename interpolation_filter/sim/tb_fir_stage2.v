`timescale 1ns/1ps

module tb_fir_stage2;
    reg clk, rst_n;
    reg signed [15:0] data_in;
    wire signed [15:0] data_out;

    // 实例化你生成的 Stage-2 模块
    fir_stage2 uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    // 时钟：为了对应 200kHz 的输出率，时钟周期设为 5000ns (200kHz)
    initial clk = 0;
    always #2500 clk = ~clk; 

    integer fp_in, fp_out, r;
    initial begin
        $dumpfile("wave_s2.vcd");
        $dumpvars(0, tb_fir_stage2);

        rst_n = 0;
        data_in = 0;
        fp_in = $fopen("din_s2_fixed.txt", "r");
        fp_out = $fopen("dout_s2_fixed.txt", "w");
        
        #100 rst_n = 1;

        // 核心逻辑：每 4 个主时钟输入一个有效数据，其余 3 个时钟输入 0
        // 这就是所谓的"插值补零"
        while (!$feof(fp_in)) begin
            // 1. 输入有效数据
            @(posedge clk);
            r = $fscanf(fp_in, "%d\n", data_in);
            $fwrite(fp_out, "%d\n", data_out);
            
            // 2. 插入三个零
            repeat(3) begin
                @(posedge clk);
                data_in = 16'd0;
                $fwrite(fp_out, "%d\n", data_out);
            end
        end

        #1000;
        $fclose(fp_in);
        $fclose(fp_out);
        $finish;
    end
endmodule