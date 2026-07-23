module rgb_to_grayscale (
    input wire [15:0] rgb_data,
    output wire [7:0] gray_data
);
    wire [7:0] r = {rgb_data[15:11], 3'b0};
    wire [7:0] g = {rgb_data[10:5],  2'b0};
    wire [7:0] b = {rgb_data[4:0],   3'b0};

    wire [15:0] sum = (r * 77) + (g * 150) + (b * 29);
    
    assign gray_data = sum[15:8]; 
endmodule