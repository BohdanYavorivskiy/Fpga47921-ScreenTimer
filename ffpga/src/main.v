// Pmod LCD 0.96" (ST7735S, 160x80, 4-wire SPI) - stopwatch MM:SS.CC with a
// status icon in the top-right corner.
//
//   GPIO13 : start / pause            GPIO14 : stop + reset
//   GPIO15 : panel reset              GPIO8/9/10/11 : CS / MOSI / DC / SCLK
//
// Clocking: the on-chip oscillator runs at 50 MHz and post-divider OUT0 halves
// it, so i_clk is 25 MHz. The clock source must be selected in CLK MUX0 in the
// project (register setting, not RTL) and i_clk mapped to GLOBAL_CLK_MUX_OUT[0].
//
// Top level only wires things together:
//   stopwatch - buttons and the BCD time
//   lcd_ctrl  - panel reset, init sequence and pixel streaming
//               (spi_master + lcd_init_rom + pixel_gen + font5x7)
(* top *) module main(
    (* clkbuf_inhibit *) input i_clk,
    input  i_btn_start,
    input  i_btn_stop,
    output o_btn_start_pu,
    output o_btn_stop_pu,
    output o_osc_en,
    output o_osc_mode,
    output o_postdiv0_en,
    output o_postdiv0_sel0,
    output o_postdiv0_sel1,
    output o_postdiv0_sel2,
    output o_tft_reset,
    output o_tft_reset_oe,
    output o_tft_cs,
    output o_tft_cs_oe,
    output o_tft_dc,
    output o_tft_dc_oe,
    output o_tft_mosi,
    output o_tft_mosi_oe,
    output o_tft_clk,
    output o_tft_clk_oe
);
    // On-chip oscillator: 50 MHz mode, post-divider OUT0 = 50/2 = 25 MHz (DIV_SEL=001)
    assign o_osc_en        = 1'b1;
    assign o_osc_mode      = 1'b1;
    assign o_postdiv0_en   = 1'b1;
    assign o_postdiv0_sel0 = 1'b1;
    assign o_postdiv0_sel1 = 1'b0;
    assign o_postdiv0_sel2 = 1'b0;

    assign o_btn_start_pu  = 1'b1;     // internal pull-ups for the buttons
    assign o_btn_stop_pu   = 1'b1;

    assign o_tft_reset_oe  = 1'b1;     // every LCD pin is driven, never sensed
    assign o_tft_cs_oe     = 1'b1;
    assign o_tft_dc_oe     = 1'b1;
    assign o_tft_mosi_oe   = 1'b1;
    assign o_tft_clk_oe    = 1'b1;

    wire       running;
    wire       armed;
    wire [1:0] smode;
    wire [3:0] m1, m0, s1, s0, c1, c0;

    stopwatch u_sw (
        .clk(i_clk),
        .i_btn_start(i_btn_start),
        .i_btn_stop(i_btn_stop),
        .o_mode(smode),
        .o_running(running),
        .o_armed(armed),
        .o_m1(m1), .o_m0(m0), .o_s1(s1), .o_s0(s0), .o_c1(c1), .o_c0(c0)
    );

    lcd_ctrl u_lcd (
        .clk(i_clk),
        .i_mode(smode),
        .i_m1(m1), .i_m0(m0), .i_s1(s1), .i_s0(s0), .i_c1(c1), .i_c0(c0),
        .o_reset(o_tft_reset),
        .o_cs(o_tft_cs),
        .o_dc(o_tft_dc),
        .o_mosi(o_tft_mosi),
        .o_sclk(o_tft_clk)
    );
endmodule
