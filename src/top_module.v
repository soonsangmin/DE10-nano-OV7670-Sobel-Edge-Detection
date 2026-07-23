module top_module(
    // Clocks & Reset
    input  wire        fpga_clk_50,   
    input  wire        reset_n,      

    // CMOS Camera Pins 
    input  wire        cmos_pclk,
    input  wire        cmos_vsync,
    input  wire        cmos_href,
    input  wire [7:0]  cmos_db,
    output wire        cmos_xclk,     // Camera clk
    output wire        cmos_scl,
    inout  wire        cmos_sda,

    // HDMI Pins
    output wire [23:0] HDMI_TX_D,
    output wire        HDMI_TX_VS,
    output wire        HDMI_TX_HS,
    output wire        HDMI_TX_DE,
    output wire        HDMI_TX_CLK,
    input  wire        HDMI_TX_INT,
    inout  wire        HDMI_I2C_SDA, 
    output wire        HDMI_I2C_SCL,

    output wire [7:0]  led            
);

    // --- (PLL) ---
    wire clk_24m, clk_25m;
	 
	 wire pll_locked;
	 
    pll_25_24 pll (
        .refclk(fpga_clk_50), .rst(~reset_n),
		  .locked(pll_locked),
        .outclk_0(clk_24m), .outclk_1(clk_25m)
    );
    assign cmos_xclk = clk_24m;

    // --- (I2C/SCCB) ---
    wire cfg_done;
    wire [7:0] r_addr, r_data;
    wire i2c_start, i2c_done;

    ov7670_config cfg_ctrl (
        .clk(fpga_clk_50), .rst_n(reset_n), .start(1'b1),
        .reg_addr(r_addr), .reg_data(r_data),
        .i2c_start(i2c_start), .i2c_done(i2c_done),
        .config_finished(cfg_done)
    );

    i2c_camera_controller i2c_cam (
        .clk(fpga_clk_50), .rst_n(reset_n), .addr(8'h42),
        .reg_addr(r_addr), .data(r_data),
        .start(i2c_start), .done(i2c_done),
        .scl(cmos_scl), .sda(cmos_sda)
    );

    // --- (Pipeline) ---
    wire [15:0] raw_rgb;
    wire        raw_valid;
    wire [7:0]  gray_data;
    wire [7:0]  sobel_pixel_data;
    wire        sobel_ack_wire;
    wire        sobel_vsync_wire;

    // A. Interface
    camera_interface cap (
        .pclk(cmos_pclk), .rst_n(reset_n), .href(cmos_href),
        .vsync(cmos_vsync), .d_in(cmos_db),
        .pixel_rgb(raw_rgb), .pixel_valid(raw_valid)
    );

    // B. Gray
    rgb_to_grayscale g_conv (
        .rgb_data(raw_rgb), .gray_data(gray_data)
    );


    // D. Sobel Convolution
    sobel_filter sob_inst (
        .clk(cmos_pclk),
        .xrst(reset_n),
        .pixel_in(gray_data),
        .rcv_ack(raw_valid),    // pixel_valid from camera
        .cam_vsync(cmos_vsync), // camera vsync
        .rcv_req(),
        
        .pixel_out(sobel_pixel_data),
        .snd_ack(sobel_ack_wire),      // connect to wr_en of FB
        .sobel_vsync(sobel_vsync_wire), // connect to wr_vsync of FB
        .snd_req(1'b1)
    );

    wire [7:0] display_pixel_8bit;
    wire fifo_empty;

    sobel_frame_buffer fb_inst (
        // write (Camera Clock Domain - 24MHz)
        .wr_clk(cmos_pclk),
        .wr_en(sobel_ack_wire),        // 1 Sobel pixel done
        .pixel_in(sobel_pixel_data),
        .wr_vsync(sobel_vsync_wire),   // Reset wr_addr depend on delay vsync
        
        // read (HDMI Clock Domain - 25MHz)
        .rd_clk(clk_25m),
        .rd_de(HDMI_TX_DE),            // read when HDMI Data Enable = 1
        .rd_vsync(HDMI_TX_VS),         // Reset rd_addr when finished reading a frame
        .pixel_out(display_pixel_8bit),
        .xrst(reset_n)
    );
	 

    // --- HDMI ---
	 wire hdmi_is_ready;

    hdmi_text hdmi_out (
        .clock50(fpga_clk_50),
        .clk_vga(clk_25m),
        .rst_n(reset_n),
        .pixel_in(display_pixel_8bit),
		  .locked_from_pll(pll_locked),
        
        .HDMI_TX_D(HDMI_TX_D), .HDMI_TX_VS(HDMI_TX_VS), .HDMI_TX_HS(HDMI_TX_HS),
        .HDMI_TX_DE(HDMI_TX_DE), .HDMI_TX_CLK(HDMI_TX_CLK), .HDMI_TX_INT(HDMI_TX_INT),
        .HDMI_I2C_SDA(HDMI_I2C_SDA), .HDMI_I2C_SCL(HDMI_I2C_SCL),
        .hdmi_ready(hdmi_is_ready)
    );

    assign led[0] = cfg_done;     
	 assign led[7] = hdmi_is_ready; 
	 assign led[6:1] = 6'b0;
endmodule