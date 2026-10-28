// 5x7 glyph table: digits 0-9 plus ':' (code 10) and '.' (code 11).
// One row per lookup, bit 4 is the leftmost column.
module font5x7(
    input      [3:0] i_ch,                 // character code 0..11
    input      [2:0] i_row,                // glyph row 0..6
    output reg [4:0] o_bits
);
    always @(*) begin
        case ({i_ch, i_row})
            {4'd0, 3'd0}: o_bits = 5'h0E;
            {4'd0, 3'd1}: o_bits = 5'h11;
            {4'd0, 3'd2}: o_bits = 5'h13;
            {4'd0, 3'd3}: o_bits = 5'h15;
            {4'd0, 3'd4}: o_bits = 5'h19;
            {4'd0, 3'd5}: o_bits = 5'h11;
            {4'd0, 3'd6}: o_bits = 5'h0E;
            {4'd1, 3'd0}: o_bits = 5'h04;
            {4'd1, 3'd1}: o_bits = 5'h0C;
            {4'd1, 3'd2}: o_bits = 5'h04;
            {4'd1, 3'd3}: o_bits = 5'h04;
            {4'd1, 3'd4}: o_bits = 5'h04;
            {4'd1, 3'd5}: o_bits = 5'h04;
            {4'd1, 3'd6}: o_bits = 5'h0E;
            {4'd2, 3'd0}: o_bits = 5'h0E;
            {4'd2, 3'd1}: o_bits = 5'h11;
            {4'd2, 3'd2}: o_bits = 5'h01;
            {4'd2, 3'd3}: o_bits = 5'h02;
            {4'd2, 3'd4}: o_bits = 5'h04;
            {4'd2, 3'd5}: o_bits = 5'h08;
            {4'd2, 3'd6}: o_bits = 5'h1F;
            {4'd3, 3'd0}: o_bits = 5'h1F;
            {4'd3, 3'd1}: o_bits = 5'h02;
            {4'd3, 3'd2}: o_bits = 5'h04;
            {4'd3, 3'd3}: o_bits = 5'h02;
            {4'd3, 3'd4}: o_bits = 5'h01;
            {4'd3, 3'd5}: o_bits = 5'h11;
            {4'd3, 3'd6}: o_bits = 5'h0E;
            {4'd4, 3'd0}: o_bits = 5'h02;
            {4'd4, 3'd1}: o_bits = 5'h06;
            {4'd4, 3'd2}: o_bits = 5'h0A;
            {4'd4, 3'd3}: o_bits = 5'h12;
            {4'd4, 3'd4}: o_bits = 5'h1F;
            {4'd4, 3'd5}: o_bits = 5'h02;
            {4'd4, 3'd6}: o_bits = 5'h02;
            {4'd5, 3'd0}: o_bits = 5'h1F;
            {4'd5, 3'd1}: o_bits = 5'h10;
            {4'd5, 3'd2}: o_bits = 5'h1E;
            {4'd5, 3'd3}: o_bits = 5'h01;
            {4'd5, 3'd4}: o_bits = 5'h01;
            {4'd5, 3'd5}: o_bits = 5'h11;
            {4'd5, 3'd6}: o_bits = 5'h0E;
            {4'd6, 3'd0}: o_bits = 5'h06;
            {4'd6, 3'd1}: o_bits = 5'h08;
            {4'd6, 3'd2}: o_bits = 5'h10;
            {4'd6, 3'd3}: o_bits = 5'h1E;
            {4'd6, 3'd4}: o_bits = 5'h11;
            {4'd6, 3'd5}: o_bits = 5'h11;
            {4'd6, 3'd6}: o_bits = 5'h0E;
            {4'd7, 3'd0}: o_bits = 5'h1F;
            {4'd7, 3'd1}: o_bits = 5'h01;
            {4'd7, 3'd2}: o_bits = 5'h02;
            {4'd7, 3'd3}: o_bits = 5'h04;
            {4'd7, 3'd4}: o_bits = 5'h08;
            {4'd7, 3'd5}: o_bits = 5'h08;
            {4'd7, 3'd6}: o_bits = 5'h08;
            {4'd8, 3'd0}: o_bits = 5'h0E;
            {4'd8, 3'd1}: o_bits = 5'h11;
            {4'd8, 3'd2}: o_bits = 5'h11;
            {4'd8, 3'd3}: o_bits = 5'h0E;
            {4'd8, 3'd4}: o_bits = 5'h11;
            {4'd8, 3'd5}: o_bits = 5'h11;
            {4'd8, 3'd6}: o_bits = 5'h0E;
            {4'd9, 3'd0}: o_bits = 5'h0E;
            {4'd9, 3'd1}: o_bits = 5'h11;
            {4'd9, 3'd2}: o_bits = 5'h11;
            {4'd9, 3'd3}: o_bits = 5'h0F;
            {4'd9, 3'd4}: o_bits = 5'h01;
            {4'd9, 3'd5}: o_bits = 5'h02;
            {4'd9, 3'd6}: o_bits = 5'h0C;
            {4'd10, 3'd0}: o_bits = 5'h00;
            {4'd10, 3'd1}: o_bits = 5'h04;
            {4'd10, 3'd2}: o_bits = 5'h04;
            {4'd10, 3'd3}: o_bits = 5'h00;
            {4'd10, 3'd4}: o_bits = 5'h04;
            {4'd10, 3'd5}: o_bits = 5'h04;
            {4'd10, 3'd6}: o_bits = 5'h00;
            {4'd11, 3'd0}: o_bits = 5'h00;
            {4'd11, 3'd1}: o_bits = 5'h00;
            {4'd11, 3'd2}: o_bits = 5'h00;
            {4'd11, 3'd3}: o_bits = 5'h00;
            {4'd11, 3'd4}: o_bits = 5'h00;
            {4'd11, 3'd5}: o_bits = 5'h04;
            {4'd11, 3'd6}: o_bits = 5'h04;
            default: o_bits = 5'h00;
        endcase
    end
endmodule
