module hdmi_text(
	input wire clock50, 
	input wire rst_n,
	input wire clk_vga,
	input wire [15:0] pixel_in,
	input wire locked_from_pll,
	
	// ** HDMI CONNECTIONS **
	
	// AUDIO
	output HDMI_I2S0, 
	output HDMI_MCLK, 
	output HDMI_LRCLK, 
	output HDMI_SCLK, 
	
	// VIDEO
	output [23:0] HDMI_TX_D, // RGBchannel
	output HDMI_TX_VS, // vsync
	output HDMI_TX_HS, // hsync
	output HDMI_TX_DE, // dataEnable
	output HDMI_TX_CLK, // vgaClock
	
	// REGISTERS AND CONFIG LOGIC
	input HDMI_TX_INT,
	inout HDMI_I2C_SDA, 	
	output HDMI_I2C_SCL, 
	//output READY 			// HDMI is ready signal from i2c module
	output hdmi_ready	// HDMI is ready signal from i2c module
	// ********************************************** //
	);

//wire clockHDMI;
//wire locked;
//wire rst = ~rst;

assign HDMI_I2S0 = 1'b z;
assign HDMI_MCLK = 1'b z;
assign HDMI_LRCLK = 1'b z;
assign HDMI_SCLK = 1'b z;

// ** VGA MAIN CONTROLLER **
vgaHdmi vgaHdmi (
	// input
	.clock	(clk_vga),
	.clock50	(clock50),		
	.reset	(~locked_from_pll),
	.data_in (pixel_in),
	
	// ouput
	.hsync	(HDMI_TX_HS),
	.vsync	(HDMI_TX_VS),
	.dataEnable	(HDMI_TX_DE),
	.vgaClock	(HDMI_TX_CLK),
	.RGBchannel	(HDMI_TX_D)
);

// ** I2C Interface for ADV7513 initial config **
I2C_HDMI_Config I2C_HDMI_Config(
	.iCLK				(clock50),
	.iRST_N			(rst_n),
	.I2C_SCLK		(HDMI_I2C_SCL),
	.I2C_SDAT		(HDMI_I2C_SDA),
	.HDMI_TX_INT	(HDMI_TX_INT),
	.READY			(hdmi_ready)
);

endmodule