module bit_synchronizer
(
    input logic     clk, arstn,
    input logic     d_async,
    output logic    q_sync
);
    (* ASYNC_REG = "true" *) logic sync1_reg, sync2_reg;

    always_ff @(posedge clk, negedge arstn) begin
        if (~arstn) begin
            sync1_reg <= 1'b0;
            sync2_reg <= 1'b0;
            q_sync <= 1'b0;
        end else begin
            sync1_reg <= d_async;
            sync2_reg <= sync1_reg;
            q_sync <= sync2_reg;
        end
    end
endmodule