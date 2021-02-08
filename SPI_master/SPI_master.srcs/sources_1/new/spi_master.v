`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2021 18:32:24
// Design Name: 
// Module Name: spi_master
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


module spi_master
    #(parameter SPI_MODE = 0, 
      parameter CLKS_PER_HALF_BIT = 2)
      (
            //RST & CLK 
        input i_Rst_L,
        input i_Clk,
            //MOSI signals
        input [7:0] i_TX_Byte,
        input       i_TX_DV,
        output reg  o_TX_Ready,
            //MISO signals
        output reg  o_RX_DV,
        output reg [7:0] o_RX_Byte,
            //Interface signals
        output reg  o_SPI_Clk,
        input       i_SPI_MISO,
        output reg  o_SPI_MOSI
    );
    
    //
    wire w_CPOL;
    wire w_CPHA;
    
    reg [$clog2(CLKS_PER_HALF_BIT*2)-1:0] r_SPI_Clk_Count; //[2:0] by tb
    reg r_SPI_Clk;
    reg [4:0] r_SPI_Clk_Edges;
    reg r_Leading_Edge;
    reg r_Trailing_Edge;
    reg r_TX_DV;
    reg [7:0] r_TX_Byte;
    
    reg [2:0] r_RX_Bit_Count;
    reg [2:0] r_TX_Bit_Count;    
    assign w_CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);
    
    assign w_CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);
    
always @(posedge i_Clk or negedge i_Rst_L) // generates internal r_SPI_Clk, Leading&Trailing edge internal registers, o_TX_Ready reg
    begin
        if (~i_Rst_L)
            begin
                   o_TX_Ready       <= 1'b0;
                   r_SPI_Clk_Edges  <= 0;
                   r_Leading_Edge   <= 1'b0;
                   r_Trailing_Edge  <= 1'b0;
                   r_SPI_Clk        <= w_CPOL;
                   r_SPI_Clk_Count  <= 0;
            end
        else
            begin  
                   r_Leading_Edge   <= 1'b0;
                   r_Trailing_Edge  <= 1'b0;
                   
                   if (i_TX_DV)
                        begin 
                            o_TX_Ready <= 1'b0;
                            r_SPI_Clk_Edges <= 16;
                        end
                   else if (r_SPI_Clk_Edges >0)
                        begin
                            o_TX_Ready <= 1'b0;
                            if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT*2-1) //tb==7
                                begin
                                    r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                                    r_Trailing_Edge <= 1'b1;
                                    r_SPI_Clk_Count <= 0; 
                                    r_SPI_Clk       <= ~r_SPI_Clk;
                                end 
                            else if (r_SPI_Clk_Count == CLKS_PER_HALF_BIT - 1) //tb==3
                                begin
                                    r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
                                    r_Leading_Edge  <= 1'b1;
                                    r_SPI_Clk_Count <= r_SPI_Clk_Count +1;
                                    r_SPI_Clk       <= ~r_SPI_Clk;
                                end 
                            else
                                begin
                                    r_SPI_Clk_Count <= r_SPI_Clk_Count + 1; //
                                end 
                        end          
                   else
                        begin
                            o_TX_Ready <= 1'b1;
                        end
                    
            end    
    end
    
always @(posedge i_Clk or negedge i_Rst_L) //reads byte from i_TX_Byte to internal register
    begin
        if (~i_Rst_L)
            begin
                r_TX_Byte   <= 8'b0000_0000;
                r_TX_DV     <= 1'b0;
            end 
        else 
            begin
                r_TX_DV <= i_TX_DV;
                if (i_TX_DV)
                    begin
                        r_TX_Byte <= i_TX_Byte;
                    end
            end
    end
    
always @(posedge i_Clk or negedge i_Rst_L) //sending byte from r_TX_Byte to MOSI
    begin
        if (~i_Rst_L)
            begin
                o_SPI_MOSI <= 1'b0; //initial state
                r_TX_Bit_Count <= 3'b111;
            end 
        else
            begin
                if (o_TX_Ready)
                    begin 
                        r_TX_Bit_Count <= 3'b111;
                    end 
                else if (r_TX_DV & ~w_CPHA)
                    begin 
                        o_SPI_MOSI <= r_TX_Byte[3'b111]; //sending MSB
                        r_TX_Bit_Count <= 3'b110;
                    end 
                else if ((r_Leading_Edge & w_CPHA) | (r_Trailing_Edge & ~w_CPHA))
                    begin
                        r_TX_Bit_Count  <= r_TX_Bit_Count -1;
                        o_SPI_MOSI      <= r_TX_Byte[r_TX_Bit_Count]; //sending other bits
                    end 
            end 
    end 
        
always @(posedge i_Clk or negedge i_Rst_L) //read byte from MISO to RX_Byte
    begin
        if (~i_Rst_L)
            begin
                o_RX_Byte       <=  8'b0000_0000;
                o_RX_DV         <=  1'b0;
                r_RX_Bit_Count  <=  3'b111;
            end 
        else 
            begin
                o_RX_DV <= 1'b0;
                if (o_TX_Ready)
                    begin 
                        r_TX_Bit_Count <= 3'b111;
                    end 
                else if ((r_Leading_Edge & ~w_CPHA) | (r_Trailing_Edge & w_CPHA))
                    begin
                        o_RX_Byte[r_RX_Bit_Count]   <= i_SPI_MISO; //reading bits from MISO
                        r_RX_Bit_Count              <= r_RX_Bit_Count -1;
                        if (r_RX_Bit_Count == 3'b000)
                            begin
                                o_RX_DV <= 1'b1;
                            end 
                    end 
             end 
      end 
                    
always @(posedge i_Clk or negedge i_Rst_L) //releases SPI_CLK to output
    begin
        if (~i_Rst_L)
            begin
                o_SPI_Clk <= w_CPOL;
            end
        else
            begin
                o_SPI_Clk <= r_SPI_Clk;
            end
     end                         
            
endmodule
