module uart_tx
(
    input logic         clk, rst,
    input logic         tx_start, baud_pulse,
    input logic[7:0]    tx_data,
    output logic        uart_tx_done,
    output logic        tx
);
    typedef enum {
        IDLE,
        START,
        DATA,
        STOP,
        DONE
    } state_t;

    localparam  DATA_WIDTH = 8;
    localparam  START_TICKS = 16;
    localparam  DATA_TICKS = 16;
    localparam  STOP_TICKS = 16 * 1;

    state_t     state_reg;
    logic[3:0]  tick_ctr_reg;
    logic[2:0]  bit_ctr_reg;
    logic[7:0]  data_reg;

    logic       tx_done_reg;
    logic       tx_data_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= IDLE;
            tx_done_reg <= 1'b0;
            tx_data_reg <= 1'b1;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    tick_ctr_reg <= '0;
                    bit_ctr_reg <= '0;
                    data_reg <= tx_data;

                    if (tx_start)
                        state_reg <= START;
                end

                START: begin
                    tx_data_reg <= 1'b0; // Start bit

                    if (baud_pulse) begin
                        if (tick_ctr_reg == 4'(START_TICKS-1)) begin
                            tick_ctr_reg <= '0;
                            state_reg <= DATA;
                        end else begin
                            tick_ctr_reg <= tick_ctr_reg + 4'h1;
                        end
                    end
                end

                DATA: begin
                    tx_data_reg <= data_reg[0];

                    if (baud_pulse) begin
                        if (tick_ctr_reg == 4'(DATA_TICKS-1)) begin
                            tick_ctr_reg <= '0;
                            data_reg <= data_reg >> 1; // Shift in next bit to be transmitted

                            if (bit_ctr_reg == 3'(DATA_WIDTH-1))
                                state_reg <= STOP;
                            else
                                bit_ctr_reg <= bit_ctr_reg + 3'd1;
                        end else begin
                            tick_ctr_reg <= tick_ctr_reg + 4'd1;
                        end
                    end
                end

                STOP: begin
                    tx_data_reg <= 1'b1; // Stop bit

                    if (baud_pulse) begin
                        if (tick_ctr_reg == 4'(STOP_TICKS-1)) begin
                            state_reg <= DONE;
                            tx_done_reg <= 1'b1;
                        end else begin
                            tick_ctr_reg <= tick_ctr_reg + 4'h1;
                        end
                    end
                end

                DONE: begin
                    tx_done_reg <= 1'b0;
                    state_reg <= IDLE;
                end

                default: ;
            endcase
        end
    end

    // Outputs
    assign tx = tx_data_reg;
    assign uart_tx_done = tx_done_reg;
endmodule