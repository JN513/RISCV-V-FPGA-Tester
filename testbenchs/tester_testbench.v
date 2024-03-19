module tb_tester();

reg clk, reset;
wire rx, tx;
wire [7:0] led;

always #1 clk = ~clk;

top top(
    .clk(clk),
    .rx(rx),
    .tx(tx),
    .reset(reset),
    .led(led)
);

initial begin
    $dumpfile("build/tester.vcd");
    $dumpvars;

    clk = 1'b0;

    #1200

    $finish;
end

endmodule
