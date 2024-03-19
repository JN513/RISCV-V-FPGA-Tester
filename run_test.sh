#!/bin/zsh

iverilog -o build/tb_tester -s tb_tester testbenchs/tester_testbench.v src/bus.v src/controller.v src/fifo.v src/main.v src/memory.v src/reset.v src/uart.v src/uart_rx.v src/uart_tx.v Risco-5/src/core/alu.v Risco-5/src/core/alu_control.v Risco-5/src/core/control_unit.v Risco-5/src/core/core.v Risco-5/src/core/csr_unit.v Risco-5/src/core/immediate_generator.v Risco-5/src/core/mux.v Risco-5/src/core/pc.v Risco-5/src/core/registers.v
vvp build/tb_tester