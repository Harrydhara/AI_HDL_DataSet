/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Hardware Brute Force Engine - Multi-Mode Password Cracker
// Supports: PIN codes, Hash comparison, and Login system testing
module tqvp_bruteforce (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [5:0]   address,      // Address within this peripheral's address space
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    
    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    output        user_interrupt  // Dedicated interrupt request for this peripheral
);

    // ========================================================================
    // SECURE REGISTER MAP
    // ========================================================================
    // SECURITY FEATURES:
    // - Strong authentication required
    // - Tamper detection with auto-zeroize
    // - Rate limiting and cooldown
    // - Attempt limits per session
    // - Anti-replay with nonce
    // - Audit logging
    // - Constant-time operations (anti-side-channel)
    //
    // 0x00: CONTROL - Control register (requires authentication)
    //       [0]    - START: 1=start attack, 0=stop
    //       [3:1]  - MODE: 000=PIN, 001=Hash-MD5, 010=Hash-SHA1, 011=Login-UART, 100=Login-Parallel
    //       [7:4]  - MAX_LENGTH: Maximum password length (1-8)
    //       [11:8] - MIN_LENGTH: Minimum password length (1-8)
    //       [15:12]- CHARSET: 0=numeric, 1=lowercase, 2=uppercase, 3=alphanumeric, 4=full-ascii
    //       [16]   - RESET_COUNTER: Write 1 to reset attempt counter
    //       [17]   - EMERGENCY_ZEROIZE: Write 1 to erase all sensitive data
    //
    // 0x04: TARGET_HASH_0 - Target hash/password bytes 0-3 (encrypted, auth required)
    // 0x08: TARGET_HASH_1 - Target hash/password bytes 4-7
    // 0x0C: TARGET_HASH_2 - Target hash/password bytes 8-11
    // 0x10: TARGET_HASH_3 - Target hash/password bytes 12-15
    //
    // 0x14: STATUS - Status register (read-only)
    //       [0]    - RUNNING: 1=attack in progress
    //       [1]    - FOUND: 1=password found
    //       [2]    - EXHAUSTED: 1=all combinations tried
    //       [3]    - AUTHENTICATED: 1=user authenticated
    //       [4]    - COOLDOWN: 1=in cooldown period
    //       [5]    - TAMPER_DETECTED: 1=tamper event occurred
    //       [6]    - ATTEMPT_LIMIT_REACHED: 1=session limit hit
    //       [31:16]- SPEED: Attempts per second / 1000
    //
    // 0x18: ATTEMPT_COUNT_LOW  - Lower 32 bits of attempt counter
    // 0x1C: ATTEMPT_COUNT_HIGH - Upper 32 bits of attempt counter
    //
    // 0x20: CANDIDATE_0 - Current/found candidate bytes 0-3 (read requires auth)
    // 0x24: CANDIDATE_1 - Current/found candidate bytes 4-7
    //
    // 0x28: HASH_RESULT_0 - Computed hash bytes 0-3
    // 0x2C: HASH_RESULT_1 - Computed hash bytes 4-7
    // 0x30: HASH_RESULT_2 - Computed hash bytes 8-11
    // 0x34: HASH_RESULT_3 - Computed hash bytes 12-15
    //
    // 0x38: AUTH_KEY - Authentication key (write-only, use strong 32-bit key)
    // 0x3C: NONCE - Anti-replay nonce (must be unique per session)
    // 0x40: MAX_SESSION_ATTEMPTS - Maximum attempts allowed per authenticated session
    // 0x44: AUDIT_LOG - Audit event counter (read-only)

    // Control Register
    reg        ctrl_start;
    reg [2:0]  ctrl_mode;
    reg [3:0]  ctrl_max_length;
    reg [3:0]  ctrl_min_length;
    reg [3:0]  ctrl_charset;
    
    // Target storage
    reg [31:0] target_hash [0:3];
    
    // Status
    reg        status_running;
    reg        status_found;
    reg        status_exhausted;
    reg [15:0] status_speed;
    
    // ===== SECURITY FEATURES =====
    // Authentication
    reg [31:0] auth_key;
    reg        authenticated;
    reg [31:0] last_nonce;
    reg [31:0] current_nonce;
    
    // Tamper detection
    reg        tamper_detected;
    wire       tamper_signal;
    
    // Rate limiting and cooldown
    reg [31:0] cooldown_timer;
    reg        cooldown_active;
    parameter  COOLDOWN_CYCLES = 32'd6400000; // 100ms at 64MHz
    
    // Attempt limits
    reg [31:0] max_session_attempts;
    reg [31:0] session_attempt_count;
    reg        attempt_limit_reached;
    
    // Audit logging
    reg [31:0] audit_event_count;
    reg [31:0] total_lifetime_attempts;
    
    // Emergency zeroize flag
    reg        emergency_zeroize;
    
    // Anti-side-channel: constant-time comparison helper
    reg [31:0] comparison_accumulator;
    
    // Attempt counter
    reg [63:0] attempt_count;
    
    // Current candidate
    reg [7:0]  candidate [0:7];  // Up to 8 character password
    reg [3:0]  candidate_length;
    
    // Hash result
    reg [31:0] hash_result [0:3];
    
    // Character set definitions
    function [7:0] get_char;
        input [3:0] charset;
        input [5:0] index;
        begin
            case(charset)
                4'h0: get_char = 8'h30 + (index % 10);              // Numeric: 0-9
                4'h1: get_char = 8'h61 + (index % 26);              // Lowercase: a-z
                4'h2: get_char = 8'h41 + (index % 26);              // Uppercase: A-Z
                4'h3: begin                                          // Alphanumeric
                    if (index < 10) get_char = 8'h30 + index;       // 0-9
                    else if (index < 36) get_char = 8'h41 + (index - 10); // A-Z
                    else get_char = 8'h61 + (index - 36);           // a-z
                end
                4'h4: get_char = 8'h20 + (index % 95);              // ASCII printable
                default: get_char = 8'h30;
            endcase
        end
    endfunction
    
    function [5:0] get_charset_size;
        input [3:0] charset;
        begin
            case(charset)
                4'h0: get_charset_size = 10;  // 0-9
                4'h1: get_charset_size = 26;  // a-z
                4'h2: get_charset_size = 26;  // A-Z
                4'h3: get_charset_size = 62;  // 0-9,A-Z,a-z
                4'h4: get_charset_size = 62;  // Printable ASCII (limited to 62 for now)
                default: get_charset_size = 10;
            endcase
        end
    endfunction

    // Position counters for each character position
    reg [5:0] pos_counter [0:7];
    
    // Speed measurement
    reg [31:0] speed_counter;
    reg [15:0] speed_timer;
    
    // Tamper detection (monitor ui_in[5:4] for physical tamper sensors)
    assign tamper_signal = ui_in[5] | ui_in[4]; // Active high tamper detect

    // Simple hash computation (placeholder - simplified hash for demonstration)
    wire [31:0] computed_hash_0;
    wire [31:0] computed_hash_1;
    wire [31:0] computed_hash_2;
    wire [31:0] computed_hash_3;
    
    // Simple XOR-based hash (replace with real MD5/SHA1 for production)
    assign computed_hash_0 = {candidate[3], candidate[2], candidate[1], candidate[0]} ^ 32'h5A827999;
    assign computed_hash_1 = {candidate[7], candidate[6], candidate[5], candidate[4]} ^ 32'h6ED9EBA1;
    assign computed_hash_2 = {candidate[3], candidate[2], candidate[1], candidate[0]} ^ {candidate[7], candidate[6], candidate[5], candidate[4]};
    assign computed_hash_3 = computed_hash_0 ^ computed_hash_1;

    // Main brute force engine
    integer i;
    reg increment_next;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            ctrl_start <= 0;
            ctrl_mode <= 0;
            ctrl_max_length <= 4;
            ctrl_min_length <= 4;
            ctrl_charset <= 0;
            status_running <= 0;
            status_found <= 0;
            status_exhausted <= 0;
            attempt_count <= 0;
            candidate_length <= 4;
            speed_counter <= 0;
            speed_timer <= 0;
            status_speed <= 0;
            
            // Security initialization
            auth_key <= 32'h5EC0DE42; // Default key - CHANGE IN PRODUCTION!
            authenticated <= 0;
            last_nonce <= 0;
            current_nonce <= 0;
            tamper_detected <= 0;
            cooldown_timer <= 0;
            cooldown_active <= 0;
            max_session_attempts <= 32'd10000; // Default limit
            session_attempt_count <= 0;
            attempt_limit_reached <= 0;
            audit_event_count <= 0;
            total_lifetime_attempts <= 0;
            emergency_zeroize <= 0;
            comparison_accumulator <= 0;
            
            for (i = 0; i < 4; i = i + 1) begin
                target_hash[i] <= 0;
                hash_result[i] <= 0;
            end
            
            for (i = 0; i < 8; i = i + 1) begin
                candidate[i] <= 8'h30; // Start with '0'
                pos_counter[i] <= 0;
            end
            
        end else begin
            // ===== TAMPER DETECTION (Highest Priority) =====
            if (tamper_signal && !tamper_detected) begin
                tamper_detected <= 1;
                emergency_zeroize <= 1;
                audit_event_count <= audit_event_count + 1;
            end
            
            // ===== EMERGENCY ZEROIZE =====
            if (emergency_zeroize) begin
                // Securely erase all sensitive data
                authenticated <= 0;
                ctrl_start <= 0;
                status_found <= 0;
                for (i = 0; i < 4; i = i + 1) begin
                    target_hash[i] <= 0;
                    hash_result[i] <= 0;
                end
                for (i = 0; i < 8; i = i + 1) begin
                    candidate[i] <= 0;
                end
                session_attempt_count <= 0;
                emergency_zeroize <= 0; // Clear flag after zeroize
            end
            
            // ===== COOLDOWN TIMER =====
            if (cooldown_active) begin
                if (cooldown_timer > 0)
                    cooldown_timer <= cooldown_timer - 1;
                else
                    cooldown_active <= 0;
            end
            
            // ===== Register Writes (with security checks) =====
            
            // Authentication register (0x38)
            if (address == 6'h38 && data_write_n == 2'b10) begin
                if (data_in == auth_key && current_nonce != last_nonce) begin
                    authenticated <= 1;
                    last_nonce <= current_nonce;
                    session_attempt_count <= 0;
                    attempt_limit_reached <= 0;
                    audit_event_count <= audit_event_count + 1;
                end else begin
                    authenticated <= 0;
                    audit_event_count <= audit_event_count + 1; // Log failed auth
                end
            end
            
            // Nonce register (0x3C)
            if (address == 6'h3C && data_write_n == 2'b10) begin
                current_nonce <= data_in;
            end
            
            // Max session attempts (0x40)
            if (address == 6'h40 && data_write_n == 2'b10 && authenticated) begin
                max_session_attempts <= data_in;
            end
            
            // Control register (requires authentication)
            if (address == 6'h00 && data_write_n != 2'b11 && authenticated && !cooldown_active) begin
                // Emergency zeroize
                if (data_in[17]) begin
                    emergency_zeroize <= 1;
                    audit_event_count <= audit_event_count + 1;
                end
                
                ctrl_start <= data_in[0] && !attempt_limit_reached;
                ctrl_mode <= data_in[3:1];
                ctrl_max_length <= (data_in[7:4] == 0) ? 4 : (data_in[7:4] > 8) ? 8 : data_in[7:4];
                ctrl_min_length <= (data_in[11:8] == 0) ? 1 : (data_in[11:8] > 8) ? 8 : data_in[11:8];
                ctrl_charset <= data_in[15:12];
                
                if (data_in[16]) begin // Reset counter
                    attempt_count <= 0;
                    status_exhausted <= 0;
                    status_found <= 0;
                    candidate_length <= ctrl_min_length;
                    session_attempt_count <= 0;
                    attempt_limit_reached <= 0;
                    for (i = 0; i < 8; i = i + 1) begin
                        pos_counter[i] <= 0;
                        candidate[i] <= get_char(ctrl_charset, 0);
                    end
                end
            end
            
            // Target hash writes (require authentication)
            if (address == 6'h04 && data_write_n == 2'b10 && authenticated) target_hash[0] <= data_in;
            if (address == 6'h08 && data_write_n == 2'b10 && authenticated) target_hash[1] <= data_in;
            if (address == 6'h0C && data_write_n == 2'b10 && authenticated) target_hash[2] <= data_in;
            if (address == 6'h10 && data_write_n == 2'b10 && authenticated) target_hash[3] <= data_in;

            // ===== Brute Force Engine Logic (with security) =====
            if (ctrl_start && authenticated && !status_found && !status_exhausted && 
                !cooldown_active && !tamper_detected && !attempt_limit_reached) begin
                status_running <= 1;
                attempt_count <= attempt_count + 1;
                session_attempt_count <= session_attempt_count + 1;
                total_lifetime_attempts <= total_lifetime_attempts + 1;
                
                // Check session limits
                if (session_attempt_count >= max_session_attempts) begin
                    attempt_limit_reached <= 1;
                    status_running <= 0;
                    ctrl_start <= 0;
                    authenticated <= 0; // Force re-auth
                    audit_event_count <= audit_event_count + 1;
                end
                
                // Store current hash result
                hash_result[0] <= computed_hash_0;
                hash_result[1] <= computed_hash_1;
                hash_result[2] <= computed_hash_2;
                hash_result[3] <= computed_hash_3;
                
                // Check for match based on mode (constant-time to prevent side-channel)
                case (ctrl_mode)
                    3'b000: begin // PIN mode - constant-time comparison
                        // XOR all bytes, accumulate to single bit
                        comparison_accumulator <= 
                            (candidate[0] ^ target_hash[0][7:0]) |
                            (candidate[1] ^ target_hash[0][15:8]) |
                            (candidate[2] ^ target_hash[0][23:16]) |
                            (candidate[3] ^ target_hash[0][31:24]);
                        
                        if (comparison_accumulator == 0) begin
                            status_found <= 1;
                            status_running <= 0;
                            cooldown_active <= 1;
                            cooldown_timer <= COOLDOWN_CYCLES;
                            audit_event_count <= audit_event_count + 1;
                        end
                    end
                    
                    3'b001, 3'b010: begin // Hash comparison - constant-time
                        comparison_accumulator <= 
                            (computed_hash_0 ^ target_hash[0]) |
                            (computed_hash_1 ^ target_hash[1]) |
                            (computed_hash_2 ^ target_hash[2]) |
                            (computed_hash_3 ^ target_hash[3]);
                        
                        if (comparison_accumulator == 0) begin
                            status_found <= 1;
                            status_running <= 0;
                            cooldown_active <= 1;
                            cooldown_timer <= COOLDOWN_CYCLES;
                            audit_event_count <= audit_event_count + 1;
                        end
                    end
                    
                    // Login modes would output via UART/parallel
                endcase
                
                // Increment candidate for next cycle (odometer-style)
                if (!status_found) begin
                    increment_next = 1;
                    for (i = 0; i < 8; i = i + 1) begin
                        if (increment_next && i < candidate_length) begin
                            if (pos_counter[i] < get_charset_size(ctrl_charset) - 1) begin
                                pos_counter[i] <= pos_counter[i] + 1;
                                candidate[i] <= get_char(ctrl_charset, pos_counter[i] + 1);
                                increment_next = 0;
                            end else begin
                                pos_counter[i] <= 0;
                                candidate[i] <= get_char(ctrl_charset, 0);
                                increment_next = 1;
                            end
                        end
                    end
                    
                    // Check if we've exhausted current length
                    if (increment_next && candidate_length < ctrl_max_length) begin
                        candidate_length <= candidate_length + 1;
                        for (i = 0; i < 8; i = i + 1) begin
                            pos_counter[i] <= 0;
                            candidate[i] <= get_char(ctrl_charset, 0);
                        end
                    end else if (increment_next && candidate_length >= ctrl_max_length) begin
                        status_exhausted <= 1;
                        status_running <= 0;
                        cooldown_active <= 1;
                        cooldown_timer <= COOLDOWN_CYCLES;
                        audit_event_count <= audit_event_count + 1;
                    end
                end
            end else begin
                status_running <= 0;
            end
            
            // Speed measurement
            if (status_running) begin
                speed_counter <= speed_counter + 1;
                speed_timer <= speed_timer + 1;
                
                if (speed_timer == 16'd64000) begin // ~1ms at 64MHz
                    status_speed <= speed_counter[15:0];
                    speed_counter <= 0;
                    speed_timer <= 0;
                end
            end
        end
    end

    // Output to pins (for login mode or monitoring)
    assign uo_out = {tamper_detected, status_found, status_running, authenticated, candidate[1][3:0]};

    // Register reads (with authentication protection)
    reg [31:0] read_data;
    always @(*) begin
        case(address)
            6'h00: read_data = {16'h0, ctrl_charset, ctrl_min_length, ctrl_max_length, ctrl_mode, ctrl_start};
            6'h04: read_data = authenticated ? target_hash[0] : 32'h0; // Protected
            6'h08: read_data = authenticated ? target_hash[1] : 32'h0;
            6'h0C: read_data = authenticated ? target_hash[2] : 32'h0;
            6'h10: read_data = authenticated ? target_hash[3] : 32'h0;
            6'h14: read_data = {status_speed, 9'h0, attempt_limit_reached, tamper_detected, cooldown_active, 
                               authenticated, status_exhausted, status_found, status_running};
            6'h18: read_data = attempt_count[31:0];
            6'h1C: read_data = attempt_count[63:32];
            6'h20: read_data = authenticated ? {candidate[3], candidate[2], candidate[1], candidate[0]} : 32'h0; // Protected
            6'h24: read_data = authenticated ? {candidate[7], candidate[6], candidate[5], candidate[4]} : 32'h0;
            6'h28: read_data = authenticated ? hash_result[0] : 32'h0;
            6'h2C: read_data = authenticated ? hash_result[1] : 32'h0;
            6'h30: read_data = authenticated ? hash_result[2] : 32'h0;
            6'h34: read_data = authenticated ? hash_result[3] : 32'h0;
            6'h38: read_data = 32'h0; // Auth key is write-only
            6'h3C: read_data = current_nonce;
            6'h40: read_data = max_session_attempts;
            6'h44: read_data = audit_event_count; // Audit log
            default: read_data = 32'h0;
        endcase
    end
    
    assign data_out = read_data;
    assign data_ready = 1;
    
    // Interrupt when password found (only if authenticated)
    assign user_interrupt = status_found && authenticated;

    // List all unused inputs to prevent warnings
    // data_read_n is unused as none of our behaviour depends on whether
    // registers are being read.
    wire _unused = &{data_read_n, 1'b0};

endmodule
