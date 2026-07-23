module vgaHdmi(
	input clock, clock50, reset,
	input [7:0] data_in,
	
	output reg hsync, vsync,
	output reg dataEnable,
	output vgaClock,
	output [23:0] RGBchannel
);

reg [10:0] pixelH, pixelV; 
reg [9:0]	pixel_x, pixel_y;
reg [23:0] r_pixel;

reg h_act, v_act;

wire h_max, hs_end, hr_start,hr_end;
wire v_max, vs_end, vr_start,vr_end;

reg pre1_vga_de;
reg pre2_vga_de;

// Videos Modeline
/*parameter h_display = 1024;
parameter h_front_porch = 40;
parameter h_sync = 104;
parameter h_back_porch = 144;
parameter h_total = 1312;

parameter v_display = 600;
parameter v_front_porch = 3;
parameter v_sync = 10;
parameter v_back_porch = 11;
parameter v_total = 624;*/

parameter h_display = 640;
parameter h_front_porch = 16;
parameter h_sync = 96;
parameter h_back_porch = 48;
parameter h_total = 800;

parameter v_display = 480;
parameter v_front_porch = 10;
parameter v_sync = 2;
parameter v_back_porch = 33;
parameter v_total = 525;

initial begin
	hsync = 1;
	vsync = 1;
	pixelH = 0;
	pixelV = 0;
	dataEnable = 0;
	pre1_vga_de = 0;
	pre2_vga_de = 0;
end


assign h_max = pixelH == (h_total - 1);
assign hs_end = pixelH >= (h_sync - 1);
assign hr_start = pixelH == (h_sync + h_back_porch - 3);
assign hr_end = pixelH == (h_sync + h_back_porch - 3 + h_display);

assign v_max = pixelV == (v_total - 1);
assign vs_end = pixelV >= (v_sync - 1);
assign vr_start = pixelV == (v_sync + v_back_porch - 1);
assign vr_end = pixelV == (v_sync + v_back_porch - 1 + v_display);

always @(posedge clock or posedge reset) begin
	if(reset) begin
		hsync <= 1;
		vsync <= 1;
		pixelH <= 0;
		pixelV <= 0;
	end
	else begin	
		if(h_max)
			pixelH <= 11'b0;
		else
			pixelH <= pixelH + 11'b1;
			
		if (h_act)
			pixel_x	<=	pixel_x + 11'b1;
		else
			pixel_x	<=	11'b0;
		
		if(hs_end && !h_max)
			hsync  <= 1'b1;
		else 
			hsync <= 1'b0;
			
		if(hr_start)
			h_act <= 1'b1;
		else if(hr_end)
			h_act <= 1'b0;

		if (h_max)
		begin
			if(v_max)
				pixelV <= 11'b0;
			else
				pixelV <= pixelV + 11'b1;
				
			if (v_act)
				pixel_y	<=	pixel_y + 11'b1;
			else
				pixel_y	<=	11'b0;
				
			if(vs_end && !v_max)
				vsync  <= 1'b1;
			else 
				vsync <= 1'b0;
				
			if(vr_start)
				v_act <= 1'b1;
			else if(vr_end)
				v_act <= 1'b0;
		end
	end
end

// dataEnable signal
always @(posedge clock or posedge reset) begin
	if(reset) begin
		dataEnable <= 0;
		pre1_vga_de <= 0;
		pre2_vga_de <= 0;
	end
	else begin
		dataEnable <= pre2_vga_de;
		pre2_vga_de <= pre1_vga_de;
		
		pre1_vga_de <= v_act && h_act;
	end
end

assign vgaClock = clock;


assign frame = (hr_start) && (pixelV == (v_sync + v_back_porch + v_display));


always @(posedge clock) begin
    if (v_act && h_act) begin
        if (data_in[7:0] == 8'hFF) begin
            r_pixel[23:16] <= 8'hFF; 
            r_pixel[15:8]  <= 8'hFF; 
            r_pixel[7:0]   <= 8'hFF; 
        end 
        else begin
            r_pixel[23:16] <= 8'h00;
            r_pixel[15:8]  <= 8'h00;
            r_pixel[7:0]   <= 8'h00;
        end
    end else begin
        r_pixel <= 24'b0; //black when out of screen
    end
end

assign RGBchannel = r_pixel;


endmodule
