module camera_interface (
    input  wire        pclk,      
    input  wire        rst_n,     
    input  wire        href,    
    input  wire        vsync,     
    input  wire [7:0]  d_in,      
    
    output reg  [23:0] vid_data,  
    output reg         vid_de,    
    output reg         vid_datavalid,
    output wire        vid_h_sync,
    output wire        vid_v_sync,
    
    output reg  [19:0] frame_pixel_count 
);

    reg [7:0] byte_hold;      
    reg       byte_ctrl; 

    assign vid_h_sync = !href;
    assign vid_v_sync = vsync;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vid_data          <= 24'd0;
            vid_de            <= 1'b0;
            vid_datavalid     <= 1'b0;
            byte_hold         <= 8'd0;
            byte_ctrl         <= 1'b0;
            frame_pixel_count <= 20'd0;
        end 
        else begin
            vid_datavalid <= !vid_datavalid;

            if (vsync) begin
                byte_ctrl         <= 1'b0;
                vid_de            <= 1'b0;
                frame_pixel_count <= 20'd0; 
            end 
            else if (!href) begin 
                if (byte_ctrl == 1'b0) begin
                    byte_hold <= d_in;
                    byte_ctrl <= 1'b1;     
                    vid_de    <= 1'b0; 
                end 
                else begin
							vid_data[23:16] <= {byte_hold[7:3], 3'b000};
							vid_data[15:8]  <= {byte_hold[2:0],d_in[7:5], 2'b00};           
							vid_data[7:0]   <= {d_in[4:0], 3'b000};                
                    
                    byte_ctrl <= 1'b0;
                    vid_de    <= 1'b1; 
                    frame_pixel_count <= frame_pixel_count + 1'b1;
                end
            end 
            else begin
                byte_ctrl <= 1'b0;
                vid_de    <= 1'b0;
            end
        end
    end
endmodule