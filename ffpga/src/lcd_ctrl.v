// LCD sequencer: pulses the panel reset, plays the ST7735S init sequence,
// paints one black full-screen frame and then repaints the text band forever.
// The 16x16 status icon lives in its own window and is repainted only when the
// stopwatch mode changes, so the digits can refresh at ~170 Hz.
//
// One FSM drives everything; the byte engine, the init ROM and the colour
// lookup live in their own modules. Pixels are generated on the fly, so there
// is no frame buffer.
//
// The windows the panel is told to write are fragile: a band starting at row
// 0x1C made this panel display nothing, while 0x1A and 0x37 work. Do not
// change the RASET values in lcd_init_rom without testing on hardware.
module lcd_ctrl #(
    parameter       SPI_DIV  = 1,          // SPI clock = clk / (2*SPI_DIV) = 12.5 MHz
    parameter [6:0] IDX_TEXT = 7'd90,      // ROM index that opens the text band
    parameter [6:0] IDX_ICON = 7'd102      // ROM index that opens the icon band
)(
    input             clk,
    input      [1:0]  i_mode,
    input      [3:0]  i_m1,
    input      [3:0]  i_m0,
    input      [3:0]  i_s1,
    input      [3:0]  i_s0,
    input      [3:0]  i_c1,
    input      [3:0]  i_c0,
    output            o_reset,             // active low panel reset
    output            o_cs,
    output            o_dc,
    output            o_mosi,
    output            o_sclk
);
    // ---- frame geometry ----
    localparam [6:0] LAST_ROW_FULL = 7'd79;    // black clear frame: 80 rows
    localparam [6:0] LAST_ROW_TEXT = 7'd20;    // text band: 21 rows (7 glyph rows x3)
    localparam [6:0] LAST_ROW_ICON = 7'd17;    // icon band: 18 rows

    // frame kinds
    localparam [1:0] PH_CLEAR = 2'd0, PH_TEXT = 2'd1, PH_ICON = 2'd2;
    localparam [4:0] LAST_PX       = 5'd19;    // 20 pixels per character cell
    localparam [2:0] LAST_CELL     = 3'd7;     // 8 character cells

    // ---- FSM ----
    localparam S_RST_LOW = 4'd0, S_RST_HIGH = 4'd1, S_FETCH = 4'd2, S_W1 = 4'd3,
               S_W2 = 4'd4, S_DLY = 4'd5, S_PREP = 4'd6, S_PIX = 4'd7,
               S_PW1 = 4'd8, S_PW2 = 4'd9;

    reg [3:0]  state = S_RST_LOW;
    reg [26:0] t     = 27'd0;              // reset and inter-command delays
    reg [6:0]  idx   = 7'd0;               // init ROM pointer

    // scan position inside the current frame
    reg [4:0] pxc  = 5'd0;                 // pixel inside the character cell
    reg [2:0] cx   = 3'd0;                 // character cell
    reg [6:0] ycnt = 7'd0;                 // row inside the window
    reg [2:0] gr   = 3'd0;                 // glyph row
    reg [1:0] sr   = 2'd0;                 // sub-row, vertical scale x3
    reg       lo   = 1'b0;                 // 0 = high colour byte, 1 = low byte

    reg [15:0] pix_col = 16'h0000;
    reg [1:0]  ph = PH_CLEAR;              // kind of frame being streamed
    reg [1:0]  icon_cur = 2'd0;            // mode the icon on screen shows
    reg        icon_valid = 1'b0;          // 0 until the first icon frame is done

    // latched once per frame so the picture never tears mid-frame
    reg [1:0] d_mode = 2'd0;
    reg [3:0] d_m1 = 4'd0, d_m0 = 4'd0, d_s1 = 4'd0, d_s0 = 4'd0, d_c1 = 4'd0, d_c0 = 4'd0;

    // SPI handshake
    reg       start   = 1'b0;
    reg       tx_dc   = 1'b0;
    reg [7:0] tx_byte = 8'd0;
    wire      busy;

    wire       rom_end, rom_delay, rom_dc;
    wire [7:0] rom_byte;
    wire [15:0] color;

    assign o_reset = (state != S_RST_LOW); // low only while in S_RST_LOW

    spi_master #(.DIV(SPI_DIV)) u_spi (
        .clk(clk), .start(start), .tx_dc(tx_dc), .tx_byte(tx_byte),
        .busy(busy), .cs(o_cs), .dc(o_dc), .mosi(o_mosi), .sclk(o_sclk)
    );

    lcd_init_rom u_rom (
        .i_idx(idx), .o_end(rom_end), .o_delay(rom_delay),
        .o_dc(rom_dc), .o_byte(rom_byte)
    );

    pixel_gen u_px (
        .i_cx(cx), .i_pxc(pxc), .i_ycnt(ycnt), .i_kind(ph), .i_gr(gr), .i_mode(d_mode),
        .i_m1(d_m1), .i_m0(d_m0), .i_s1(d_s1), .i_s0(d_s0), .i_c1(d_c1), .i_c0(d_c0),
        .o_color(color)
    );

    wire [6:0] last_row = (ph == PH_CLEAR) ? LAST_ROW_FULL :
                          (ph == PH_TEXT)  ? LAST_ROW_TEXT : LAST_ROW_ICON;
    // the icon is redrawn after the clear frame and whenever the mode changes
    wire need_icon = !icon_valid || (i_mode != icon_cur);

    always @(posedge clk) begin
        case (state)
            S_RST_LOW: begin                       // hold reset low ~84 ms
                t <= t + 27'd1;
                if (t[21]) begin t <= 27'd0; state <= S_RST_HIGH; end
            end
            S_RST_HIGH: begin                      // let the panel settle ~335 ms
                t <= t + 27'd1;
                if (t[23]) begin t <= 27'd0; state <= S_FETCH; end
            end
            S_FETCH: begin
                if (rom_end) begin
                    state <= S_PREP;               // RAMWR sent, start streaming pixels
                end else if (rom_delay) begin
                    t <= 27'd0; state <= S_DLY;
                end else begin
                    tx_dc   <= rom_dc;
                    tx_byte <= rom_byte;
                    start   <= 1'b1;
                    state   <= S_W1;
                end
            end
            S_W1: begin start <= 1'b0; state <= S_W2; end
            S_W2: if (!busy) begin idx <= idx + 7'd1; state <= S_FETCH; end
            S_DLY: begin
                t <= t + 27'd1;
                if (t[23]) begin idx <= idx + 7'd1; state <= S_FETCH; end
            end
            S_PREP: begin                          // register the colour, then send it
                pix_col <= (ph == PH_CLEAR) ? 16'h0000 : color;
                state   <= S_PIX;
            end
            S_PIX: begin
                tx_dc   <= 1'b1;
                tx_byte <= lo ? pix_col[7:0] : pix_col[15:8];
                start   <= 1'b1;
                state   <= S_PW1;
            end
            S_PW1: begin start <= 1'b0; state <= S_PW2; end
            S_PW2: if (!busy) begin
                if (!lo) begin
                    lo <= 1'b1; state <= S_PIX;    // second byte of the same pixel
                end else begin
                    lo <= 1'b0;
                    if (pxc != LAST_PX) begin
                        pxc <= pxc + 5'd1; state <= S_PREP;
                    end else begin
                        pxc <= 5'd0;
                        if (cx != LAST_CELL) begin
                            cx <= cx + 3'd1; state <= S_PREP;
                        end else begin
                            cx <= 3'd0;
                            if (ycnt == last_row) begin        // frame done
                                ycnt <= 7'd0; gr <= 3'd0; sr <= 2'd0;
                                d_m1 <= i_m1; d_m0 <= i_m0; d_s1 <= i_s1;
                                d_s0 <= i_s0; d_c1 <= i_c1; d_c0 <= i_c0;
                                if (need_icon) begin
                                    ph <= PH_ICON; idx <= IDX_ICON;
                                    d_mode <= i_mode; icon_cur <= i_mode; icon_valid <= 1'b1;
                                end else begin
                                    ph <= PH_TEXT; idx <= IDX_TEXT;
                                end
                                state <= S_FETCH;
                            end else begin
                                ycnt <= ycnt + 7'd1;
                                if (sr == 2'd2) begin sr <= 2'd0; gr <= gr + 3'd1; end   // glyph row x3
                                else sr <= sr + 2'd1;
                                state <= S_PREP;
                            end
                        end
                    end
                end
            end
            default: ;
        endcase
    end
endmodule
