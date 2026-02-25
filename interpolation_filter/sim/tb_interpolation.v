`timescale 1ns/1ps

module tb_interpolation;
    reg clk, rst_n;
    reg signed [15:0] data_in;
    wire signed [15:0] data_out;

    interpolation_top uut (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in), .data_out(data_out)
    );

    // 3.2MHz 主时钟 (周期约为 312.5ns)
    initial clk = 0;
    always #156.25 clk = ~clk; 

    integer fp_in, fp_out, r, cnt;
    initial begin
        $dumpfile("wave_top.vcd");
        $dumpvars(0, tb_interpolation);

        rst_n = 0; data_in = 0; cnt = 0;
        fp_in = $fopen("din_fixed.txt", "r"); // 使用 25kHz 的原始测试向量
        fp_out = $fopen("dout_final.txt", "w");
        
        #1000 rst_n = 1;

        while (!$feof(fp_in)) begin
            @(posedge clk);
            // 只有在 25kHz 周期（128个 clk）开始时，才读取下一个输入点
            if (cnt == 0) begin
                r = $fscanf(fp_in, "%d\n", data_in);
            end
            
            $fwrite(fp_out, "%d\n", data_out);
            
            if (cnt == 127) cnt = 0;
            else cnt = cnt + 1;
        end

        $fclose(fp_in); $fclose(fp_out);
        $finish;
    end
endmodule