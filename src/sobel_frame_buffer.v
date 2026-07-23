module sobel_frame_buffer(
    input           wr_clk,
    input           wr_en,
    input [7:0]     pixel_in,
    input           wr_vsync, 

    input           rd_clk,
    input           rd_de,    
    input           rd_vsync, 
    output reg [7:0] pixel_out,

    input           xrst
);

    parameter PIXEL_NUM = 640 * 480;

    (* ramstyle = "M10K" *) reg [7:0] mem [0:PIXEL_NUM-1];

    // --- WRITE LOGIC---
    reg [18:0] wr_addr;
    always @(posedge wr_clk or negedge xrst) begin
        if (!xrst) begin
            wr_addr <= 19'd0;
        end else if (wr_vsync) begin
            wr_addr <= 19'd0;
        end else if (wr_en) begin
            if (wr_addr < PIXEL_NUM - 1)
                wr_addr <= wr_addr + 1'b1;
            else
                wr_addr <= 19'd0;
        end
    end

    always @(posedge wr_clk) begin
        if (wr_en)
            mem[wr_addr] <= pixel_in;
    end

    // --- READ LOGIC---
    reg [18:0] rd_addr;
    always @(posedge rd_clk or negedge xrst) begin
        if (!xrst) begin
            rd_addr <= 19'd0;
        end else if (!rd_vsync) begin 
            rd_addr <= 19'd0;
        end else if (rd_de) begin
            if (rd_addr < PIXEL_NUM - 1)
                rd_addr <= rd_addr + 1'b1;
            else
                rd_addr <= 19'd0;
        end
    end

    always @(posedge rd_clk) begin
        pixel_out <= mem[rd_addr];
    end

endmodule