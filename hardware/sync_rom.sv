module sync_rom
#(
    parameter ROM_FILE      = "",
    parameter READ_HEX      = "NO",
    parameter ADDR_WIDTH    = 6,
    parameter DATA_WIDTH    = 8
)
(
    input logic                     clk,
    input logic[ADDR_WIDTH-1:0]     addr,
    output logic[DATA_WIDTH-1:0]    data
);
    logic[DATA_WIDTH-1:0]   rom[2**ADDR_WIDTH-1:0];
    logic[DATA_WIDTH-1:0]   data_reg;

    generate
        if (READ_HEX != "NO") begin
            initial begin
                $readmemh(ROM_FILE, rom);
            end
        end else begin
            initial begin
                $readmemb(ROM_FILE, rom);
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        data_reg <= rom[addr];
    end

    assign data = data_reg;
endmodule
