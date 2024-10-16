`timescale 1ns / 1ps

//`define DEBUG

module i2c_controller
#( 
    parameter FPGA_CLK_FREQ = 27_000_000,   // Default 27 MHz FPGA clock
    parameter I2C_FREQ = 100_000           // Default 100 kHz I2C frequency
)
(
	input wire clk,
	input wire rst,
	input wire [6:0] addr,
	input wire [7:0] data_in,
	input wire enable,
	input wire rw,
	input wire debug_ack,

	output reg [7:0] data_out,
	output wire ready,
	output reg data_rdy,
	output reg write_done,

	inout i2c_sda,
	inout wire i2c_scl
	);

	localparam IDLE = 0;
	localparam START = 1;
	localparam ADDRESS = 2;
	localparam READ_ACK = 3;
	localparam WRITE_DATA = 4;
	localparam WRITE_ACK = 5;
	localparam READ_DATA = 6;
	localparam READ_ACK2 = 7;
	localparam STOP = 8;
	
	
	`ifdef DEBUG
			// Behavior for simulation
			localparam DIVIDE_BY = 10;
	`else
			// Behavior for synthesis
			localparam DIVIDE_BY = FPGA_CLK_FREQ / I2C_FREQ;
	`endif
				

	reg [7:0] state;
	reg [7:0] saved_addr;
	reg [7:0] saved_data;
	reg [7:0] counter;
	reg [7:0] counter2 = 0;
	reg [7:0] clk_count = 0; 
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable = 0;
	reg i2c_clk = 1'b0;
	reg is_ack = 1'b0;
	
	reg clk_en_rise = 1'b0;
	reg clk_en_fall = 1'b0;
	
	assign ready = ((rst == 0) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1'bz : ~i2c_clk; // if debug: 1'b1, if release: 1'bz
	assign i2c_sda = (write_enable == 1) ? sda_out : 1'bz; // if debug: 1'b1, if release: 1'bz
	
	/* Clock generation unit */
always @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_en_rise <= 1'b0;
        clk_en_fall <= 1'b0;
        i2c_clk <= 1'b0;
        clk_count <= 9'b0;
    end else begin
        // Clock enable for rising edge of i2c clock
        if (clk_count == 9'd0) begin
            clk_en_rise <= 1'b1;
        end else begin
            clk_en_rise <= 1'b0;
        end
				
				
				if (clk_count == 9'd1) begin
            i2c_clk <= ~i2c_clk;
        end
				
				
        
        // Clock enable for rising edge of i2c clock
        if (clk_count == (DIVIDE_BY/2) ) begin
            clk_en_fall <= 1'b1;
        end else begin
            clk_en_fall <= 1'b0;
        end
				
				if (clk_count == (DIVIDE_BY/2) +1) begin
            i2c_clk <= ~i2c_clk;
        end
        
         
        if (clk_count == (DIVIDE_BY - 1)) begin
                clk_count <= 9'b0;
                
        end
        else begin
            clk_count <= clk_count + 1;  
         end
    end
end


	always @(posedge clk, posedge rst) begin
		if(rst == 1) begin
			state <= IDLE;
			i2c_scl_enable <= 0;
			write_enable <= 0;
			data_rdy <= 1'b0;
			write_done <= 1'b0;
		end		
		else begin
			if(clk_en_rise) begin
			data_rdy <= 1'b0;
			write_done <= 1'b0;
			case(state)
			
				IDLE: begin
					i2c_scl_enable <= 1'b0; // let the scl to be high
					if (enable) begin
						state <= START;
						saved_addr <= {addr, rw};
						saved_data <= data_in;
					end
					else begin
						state <= IDLE;
						sda_out <= 1'bz; // 1'b1 if debug, else 1'bz
						write_enable <= 1'b0;
					end
				end

				START: begin
					write_enable <= 1'b1;
					sda_out <= 1'b0;		
					state <= ADDRESS;
					counter <= 8;
				end

				ADDRESS: begin
					i2c_scl_enable <= 1'b1;  // enable clock generation
					if (counter == 0) begin 
						state <= READ_ACK;
						counter <= 8;
						write_enable <= 1'b0;   // disable write enable
						//sda_out <= saved_addr[counter -1];
						end 
					else begin 
						counter <= counter - 1;
						sda_out <= saved_addr[counter -1];
						end						
				end

				READ_ACK: begin
				`ifdef DEBUG
					if (is_ack == 0 || debug_ack) begin // ack is read
				 `else
					if (is_ack == 1) begin // ack is read
				 `endif
																		
						if(saved_addr[0] == 0) begin 
							write_enable <= 1'b1;
							sda_out <= saved_data[counter -1];
							counter <= counter - 1;							
							state <= WRITE_DATA;
						end
						else begin 
							counter <= 8 -1;
							state <= READ_DATA;
						end 
					end 
						else state <= STOP;					// nack is read, stop the communication
				end

				WRITE_DATA: begin
					if(counter == 0) begin
						state <= READ_ACK2;
						write_enable <= 0;  // write disable in order to read ack
						counter <= 7;
						write_done <= 1'b1;
						end 
					else begin
						counter <= counter - 1;
						sda_out <= saved_data[counter -1];
						end
				end
				
				READ_ACK2: begin
					saved_data <= data_in;
				 `ifdef DEBUG
					if ( (is_ack == 1 || debug_ack) && (enable == 1) && rw == 1 ) begin // ack is read
				 `else
					if ( (is_ack == 1) && (enable == 1) && rw == 1 ) begin 
				 `endif
				 
						state <= IDLE;  // ack is read
						sda_out <= 1'b1;
						write_enable <= 1;  // write enable in order to write ack
						end
					`ifdef DEBUG
					else if ( (is_ack == 1 || debug_ack) && (enable == 1) && rw == 0 ) begin 
					`else
					else if ( (is_ack == 1) && (enable == 1) && rw == 0 ) begin 
					`endif
						state <= WRITE_DATA;  // ack is read
						sda_out <= saved_data[counter];
						write_enable <= 1;  // write enable in order to write ack
					
					end
					else begin 
						state <= STOP;			// nack is read
						write_enable <= 1;  // write enable in order to read ack
						
						end
				end

				READ_DATA: begin
					if (counter == 0) begin
						data_rdy <= 1'b1;
						state <= WRITE_ACK;
						write_enable <= 1;  // write enable in order to write ack
						if(enable == 1 ) // continue , generate NACK
							sda_out <= 0;
						else 
							sda_out <= 1;    // break, continue , generate ACK 
						end
					else counter <= counter - 1;
				end
				
				WRITE_ACK: begin
					sda_out <= 0;
					
					if(enable == 1 && rw == 1) begin // continue , generate NACK 
						state <= READ_DATA;
						write_enable <= 0;
						counter <= 8 -1;
					end
					else if (enable == 0) begin
						state <= STOP;    // break, continue , generate ACK 
						write_enable <= 1;
					end		
				end

				STOP: begin
					i2c_scl_enable <= 1'b0; // let the scl to be high
					sda_out <= 1'b1;
					state <= IDLE;
				end
				
			endcase
		end
	end
end
	
	always @(posedge clk) begin

	if(clk_en_fall) begin
			case(state)
				
				ADDRESS: begin
					
				end
				
				WRITE_DATA: begin 
					
				end
				
				READ_DATA: begin
					data_out[counter] <= i2c_sda;
				end
				
				READ_ACK: begin
					if (i2c_sda == 0) 
						is_ack <= 1;
					else
						is_ack <= 0;
					
				end
				
				
				

				READ_ACK2: begin
					if (i2c_sda == 0) 
						is_ack <= 1;
					else
						is_ack <= 0;
					
				end
				
				STOP: begin

					
				end
			endcase
		end

end
endmodule