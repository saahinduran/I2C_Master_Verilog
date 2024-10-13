`timescale 1ns / 1ps

module i2c_controller_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [6:0] addr;
	reg [7:0] data_in;
	reg enable;
	reg rw;

	// Outputs
	wire [7:0] data_out;
	wire ready;
	reg debug_ack;
	wire data_rdy;
	wire write_done;

	// Bidirs
	wire i2c_sda;
	wire i2c_scl;

	// Instantiate the Unit Under Test (UUT)
	i2c_controller master (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.data_in(data_in), 
		.enable(enable), 
		.rw(rw),
		.data_rdy(data_rdy),
		.write_done(write_done),
		.debug_ack(debug_ack),
		.data_out(data_out), 
		.ready(ready), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);
	
		/*
	i2c_slave_controller slave (
    .sda(i2c_sda), 
    .scl(i2c_scl)
    );
	*/
	initial begin
		clk = 0;
		forever begin
			clk = #1 ~clk;
		end		
	end

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		rst = 0;		
		addr = 7'b1010001;
		data_in = 8'b10101010;
		rw = 0;	
		enable = 1;
		#79;
    debug_ack <= 1;
	  @(posedge write_done);
	  rw = 1;	
	
		//wait (ready == 0);
		enable = 1;

		#380
		enable = 0;
		#220
		$finish;
		
	end      
endmodule