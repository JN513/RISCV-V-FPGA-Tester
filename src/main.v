module top (
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx,
    output wire [7:0]led
);

reg led_1;

initial begin
    led_1 = 1'b0;
end

assign led[0] = ~led_1;

wire reset_o, option_memory, uart_full, finish_execution,
    enable_clk, core_clk, reset_core, reset_bus, uart_write;
wire [1:0] memory_option, core_memory_option;
wire [3:0] memory_page_number;
wire [7:0] uart_data;

wire memory_read, memory_write, core_read, core_write,
    master_read, master_write;
wire [1:0] option;
wire [31:0] memory_address, memory_write_data, memory_read_data,
    core_address, core_write_data, core_read_data,
    master_address, master_write_data, master_read_data;

assign core_clk = (enable_clk == 1'b1) ? clk : 1'b0;
assign memory_option = (enable_clk == 1'b1) ? core_memory_option : 2'b10;

ResetBootSystem #(
    .CYCLES(20)
) ResetBootSystem(
    .clk(clk),
    .reset_o(reset_o)
);

Controller_Test #(
    .CLOCK_FEQ(25000000),
    .NUM_PAGES(13),
    .MEMORY_FILE("src/reference.hex")
) Controller_Test (
    .clk(clk),
    .reset(reset_o),
    .uart_full(uart_full),
    .finish_execution(finish_execution),
    .option_memory(option_memory),
    .enable_clk(enable_clk),
    .reset_core(reset_core),
    .reset_bus(reset_bus),
    .uart_write(uart_write),
    .memory_read(master_read),
    .memory_page_number(memory_page_number),
    .uart_data(uart_data),
    .address(master_address),
    .read_data(master_read_data)
);

Memory #(
    .MEMORY_FILE("src/memory.hex"),
    .MEMORY_SIZE(4096)
) Memory(
    .clk(clk),
    .reset(reset_o),
    .option(memory_option),
    .memory_read(memory_read),
    .memory_write(memory_write),
    .write_data(memory_write_data),
    .read_data(memory_read_data),
    .address(memory_address)
);

BUS Bus(
    .clk(clk),
    .reset(reset_bus),
    .option(option_memory),
    .memory_page_number(memory_page_number),
    .finish(finish_execution),

    .read(master_read),
    .write(master_write),
    .address(master_address),
    .write_data(master_write_data),
    .read_data(master_read_data),

    .core_read(core_read),
    .core_write(core_write),
    .core_address(core_address),
    .core_write_data(core_write_data),
    .core_read_data(core_read_data),

    .memory_read(memory_read),
    .memory_write(memory_write),
    .memory_read_data(memory_read_data),
    .memory_address(memory_address),
    .memory_write_data(memory_write_data)
);

UART Uart (
    .clk(clk),
    .reset(reset_o),
    .rx(rx),
    .tx(tx),
    .read(),
    .write(uart_write),
    .tx_fifo_full(uart_full),
    .rx_fifo_full(),
    .tx_fifo_empty(),
    .rx_fifo_empty(),
    .write_data(uart_data),
    .read_data()
);

Core #(
    .BOOT_ADDRESS(32'h00000000)
) Core(
    .clk(core_clk),
    .reset(reset_core),
    .option(core_memory_option),
    .memory_read(core_read),
    .memory_write(core_write),
    .write_data(core_write_data),
    .read_data(core_read_data),
    .address(core_address)
);


always @(posedge clk ) begin
    if(finish_execution == 1'b1) begin
        led_1 <= 1'b1;
    end
end

endmodule
