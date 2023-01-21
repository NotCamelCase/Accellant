module basic_fifo
#
(
    parameter   ADDR_WIDTH              = 4,
    parameter   DATA_WIDTH              = 8,
    parameter   ALMOST_FULL_THRESHOLD   = (2**ADDR_WIDTH)/4,
    parameter   ALMOST_EMPTY_THRESHOLD  = 1
)
(
    input logic                     clk, rst,
    input logic                     clear,
    input logic                     push, pop,
    output logic                    empty, full, almost_empty, almost_full,
    input logic[DATA_WIDTH-1:0]     wr_data,
    output logic[DATA_WIDTH-1:0]    rd_data
);
    logic[DATA_WIDTH-1:0]   buffer_reg[2**ADDR_WIDTH-1:0];

    logic[ADDR_WIDTH-1:0]   wr_ptr_reg, rd_ptr_reg;
    logic[ADDR_WIDTH-1:0]   count_reg, count_nxt;

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            wr_ptr_reg <= '0;
            rd_ptr_reg <= '0;
        end else begin
            if (push) begin
                buffer_reg[wr_ptr_reg] <= wr_data;
                wr_ptr_reg <= wr_ptr_reg + ADDR_WIDTH'(1);
            end

            if (pop)
                rd_ptr_reg <= rd_ptr_reg + ADDR_WIDTH'(1);
        end
    end

    always_ff @(posedge clk) begin
        if (rst || clear)
            count_reg <= '0;
        else
            count_reg <= count_nxt;
    end

    always_comb begin
        count_nxt = count_reg;

        // Push-only
        if (push && !pop)
            count_nxt = count_reg + ADDR_WIDTH'(1);

        // Pop-only
        if (pop && !push)
            count_nxt = count_reg - ADDR_WIDTH'(1);
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            empty <= 1'b1;
            full <= 1'b0;
            almost_empty <= 1'b1;
            almost_full <= 1'b0;
        end else begin
            empty <= ~(|count_nxt);
            full <= count_nxt == (2**ADDR_WIDTH-1);
            almost_empty <= count_nxt <= ALMOST_EMPTY_THRESHOLD;
            almost_full <= count_nxt >= ALMOST_FULL_THRESHOLD;
        end
    end

    // FWFT mode
    assign rd_data = buffer_reg[rd_ptr_reg];
endmodule