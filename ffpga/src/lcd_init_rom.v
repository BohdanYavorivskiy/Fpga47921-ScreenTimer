// ST7735S power-up sequence for the Pmod LCD 0.96" (160x80 IPS panel).
// Byte order follows the vendor reference driver for this module; the register
// writes before COLMOD set up frame rate, power and gamma and the panel stays
// blank without them.
//
// Each entry is decoded into control flags plus one byte:
//   o_end   - stop fetching and start painting pixels
//   o_delay - wait instead of sending (the byte is ignored)
//   o_dc    - 0 = command, 1 = parameter
//
// Three blocks end with RAMWR (see the IDX_* parameters in lcd_ctrl):
//   index  0 : full init, then opens the whole screen for the black clear frame
//   index 90 : text band, screen rows 29..49 - repainted continuously
//   index 102: icon band, screen rows 0..17  - repainted only when the mode changes
module lcd_init_rom(
    input      [6:0] i_idx,
    output           o_end,
    output           o_delay,
    output           o_dc,
    output     [7:0] o_byte
);
    reg [10:0] w;                          // {end, delay, dc, byte}

    assign o_end   = w[10];
    assign o_delay = w[9];
    assign o_dc    = w[8];
    assign o_byte  = w[7:0];

    always @(*) begin
        case (i_idx)
            7'd0: w = {3'b000, 8'h11};
            7'd1: w = {3'b010, 8'h00};
            7'd2: w = {3'b000, 8'hB1};
            7'd3: w = {3'b001, 8'h05};
            7'd4: w = {3'b001, 8'h3C};
            7'd5: w = {3'b001, 8'h3C};
            7'd6: w = {3'b000, 8'hB2};
            7'd7: w = {3'b001, 8'h05};
            7'd8: w = {3'b001, 8'h3C};
            7'd9: w = {3'b001, 8'h3C};
            7'd10: w = {3'b000, 8'hB3};
            7'd11: w = {3'b001, 8'h05};
            7'd12: w = {3'b001, 8'h3C};
            7'd13: w = {3'b001, 8'h3C};
            7'd14: w = {3'b001, 8'h05};
            7'd15: w = {3'b001, 8'h3C};
            7'd16: w = {3'b001, 8'h3C};
            7'd17: w = {3'b000, 8'hB4};
            7'd18: w = {3'b001, 8'h03};
            7'd19: w = {3'b000, 8'hC0};
            7'd20: w = {3'b001, 8'hAB};
            7'd21: w = {3'b001, 8'h0B};
            7'd22: w = {3'b001, 8'h04};
            7'd23: w = {3'b000, 8'hC1};
            7'd24: w = {3'b001, 8'hC5};
            7'd25: w = {3'b000, 8'hC2};
            7'd26: w = {3'b001, 8'h0D};
            7'd27: w = {3'b001, 8'h00};
            7'd28: w = {3'b000, 8'hC3};
            7'd29: w = {3'b001, 8'h8D};
            7'd30: w = {3'b001, 8'h6A};
            7'd31: w = {3'b000, 8'hC4};
            7'd32: w = {3'b001, 8'h8D};
            7'd33: w = {3'b001, 8'hEE};
            7'd34: w = {3'b000, 8'hC5};
            7'd35: w = {3'b001, 8'h0F};
            7'd36: w = {3'b000, 8'hE0};
            7'd37: w = {3'b001, 8'h07};
            7'd38: w = {3'b001, 8'h0E};
            7'd39: w = {3'b001, 8'h08};
            7'd40: w = {3'b001, 8'h07};
            7'd41: w = {3'b001, 8'h10};
            7'd42: w = {3'b001, 8'h07};
            7'd43: w = {3'b001, 8'h02};
            7'd44: w = {3'b001, 8'h07};
            7'd45: w = {3'b001, 8'h09};
            7'd46: w = {3'b001, 8'h0F};
            7'd47: w = {3'b001, 8'h25};
            7'd48: w = {3'b001, 8'h36};
            7'd49: w = {3'b001, 8'h00};
            7'd50: w = {3'b001, 8'h08};
            7'd51: w = {3'b001, 8'h04};
            7'd52: w = {3'b001, 8'h10};
            7'd53: w = {3'b000, 8'hE1};
            7'd54: w = {3'b001, 8'h0A};
            7'd55: w = {3'b001, 8'h0D};
            7'd56: w = {3'b001, 8'h08};
            7'd57: w = {3'b001, 8'h07};
            7'd58: w = {3'b001, 8'h0F};
            7'd59: w = {3'b001, 8'h07};
            7'd60: w = {3'b001, 8'h02};
            7'd61: w = {3'b001, 8'h07};
            7'd62: w = {3'b001, 8'h09};
            7'd63: w = {3'b001, 8'h0F};
            7'd64: w = {3'b001, 8'h25};
            7'd65: w = {3'b001, 8'h35};
            7'd66: w = {3'b001, 8'h00};
            7'd67: w = {3'b001, 8'h09};
            7'd68: w = {3'b001, 8'h04};
            7'd69: w = {3'b001, 8'h10};
            7'd70: w = {3'b000, 8'hFC};
            7'd71: w = {3'b001, 8'h80};
            7'd72: w = {3'b000, 8'h3A};
            7'd73: w = {3'b001, 8'h05};
            7'd74: w = {3'b000, 8'h36};
            7'd75: w = {3'b001, 8'h78};
            7'd76: w = {3'b000, 8'h21};
            7'd77: w = {3'b000, 8'h29};
            7'd78: w = {3'b000, 8'h2A};
            7'd79: w = {3'b001, 8'h00};
            7'd80: w = {3'b001, 8'h01};
            7'd81: w = {3'b001, 8'h00};
            7'd82: w = {3'b001, 8'hA0};
            7'd83: w = {3'b000, 8'h2B};
            7'd84: w = {3'b001, 8'h00};
            7'd85: w = {3'b001, 8'h1A};
            7'd86: w = {3'b001, 8'h00};
            7'd87: w = {3'b001, 8'h69};
            7'd88: w = {3'b000, 8'h2C};
            7'd89: w = {3'b100, 8'h00};
            7'd90: w = {3'b000, 8'h2A};
            7'd91: w = {3'b001, 8'h00};
            7'd92: w = {3'b001, 8'h01};
            7'd93: w = {3'b001, 8'h00};
            7'd94: w = {3'b001, 8'hA0};
            7'd95: w = {3'b000, 8'h2B};
            7'd96: w = {3'b001, 8'h00};
            7'd97: w = {3'b001, 8'h37};
            7'd98: w = {3'b001, 8'h00};
            7'd99: w = {3'b001, 8'h4B};
            7'd100: w = {3'b000, 8'h2C};
            7'd101: w = {3'b100, 8'h00};
            7'd102: w = {3'b000, 8'h2A};
            7'd103: w = {3'b001, 8'h00};
            7'd104: w = {3'b001, 8'h01};
            7'd105: w = {3'b001, 8'h00};
            7'd106: w = {3'b001, 8'hA0};
            7'd107: w = {3'b000, 8'h2B};
            7'd108: w = {3'b001, 8'h00};
            7'd109: w = {3'b001, 8'h1A};
            7'd110: w = {3'b001, 8'h00};
            7'd111: w = {3'b001, 8'h2B};
            7'd112: w = {3'b000, 8'h2C};
            7'd113: w = {3'b100, 8'h00};
            default: w = {3'b100, 8'h00};
        endcase
    end
endmodule
