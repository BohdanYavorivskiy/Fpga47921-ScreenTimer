// SPI byte engine for the LCD link.
// Mode 0 (CPOL=0, CPHA=0), MSB first; CS pulses low for exactly one byte and
// returns high before the next one, which is what the ST7735S expects.
//
// Handshake: drive start high for one clock with tx_byte/tx_dc valid. busy goes
// high immediately and drops only after the byte and the trailing CS-high gap.
module spi_master #(
    parameter DIV = 2                      // sclk = clk / (2*DIV)
)(
    input            clk,
    input            start,
    input            tx_dc,                // 0 = command, 1 = data
    input      [7:0] tx_byte,
    output           busy,
    output           cs,
    output           dc,
    output           mosi,
    output           sclk
);
    reg       r_busy = 1'b0;
    reg       r_cs   = 1'b1;
    reg       r_dc   = 1'b0;
    reg       r_mosi = 1'b0;
    reg       r_sclk = 1'b0;
    reg [7:0] sh     = 8'd0;
    reg [3:0] bitn   = 4'd0;               // 0..7 = bit index, 8 = CS-high gap
    reg [3:0] div    = 4'd0;

    assign busy = r_busy;
    assign cs   = r_cs;
    assign dc   = r_dc;
    assign mosi = r_mosi;
    assign sclk = r_sclk;

    always @(posedge clk) begin
        if (!r_busy) begin
            if (start) begin
                r_busy <= 1'b1;
                r_cs   <= 1'b0;
                r_dc   <= tx_dc;
                sh     <= tx_byte;
                r_mosi <= tx_byte[7];
                bitn   <= 4'd0;
                r_sclk <= 1'b0;
                div    <= 4'd0;
            end
        end else if (div == DIV - 1) begin
            div <= 4'd0;
            if (bitn == 4'd8) begin
                r_busy <= 1'b0;            // CS-high gap finished
            end else if (!r_sclk) begin
                r_sclk <= 1'b1;            // rising edge: the slave samples here
            end else begin
                r_sclk <= 1'b0;
                if (bitn == 4'd7) begin
                    r_cs <= 1'b1;
                    bitn <= 4'd8;
                end else begin
                    bitn   <= bitn + 4'd1;
                    sh     <= {sh[6:0], 1'b0};
                    r_mosi <= sh[6];
                end
            end
        end else begin
            div <= div + 4'd1;
        end
    end
endmodule
