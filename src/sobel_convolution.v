module sobel_convolution(
   gradient_x, gradient_y, magnitude,
	
   pixel_00, pixel_01, pixel_02,
   pixel_10, pixel_11, pixel_12,
   pixel_20, pixel_21, pixel_22
);

   input [7:0] pixel_00, pixel_01, pixel_02;
   input [7:0] pixel_10, pixel_11, pixel_12;
   input [7:0] pixel_20, pixel_21, pixel_22;
   
   output signed [11:0] gradient_x;  
   output signed [11:0] gradient_y; 
   output [7:0] magnitude;           
   
   localparam THRESHOLD = 8'd180;
   
   wire signed [11:0] gx_calc;
   assign gx_calc = (-1 * pixel_00) + (0 * pixel_01) + (1 * pixel_02) +
                    (-2 * pixel_10) + (0 * pixel_11) + (2 * pixel_12) +
                    (-1 * pixel_20) + (0 * pixel_21) + (1 * pixel_22);
   
   wire signed [11:0] gy_calc;
   assign gy_calc = (1 * pixel_00) + (2 * pixel_01) + (1 * pixel_02) +
                    (0 * pixel_10) + (0 * pixel_11) + (0 * pixel_12) +
                    (-1 * pixel_20) + (-2 * pixel_21) + (-1 * pixel_22);
   
   assign gradient_x = gx_calc;
   assign gradient_y = gy_calc;
   
   // magnitude calculation: |gx| + |gy| 
   wire [11:0] abs_gx = (gx_calc[11] == 1'b1) ? -gx_calc : gx_calc;
   wire [11:0] abs_gy = (gy_calc[11] == 1'b1) ? -gy_calc : gy_calc;
   wire [12:0] magnitude_sum = abs_gx + abs_gy;
   
   assign magnitude = (magnitude_sum > THRESHOLD) ? 8'hFF : 8'h00;

endmodule