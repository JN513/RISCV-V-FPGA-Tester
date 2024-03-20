module Controller_Test #(
    parameter CLOCK_FEQ = 25000000,
    parameter NUM_PAGES = 17,
    parameter MEMORY_FILE = ""
) (
    input wire clk,
    input wire reset,
    input wire uart_full,
    input wire finish_execution,
    output reg option_memory,
    output reg enable_clk,
    output reg reset_core,
    output reg reset_bus,
    output reg uart_write,
    output reg memory_read,
    output reg [7:0] memory_page_number,
    output reg [7:0] uart_data,
    output wire [31:0] address,
    input wire [31:0] read_data
);

localparam TIMEOUT_CLK_CYCLES = 'd360;
localparam DELAY_CYCLES = 'd30;
localparam RESET_CLK_CYCLES = 'd20;

localparam INIT = 4'b0000;
localparam START_CORE = 4'b0001;
localparam RESET_CORE = 4'b0010;
localparam RUN = 4'b0011;
localparam STOP_CORE = 4'b0100;
localparam READ_MEMORY = 4'b0101;
localparam READ_MEMORY_WB = 4'b0110;
localparam CHECK = 4'b0111;
localparam SEND_RESULT = 4'b1000;
localparam DELAY = 4'b1001;
localparam SEND_PAGE_NUMBER = 4'b1010;
localparam UPDATE_PAGE = 4'b1011;
localparam STOP = 4'b1100;


reg result, timeout_n;
reg [3:0] state;
reg [31:0] counter, memory_data;

reg [31:0] reference_memory [NUM_PAGES - 1 : 0];

assign address = 32'd60;

initial begin
    result = 1'b0;
    state = 'd0;
    memory_page_number = 'd0;
    counter = 32'd0;
    uart_write = 1'b0;
    timeout_n = 1'b1;

    if(MEMORY_FILE != "") begin
        $readmemh(MEMORY_FILE, reference_memory, 0, NUM_PAGES - 1);
    end
end

always @(posedge clk ) begin
    uart_write <= 1'b0;

    if (reset == 1'b1) begin
        timeout_n <= 1'b0;
        state <= 'd0;
        result <= 1'b0;
        memory_page_number <= 'd0;
        counter <= 'd0;
        enable_clk <= 1'b0;
        uart_write = 1'b0;
    end else begin
        case (state)
            INIT: begin
                memory_page_number <= 'd0;
                state <= START_CORE;
            end

            START_CORE: begin
                timeout_n <= 1'b1;
                counter <= 'd0;
                option_memory <= 1'b1;
                enable_clk <= 1'b1;
                state <= RESET_CORE;
            end

            RESET_CORE: begin
                if(counter == 'd20) begin
                    state <= RUN;
                    reset_bus <= 1'b0;
                    reset_core <= 1'b0;
                    counter <= 'd0;
                end else begin
                    reset_bus <= 1'b1;
                    reset_core <= 1'b1;
                    counter <= counter + 1'b1;
                end
            end

            RUN: begin
                if(finish_execution == 1'b1) begin
                    state <= STOP_CORE;
                    counter <= 32'd0;
                end else if(counter == TIMEOUT_CLK_CYCLES) begin
                    timeout_n <= 1'b0;
                    state <= STOP_CORE;
                    counter <= 32'd0;
                end else begin
                    counter <= counter + 1;
                end
            end

            STOP_CORE: begin
                option_memory <= 1'b0;
                enable_clk <= 1'b0;
                state <= READ_MEMORY;
            end

            READ_MEMORY: begin
                memory_read <= 1'b1;
                state <= READ_MEMORY_WB;
            end

            READ_MEMORY_WB: begin
                memory_data <= read_data;
                state <= CHECK;
                memory_read <= 1'b0;
            end

            CHECK: begin
                state <= SEND_RESULT;
                result <= (memory_data == reference_memory[memory_page_number]) ? 1'b1 : 1'b0;
            end

            SEND_RESULT: begin
                if(uart_full == 1'b0) begin
                    uart_data <= {1'b0, (result & timeout_n), result, timeout_n, 4'h0};
                    uart_write <= 1'b1;
                    state <= DELAY; 
                end else begin
                   state <= SEND_RESULT; 
                end
            end

            DELAY: begin
                uart_write <= 1'b0;
                if(counter == DELAY_CYCLES) begin
                    state <= SEND_PAGE_NUMBER;
                end else begin
                    counter <= counter + 1'b1;
                end
            end

            SEND_PAGE_NUMBER: begin
                if(uart_full == 1'b0) begin
                    uart_data <= memory_page_number;
                    uart_write <= 1'b1;
                    state <= UPDATE_PAGE; 
                end else begin
                   state <= SEND_PAGE_NUMBER; 
                end
            end

            UPDATE_PAGE: begin
                uart_write <= 1'b0;
                memory_page_number <= memory_page_number + 1'b1;

                if(memory_page_number == NUM_PAGES) begin
                    state <= STOP;
                end else begin
                    state <= START_CORE;
                end
            end

            STOP: begin
                uart_write <= 1'b0;
                state <= STOP;
            end

            default: begin
                state <= INIT;
            end
        endcase
    end
end

endmodule
