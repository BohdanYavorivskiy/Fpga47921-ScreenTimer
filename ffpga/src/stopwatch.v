// Stopwatch core: two buttons and the MM:SS.CC time held as BCD digits.
//   i_btn_start : start / pause      i_btn_stop : stop + reset
//
// The released level of each button is learned during the first BOOT_TICKS
// ticks after power-up, so the board works with buttons wired to either rail.
// Keep both buttons released while the board powers up.
module stopwatch #(
    parameter [17:0] TICK10     = 18'd249999,  // 10 ms at 25 MHz
    parameter [4:0]  BOOT_TICKS = 5'd24        // ~250 ms of level learning
)(
    input            clk,
    input            i_btn_start,
    input            i_btn_stop,
    output     [1:0] o_mode,                   // 0 = reset, 1 = running, 2 = paused
    output           o_running,                // observability: counting now
    output           o_armed,                  // observability: buttons live
    output     [3:0] o_m1,
    output     [3:0] o_m0,
    output     [3:0] o_s1,
    output     [3:0] o_s0,
    output     [3:0] o_c1,
    output     [3:0] o_c0
);
    reg [17:0] tcnt = 18'd0;
    wire       tick = (tcnt == TICK10);
    reg        running = 1'b0;
    reg [1:0]  smode = 2'd0;
    reg [3:0]  c0 = 4'd0, c1 = 4'd0, s0 = 4'd0, s1 = 4'd0, m0 = 4'd0, m1 = 4'd0;

    assign o_mode    = smode;
    assign o_running = running;
    assign o_m1 = m1;
    assign o_m0 = m0;
    assign o_s1 = s1;
    assign o_s0 = s0;
    assign o_c1 = c1;
    assign o_c0 = c0;

    reg b1a = 1'b1, b1b = 1'b1, b2a = 1'b1, b2b = 1'b1;   // synchronizers
    reg st1 = 1'b1, st2 = 1'b1;                           // debounced levels
    reg dd1 = 1'b0, dd2 = 1'b0;                           // debounce state
    reg id1 = 1'b1, id2 = 1'b1;                           // idle (released) levels
    reg armed = 1'b0;
    reg [4:0] boot = 5'd0;
    reg p1_prev = 1'b0, p2_prev = 1'b0;
    wire pressed1 = (st1 != id1);
    wire pressed2 = (st2 != id2);
    wire start_evt = armed & pressed1 & ~p1_prev;         // acts on the press edge
    wire stop_evt  = armed & pressed2 & ~p2_prev;

    assign o_armed = armed;

    always @(posedge clk) begin
        b1a <= i_btn_start; b1b <= b1a;
        b2a <= i_btn_stop;  b2b <= b2a;
        p1_prev <= pressed1;
        p2_prev <= pressed2;

        if (tick) begin                                   // debounce: 2 equal samples (20 ms)
            if (b1b != st1) begin if (dd1) begin st1 <= b1b; dd1 <= 1'b0; end else dd1 <= 1'b1; end
            else dd1 <= 1'b0;
            if (b2b != st2) begin if (dd2) begin st2 <= b2b; dd2 <= 1'b0; end else dd2 <= 1'b1; end
            else dd2 <= 1'b0;
            if (!armed) begin                             // learn the released level
                id1 <= st1; id2 <= st2;
                boot <= boot + 5'd1;
                if (boot == BOOT_TICKS) armed <= 1'b1;
            end
        end

        if (stop_evt) begin
            running <= 1'b0;
            smode <= 2'd0;
            tcnt <= 18'd0;
            c0 <= 4'd0; c1 <= 4'd0; s0 <= 4'd0; s1 <= 4'd0; m0 <= 4'd0; m1 <= 4'd0;
        end else if (start_evt) begin
            running <= ~running;
            smode <= (smode == 2'd1) ? 2'd2 : 2'd1;
            tcnt <= 18'd0;
        end else begin
            tcnt <= tick ? 18'd0 : tcnt + 18'd1;
            if (tick && running) begin                    // BCD carry chain, 10 ms per step
                if (c0 != 4'd9) c0 <= c0 + 4'd1;
                else begin
                    c0 <= 4'd0;
                    if (c1 != 4'd9) c1 <= c1 + 4'd1;
                    else begin
                        c1 <= 4'd0;
                        if (s0 != 4'd9) s0 <= s0 + 4'd1;
                        else begin
                            s0 <= 4'd0;
                            if (s1 != 4'd5) s1 <= s1 + 4'd1;
                            else begin
                                s1 <= 4'd0;
                                if (m0 != 4'd9) m0 <= m0 + 4'd1;
                                else begin
                                    m0 <= 4'd0;
                                    m1 <= (m1 == 4'd9) ? 4'd0 : m1 + 4'd1;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
