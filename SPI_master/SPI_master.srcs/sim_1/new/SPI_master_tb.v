`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2021 12:56:08
// Design Name: 
// Module Name: SPI_master_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//`include "SPI_master.v"

module SPI_master_tb();
    parameter SPI_MODE = 3;
    parameter CLKS_PER_HALF_BIT = 4;
    parameter MAIN_CLK_DELAY    = 2;
    parameter MAX_BYTES_PER_CS  = 2;
    parameter CS_INACTIVE_CLKS  = 10;
    
    reg r_Rst_L     = 1'b0;
    wire w_SPI_Clk;
    reg r_SPI_En    = 1'b0;
    reg r_Clk       = 1'b0;
    wire w_SPI_CS_n;
    wire w_SPI_MOSI;
    wire w_SPI_MISO;
    
    reg [7:0] r_Master_TX_Byte  = 0;
    reg r_Master_TX_DV          = 1'b0;
    wire w_Master_TX_Ready;
    wire w_Master_RX_DV;
    wire [7:0] w_Master_RX_Byte;
    //wire w_Master_RX_Count; 
    wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count; 
    reg [1:0] r_Master_TX_Count = 2'b10;
    
always #(MAIN_CLK_DELAY) r_Clk = ~r_Clk;
    
SPI_master_cs #(.SPI_MODE(SPI_MODE),
                .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
                .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
                .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
                )DUT
                
               (.i_Rst_L(r_Rst_L),
                .i_Clk(r_Clk),
                
                .i_TX_Count(r_Master_TX_Count), //?
                .i_TX_Byte(r_Master_TX_Byte),
                .i_TX_DV(r_Master_TX_DV),
                .o_TX_Ready(w_Master_TX_Ready),
                
                .o_RX_Count(w_Master_RX_Count),
                .o_RX_DV(w_Master_RX_DV),
                .o_RX_Byte(w_Master_RX_Byte),
                
                .o_SPI_Clk(w_SPI_Clk),
                .i_SPI_MISO(w_SPI_MISO),
                .o_SPI_MOSI(w_SPI_MOSI),
                .o_SPI_CS_n(w_SPI_CS_n)
                );
                
task SendSingleByte(input [7:0] data);
        begin
        @(posedge r_Clk);
            begin
                r_Master_TX_Byte    <= data;
                r_Master_TX_DV      <= 1'b1;
            end
        @(posedge r_Clk);
            begin r_Master_TX_DV    <=  1'b0;
            end
        @(posedge r_Clk); //?
        @(posedge w_Master_TX_Ready); //?
    end
endtask

initial
    begin
        repeat(10)@(posedge r_Clk);
            r_Rst_L = 1'b0;
        repeat(10)@(posedge r_Clk);
            r_Rst_L = 1'b1;
        
        SendSingleByte(8'hF3);
        $display ("Sent out 0xC1, Received 0x%X", w_Master_RX_Byte);
        SendSingleByte(8'hC2);
        $display ("Sent out 0xC2, Received 0x%X", w_Master_RX_Byte);
        
        repeat(100)@(posedge r_Clk);
        $finish();
     end     
     
endmodule