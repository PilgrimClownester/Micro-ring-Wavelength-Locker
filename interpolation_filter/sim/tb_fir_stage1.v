`timescale 1ns/1ps

module tb_fir_stage1;
    reg clk, rst_n;
    reg signed [15:0] data_in;
    wire signed [15:0] data_out;

    fir_stage1 uut (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in), .data_out(data_out)
    );

    initial clk = 0;
    always #10000 clk = ~clk;

    integer fp_in, fp_out, r;
    initial begin
        // --- GTKWave 必须的 Dump 语句 ---
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fir_stage1);

        rst_n = 0; data_in = 0;
        fp_in = $fopen("din_fixed.txt", "r");
        fp_out = $fopen("dout_fixed.txt", "w");
        
        #100 rst_n = 1;
        while (!$feof(fp_in)) begin
            @(posedge clk);
            r = $fscanf(fp_in, "%d\n", data_in);
            $fwrite(fp_out, "%d\n", data_out);
        end
        #1000;
        $fclose(fp_in); $fclose(fp_out);
        $finish; // 结束仿真
    end
endmodule