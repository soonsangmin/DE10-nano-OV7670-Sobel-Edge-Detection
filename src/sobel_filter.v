module sobel_filter(
    rcv_req, pixel_out, snd_ack, sobel_vsync,
	 
    clk, xrst, pixel_in, rcv_ack, snd_req, cam_vsync
);

    input clk;
    input xrst;

    input wire [7:0] pixel_in;  
    output rcv_req;
    input rcv_ack;
    
    input cam_vsync;       

    output [7:0] pixel_out; 
    input snd_req;
    output snd_ack;
    
    output sobel_vsync;
    
    parameter WIDTH = 640;
    parameter HEIGHT = 480;

    //////////////////////////////////////////////////////////
    // Stage 0: Tracking & Line Buffer 
    //////////////////////////////////////////////////////////
    reg enable_reg;
    reg [9:0] col_count; 
    reg [8:0] row_count; 
    
    always @(posedge clk or negedge xrst) begin
        if (xrst == 1'b0) begin
            row_count <= 9'd0;
            col_count <= 10'd0;
        end else if (enable_reg) begin
            if (col_count == WIDTH - 1) begin
                col_count <= 10'd0;
                row_count <= (row_count == HEIGHT - 1) ? 9'd0 : row_count + 1'b1;
            end else begin
                col_count <= col_count + 1'b1;
            end
        end
    end

    wire [7:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;

    line_buffer_ctrl line_buf_r(
      .pixel_00(p00), .pixel_01(p01), .pixel_02(p02),
      .pixel_10(p10), .pixel_11(p11), .pixel_12(p12),
      .pixel_20(p20), .pixel_21(p21), .pixel_22(p22),
      .pixel_in(pixel_in), .enable(enable_reg), .clk(clk), .xrst(xrst),
      .row_count(row_count), .col_count(col_count)
   );

    always @(posedge clk or negedge xrst) begin
        if (xrst == 1'b0) enable_reg <= 1'b0;
        else enable_reg <= rcv_ack;
    end

    reg s1_ack_reg;
    wire [7:0] magnitude_binary; 

    sobel_convolution sobel_inst (
        .pixel_00(p00), .pixel_01(p01), .pixel_02(p02),
        .pixel_10(p10), .pixel_11(p11), .pixel_12(p12),
        .pixel_20(p20), .pixel_21(p21), .pixel_22(p22),
        .magnitude(magnitude_binary)
    );

    always @(posedge clk or negedge xrst) begin
        if (xrst == 1'b0) s1_ack_reg <= 1'b0;
        else s1_ack_reg <= enable_reg;
    end

    //////////////////////////////////////////////////////////
    // Stage 2: Output Register 
    //////////////////////////////////////////////////////////
    reg [7:0] s2_pixel_reg;
    reg s2_ack_reg;

    always @(posedge clk or negedge xrst) begin
        if (xrst == 1'b0) begin
            s2_pixel_reg <= 8'd0;
            s2_ack_reg <= 1'b0;
        end else begin
            s2_pixel_reg <= magnitude_binary;
            s2_ack_reg <= s1_ack_reg;
        end
    end
    
    reg s1_vsync_reg, s2_vsync_reg, s3_vsync_reg;
    always @(posedge clk or negedge xrst) begin
        if (!xrst) begin
            s1_vsync_reg <= 1'b1;
            s2_vsync_reg <= 1'b1;
				s3_vsync_reg <= 1'b1;
        end else begin
            s1_vsync_reg <= cam_vsync; 
            s2_vsync_reg <= s1_vsync_reg;
            s3_vsync_reg <= s2_vsync_reg;
        end
    end

    // out
    assign sobel_vsync = s3_vsync_reg;
    assign pixel_out = s2_pixel_reg;
    assign snd_ack = s2_ack_reg;
    assign rcv_req = snd_req;

endmodule