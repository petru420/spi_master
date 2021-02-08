`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2021 14:48:05
// Design Name: 
// Module Name: SPI_master_cs
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


module SPI_master_cs
    #(  parameter SPI_MODE              = 0,
        parameter CLKS_PER_HALF_BIT     = 2,
        parameter MAX_BYTES_PER_CS      = 2,
        parameter CS_INACTIVE_CLKS      = 10
    )
    (
        input   i_Rst_L,
        input   i_Clk,
        
        //input [1:0] i_TX_Count,
        input  [$clog2(MAX_BYTES_PER_CS+1)-1:0]  i_TX_Count,
        input  [7:0]     i_TX_Byte,
        input   i_TX_DV,
        output  o_TX_Ready,
    
        //output reg [1:0] o_RX_Count,
        output reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_RX_Count,
        output o_RX_DV,
        output [7:0]    o_RX_Byte,
        
        output  o_SPI_Clk,
        input   i_SPI_MISO,
        output  o_SPI_MOSI,
        output  o_SPI_CS_n
     );
     
localparam IDLE         = 2'b00; //FSM states names
localparam TRANSFER     = 2'b01;
localparam CS_INACTIVE  = 2'b10;

reg [1:0] r_SM_CS;
reg r_CS_n;
//reg r_CS_Inactive_Count;
reg [$clog2(CS_INACTIVE_CLKS)-1:0] r_CS_Inactive_Count;
//reg r_TX_Count;
reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] r_TX_Count;
wire w_Master_Ready; 

spi_master
      #(.SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)) 
        SPI_Master_Inst    
       
       (.i_Rst_L(i_Rst_L),
        .i_Clk(i_Clk),
        
        .i_TX_Byte(i_TX_Byte),
        .i_TX_DV(i_TX_DV),
        .o_TX_Ready(w_Master_Ready),
        
        .o_RX_DV(o_RX_DV),
        .o_RX_Byte(o_RX_Byte),
        
        .o_SPI_Clk(o_SPI_Clk),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_MOSI(o_SPI_MOSI)
        );
        
always @(posedge i_Clk or negedge i_Rst_L)
    begin
        if (~i_Rst_L) //initial state
            begin
                r_SM_CS                 <= IDLE;
                r_CS_n                  <= 1'b1;
                r_TX_Count              <= 0;
                r_CS_Inactive_Count     <= CS_INACTIVE_CLKS;
            end
        else
            begin
                case (r_SM_CS)
                IDLE:
                    begin
                        if (r_CS_n & i_TX_DV)
                            begin 
                                r_TX_Count  <= i_TX_Count -1;
                                r_CS_n      <= 1'b0;
                                r_SM_CS     <= TRANSFER;
                            end
                    end
                
                TRANSFER:
                    begin
                        if (w_Master_Ready)
                            begin
                                if (r_TX_Count > 0)
                                    begin
                                        if (i_TX_DV)
                                            begin
                                                r_TX_Count <= r_TX_Count -1;
                                            end
                                    end
                                else
                                    begin
                                        r_CS_n  <= 1'b1;
                                        r_CS_Inactive_Count <= CS_INACTIVE_CLKS;
                                        r_SM_CS <= CS_INACTIVE;
                                    end
                            end
                    end                                            
            
                CS_INACTIVE:
                    begin
                        if (r_CS_Inactive_Count > 0)
                            begin
                                r_CS_Inactive_Count <= r_CS_Inactive_Count - 1'b1;
                            end
                        else
                            begin
                                r_SM_CS <= IDLE;
                            end
                    end
                                
                default:
                    begin
                        r_CS_n  <= 1'b1;
                        r_SM_CS <= IDLE;
                    end
                endcase
            end 
    end
       
always @(posedge i_Clk)
    begin
        if (r_CS_n)
            begin
                o_RX_Count <= 0;
            end
        else if (o_RX_DV)
            begin
                o_RX_Count <= o_RX_Count + 1'b1;
            end
    end                             
 
 assign o_SPI_CS_n = r_CS_n;
 
 assign o_TX_Ready = ((r_SM_CS == IDLE) | (r_SM_CS == TRANSFER && w_Master_Ready == 1'b1 && r_TX_Count >0))&~i_TX_DV;      
     
endmodule
