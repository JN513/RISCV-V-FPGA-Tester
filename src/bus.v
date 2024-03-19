module BUS (
    // control signal
    input wire clk,
    input wire reset,
    input wire option, // 0 master - 1 core
    input wire [3:0] memory_page_number,
    output reg finish,

    // master connection
    input wire read,
    input wire write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data,

    // core connection
    input wire core_read,
    input wire core_write,
    input wire [31:0] core_address,
    input wire [31:0] core_write_data,
    output wire [31:0] core_read_data,

    // memory connection
    output wire memory_read,
    output wire memory_write,
    input wire [31:0] memory_read_data,
    output wire [31:0] memory_address,
    output wire [31:0] memory_write_data
);

assign memory_address = (option == 1'b1) ? {22'h000000, memory_page_number, core_address[5:0]}: {22'h000000, memory_page_number, address[5:0]};
assign memory_read = (option == 1'b1) ? core_read : read ;
assign memory_write = (option == 1'b1) ? core_write : write ;
assign memory_write_data = (option == 1'b1) ? core_write_data : write_data ;
assign read_data = memory_read_data;
assign core_read_data = memory_read_data;

always @(posedge clk ) begin
    if(reset == 1'b1) begin
        finish <= 1'b0;
    end else begin
        if(core_address[5:0] == 'd60) begin
            finish <= 1'b1;
        end
    end
end

endmodule
