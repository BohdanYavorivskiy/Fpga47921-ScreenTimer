// Pixel colour for one position inside a 160-pixel-wide window.
// Two kinds of window share this logic:
//   i_kind = 1 : text band, 21 rows - the MM:SS.CC digits
//   i_kind = 2 : icon band, 18 rows - 16x16 status icon in the right-most cell
// Everything here is combinational - the controller walks the counters and
// this returns the colour of that pixel.
module pixel_gen #(
    parameter [15:0] COL_TEXT    = 16'hFFFF,   // digits: white
    parameter [15:0] COL_RUNNING = 16'h07E0,   // icon: green
    parameter [15:0] COL_PAUSED  = 16'hFFE0,   // icon: yellow
    parameter [15:0] COL_RESET   = 16'hF800,   // icon: red
    parameter [15:0] COL_BG      = 16'h0000
)(
    input      [2:0]  i_cx,                // character cell 0..7
    input      [4:0]  i_pxc,               // pixel inside the cell 0..19
    input      [6:0]  i_ycnt,              // row inside the window
    input      [1:0]  i_kind,              // 1 = text band, 2 = icon band
    input      [2:0]  i_gr,                // glyph row 0..6
    input      [1:0]  i_mode,              // 0 = reset, 1 = running, 2 = paused
    input      [3:0]  i_m1,
    input      [3:0]  i_m0,
    input      [3:0]  i_s1,
    input      [3:0]  i_s0,
    input      [3:0]  i_c1,
    input      [3:0]  i_c0,
    output     [15:0] o_color
);
    localparam [2:0] ICON_CELL = 3'd7;     // icon sits in the last character cell
    localparam [6:0] ICON_TOP  = 7'd2;     // two blank rows above the icon

    // ---- character under the current cell: M M : S S . C C ----
    reg [3:0] ch;
    always @(*) begin
        case (i_cx)
            3'd0: ch = i_m1;
            3'd1: ch = i_m0;
            3'd2: ch = 4'd10;              // ':'
            3'd3: ch = i_s1;
            3'd4: ch = i_s0;
            3'd5: ch = 4'd11;              // '.'
            3'd6: ch = i_c1;
            default: ch = i_c0;
        endcase
    end

    wire [4:0] frow;
    font5x7 u_font (.i_ch(ch), .i_row(i_gr), .o_bits(frow));

    // ---- horizontal scale x3: 5 glyph columns over pixels 2..16 ----
    reg [2:0] gcol;
    reg       gvalid;
    always @(*) begin
        gvalid = 1'b1;
        case (i_pxc)
            5'd2, 5'd3, 5'd4:    gcol = 3'd0;
            5'd5, 5'd6, 5'd7:    gcol = 3'd1;
            5'd8, 5'd9, 5'd10:   gcol = 3'd2;
            5'd11, 5'd12, 5'd13: gcol = 3'd3;
            5'd14, 5'd15, 5'd16: gcol = 3'd4;
            default: begin gcol = 3'd0; gvalid = 1'b0; end
        endcase
    end
    wire glyph_bit = gvalid & frow[3'd4 - gcol];

    // ---- 16x16 status icon ----
    wire [3:0] ix   = i_pxc[3:0];
    wire [6:0] ysub = i_ycnt - ICON_TOP;
    wire [3:0] iy   = ysub[3:0];
    wire [2:0] dy   = iy[3] ? iy[2:0] : ~iy[2:0];                // rows from the middle
    wire tri_on = (ix >= 4'd3) && (({1'b0, ix} + {2'b00, dy}) <= 5'd13);
    wire bar_on = (((ix >= 4'd3) && (ix <= 4'd5)) || ((ix >= 4'd10) && (ix <= 4'd12))) &&
                  (iy >= 4'd2) && (iy <= 4'd13);
    wire sq_on  = (ix >= 4'd3) && (ix <= 4'd12) && (iy >= 4'd3) && (iy <= 4'd12);

    wire icon_region = (i_cx == ICON_CELL) && (i_pxc < 5'd16) &&
                       (i_ycnt >= ICON_TOP) && (i_ycnt < ICON_TOP + 7'd16);
    wire icon_shape  = (i_mode == 2'd1) ? tri_on : (i_mode == 2'd2) ? bar_on : sq_on;

    wire icon_lit = (i_kind == 2'd2) & icon_region & icon_shape;
    wire text_lit = (i_kind == 2'd1) & glyph_bit;
    wire [15:0] icon_color = (i_mode == 2'd1) ? COL_RUNNING :
                             (i_mode == 2'd2) ? COL_PAUSED  : COL_RESET;

    assign o_color = icon_lit ? icon_color : text_lit ? COL_TEXT : COL_BG;
endmodule
