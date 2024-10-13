module I2C_TOP
(
	input wire clk,  // main clock
	input wire rst,  // reset


	inout i2c_sda,     //actual sda
	inout wire i2c_scl //actual scl
	);
	
	
	// inputs
	reg [6:0] addr;
	reg [7:0] data_in;
	reg enable;
	reg rw;

	// Outputs
	wire [7:0] data_out;
	wire ready;
	
	reg [7:0] state;
	
	wire nRst;
	wire ready_for_repeated_start;
	wire data_rdy;
	wire write_done;

	assign nRst = ~rst;
	
	localparam IDLE = 0;
	localparam ADDRESS = 1;
	localparam WRITE = 2;
	localparam READ = 3;
	localparam DELAY = 4;
	localparam WAIT_FOR_BUSY = 5;
	localparam WAIT_FOR_READY = 6;
	
	localparam AT24C02N_ADDR = 7'b1010000;
	localparam WRITE_CMD = 1'b0;
	localparam READ_CMD = 1'b1;
	localparam READ_ADDR = 8'h00;
	
	localparam FPGA_CLK_FREQ  = 27_000_000;
	localparam I2C_FREQ 		  = 400_000;
	
	
	reg [8:0] counter = FPGA_CLK_FREQ / I2C_FREQ;

		


	// Instantiate the Unit Under Test (UUT)
	i2c_controller
		#(
     .FPGA_CLK_FREQ(FPGA_CLK_FREQ),  // 27 MHz
     .I2C_FREQ(I2C_FREQ)  // 100 KHz
     )
     master 
     (
		.clk(clk), 
		.rst(0), 
		.addr(addr), 
		.data_in(data_in), 
		.enable(enable), 
		.data_rdy(data_rdy),
		.write_done(write_done),
		.rw(rw),	
		.data_out(data_out), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);
	
	
	always @(posedge clk, negedge rst) begin
	
	if(rst == 0) begin
			state <= IDLE;
			enable <= 1'b0;
		end		
		
	else begin
		case(state)
			
				IDLE: begin
					state <= ADDRESS;
					addr <= AT24C02N_ADDR;
					rw <= WRITE_CMD;
					data_in <= READ_ADDR; // address: 0
					enable <= 1'b1;
					if(write_done == 1'b1) begin
							state <= WAIT_FOR_BUSY;
							rw <= READ_CMD;
					end
					else begin
						state <= IDLE;
					end
				end


				ADDRESS: begin
					state <= DELAY;
				/*
					if(willContinue) begin
					state <= DELAY;
					addr <= AT24C02N_ADDR;
					rw <= READ_CMD;
					end
					*/

				end
				
				
				WRITE: begin

				end
				
				
				READ: begin

				end
				
				
				DELAY : begin
					state <= DELAY;
				
				end
				
				
				WAIT_FOR_BUSY : begin
				
					if(ready == 0) begin
						state <= WAIT_FOR_READY; 

					end
					else begin
						state <= WAIT_FOR_BUSY; 
					end
				end
				
				
				WAIT_FOR_READY : begin
				
					if(ready == 1) begin
						state <= WAIT_FOR_BUSY; 
						
					end
					else begin
						state <= WAIT_FOR_READY; 
					end
				
				
				end


			endcase
	end

	

	
	
	
  end
	
endmodule