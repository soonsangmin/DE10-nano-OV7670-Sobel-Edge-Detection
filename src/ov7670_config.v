module ov7670_config(
    input wire clk,          
    input wire rst_n,
    input wire start,      
    
    output reg [7:0] reg_addr,
    output reg [7:0] reg_data,
    output reg i2c_start,
    input wire i2c_done,
    
    output reg config_finished
);

    reg [7:0] rom_addr;
    reg [15:0] rom_data;

    reg [2:0] state;
    localparam IDLE   = 0,
               FETCH  = 1,
               WRITE  = 2,
               WAIT   = 3,
               DONE   = 4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rom_addr <= 0;
            i2c_start <= 0;
            config_finished <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) state <= FETCH;
                end

                FETCH: begin
                    if (rom_data == 16'hFFFF) begin 
                        state <= DONE;
                    end else begin
                        reg_addr  <= rom_data[15:8];
                        reg_data  <= rom_data[7:0];
                        state     <= WRITE;
                    end
                end

                WRITE: begin
                    i2c_start <= 1;
                    state     <= WAIT;
                end

                WAIT: begin
                    i2c_start <= 0;
                    if (i2c_done) begin
                        rom_addr <= rom_addr + 1'b1;
                        state    <= FETCH;
                    end
                end

                DONE: begin
                    config_finished <= 1;
                    state <= DONE;
                end
            endcase
        end
    end

    always @(*) begin
        case (rom_addr)
            
            0  : rom_data = 16'h1280; // COM7
            1  : rom_data = 16'h1180; // CLKRC

            2  : rom_data = 16'h1204; // COM7
            3  : rom_data = 16'h40D0; // COM15: RGB565
            4  : rom_data = 16'h1502; 

            5  : rom_data = 16'h1E00; 

            6  : rom_data = 16'h13E5; 
            7  : rom_data = 16'h1400; // COM9
            8  : rom_data = 16'h0000; // GAIN
            9  : rom_data = 16'h1000; // AECH

            10 : rom_data = 16'h1713; // HSTART
            11 : rom_data = 16'h1801; // HSTOP
            12 : rom_data = 16'h32B6; // HREF control
            13 : rom_data = 16'h1902; // VSTART
            14 : rom_data = 16'h1A7A; // VSTOP
            15 : rom_data = 16'h030A; // VREF control
				
				
				16 : rom_data = 16'h3A04;
				17 : rom_data = 16'h4FC0; // Matrix Coefficient 1
				18 : rom_data = 16'h5099; // Matrix Coefficient 2
				19 : rom_data = 16'h5100; // Matrix Coefficient 3
				20 : rom_data = 16'h523D; // Matrix Coefficient 4
				21 : rom_data = 16'h5335; // Matrix Coefficient 5
				22 : rom_data = 16'h54C4; // Matrix Coefficient 6
				23 : rom_data = 16'hB084; // Matrix Control
				24 : rom_data = 16'h5530; // Bright
				

            default: rom_data = 16'hFFFF; 
        endcase
    end
endmodule