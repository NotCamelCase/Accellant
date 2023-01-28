module uart_rx
(
    input logic         clk, rst,
    input logic         rx, baud_pulse,
    output logic        uart_rx_done,
    output logic[7:0]   rx_data
);
    typedef enum {
        IDLE,
        START,
        DATA,
        STOP,
        DONE
    } state_t;

    localparam  DATA_WIDTH = 8;
    localparam  START_TICKS = 8;
    localparam  DATA_TICKS = 16;
    localparam  STOP_TICKS = 16 * 1;

    state_t     state_reg;
    logic[3:0]  tick_ctr_reg;
    logic[2:0]  bit_ctr_reg;

    logic       rx_done_reg;
    logic[7:0]  rx_data_reg;

     always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= IDLE;
            rx_done_reg <= 1'b0;
        end else begin
            unique case (state_reg)
                IDLE: begin
                    tick_ctr_reg <= '0;
                    bit_ctr_reg <= '0;

                    if (~rx)
                        state_reg <= START;
                end

                START: begin
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
                    if (baud_pulse) begin
                        if (tick_ctr_reg == 4'(DATA_TICKS-1)) begin
                            tick_ctr_reg <= '0;
                            rx_data_reg <= {rx, rx_data_reg[7:1]}; // Shift received data bit 'rx' in

                            if (bit_ctr_reg == 3'(DATA_WIDTH-1))
                                state_reg <= STOP;
                            else
                                bit_ctr_reg <= bit_ctr_reg + 3'h1;
                        end else begin
                            tick_ctr_reg <= tick_ctr_reg + 4'h1;
                        end
                    end
                end

                STOP: begin
                    if (baud_pulse) begin
                        if (tick_ctr_reg == 4'(STOP_TICKS-1)) begin
                            state_reg <= DONE;
                            rx_done_reg <= 1'b1;
                        end else begin
                            tick_ctr_reg <= tick_ctr_reg + 4'h1;
                        end
                    end
                end

                DONE: begin
                    rx_done_reg <= 1'b0;
                    state_reg <= IDLE;
                end

                default: ;
            endcase
        end
     end

     // Outputs
     assign rx_data = rx_data_reg;
     assign uart_rx_done = rx_done_reg;
endmodule