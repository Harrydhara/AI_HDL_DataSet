## 🔷**Power Optimization**🔷
Since I am running out of time, I just try with the top-level module.
### 👤User ### 
Given the top-level module below, please optimize the power consumption. 

### ⚡️Assistant
To optimize this module for power, the focus will be on reducing unnecessary switching activity and minimizing resource utilization where possible. Here are some suggestions:

### 1. **Clock Gating**:
   - **Clock gating** is one of the most effective techniques for power optimization in digital designs. In the provided design, the clock is being used by several modules, including the clock divider, button debouncers, stopwatch, digital clock, alarm, and display. Since some of these modules might not be active all the time (depending on the state machine), we can gate off the clocks to these modules when they are not in use.

   **Implementation**:
   - **Clock Gating for Stopwatch**: The stopwatch should only be active when it is in the `STOPWATCH_STATE`. This will reduce unnecessary toggling when the system is in other states.
   - **Clock Gating for Alarm**: Similarly, the alarm module should only be active when it's in the `ALARM_STATE`. 
   - **Clock Gating for Display**: The 7-segment display might not need to update constantly when the system is in certain states (for example, in `CONVERT_STATE` or `STOPWATCH_STATE` if no one is actively looking at it).
   - **Clock Gating for Button Debouncers**: Button debouncers can be disabled when the buttons are not being used to reduce power.

   **Example Implementation**:
   ```verilog
   wire gated_clk;  // Gated clock signal

   // Clock gating logic
   assign gated_clk = (current_state == CLOCK_STATE || current_state == STOPWATCH_STATE) ? clk_div : 1'b0;

   // Use gated clock for modules that can be turned off
   clock_divider clock_div_inst (
       .clk_in(clk),
       .rst(rst),
       .clk_out(clk_div)
   );

   buttonDebouncer button0_debouncer (
       .clk(gated_clk),  // Use gated clock here
       .rst(rst),
       .button_in(button0),
       .button_out(button0_debounced)
   );

   // Repeat for other modules where necessary
   ```

### 2. **Reducing Resource Usage in State Machine**:
   - **State Transitions**: The state machine uses the `button2_debounced` to transition between states. However, instead of constantly checking this condition in each state, consider adding additional checks to minimize unnecessary transitions, or reduce the frequency of transitions.
   - **State Retention**: Avoid redundant state transitions by ensuring that the state does not change unless explicitly required. This could potentially involve adding a check to see if the state already matches the desired state.

### 3. **Minimizing Display Activity**:
   - In your display logic, you're updating the display based on the state. If the display isn't essential in certain states (e.g., `ALARM_STATE`), consider turning it off or reducing its update frequency. Displaying constant information like the stopwatch or digital clock might be unnecessary if no user interaction is taking place.

   **Example**:
   ```verilog
   always @(*) begin
       case (current_state)
           CLOCK_STATE, CONVERT_STATE: display_value = {hours_24, minutes_24};
           STOPWATCH_STATE: display_value = stopwatch_value;
           ALARM_STATE: display_value = alarm_time;
           default: display_value = 16'h0000;  // Turn off display when not needed
       endcase
   end
   ```

### 4. **Voltage Scaling**:
   - If your target platform allows, consider lowering the voltage supply to the FPGA, which can directly reduce power consumption. This might involve modifying the operating frequency to balance performance and power.

### 5. **Optimizing Internal Registers and Wires**:
   - Instead of declaring unused wires or registers, ensure that all signals are essential. For example, the `adjusted_hours` and `is_pm` signals are used in multiple modules. Consolidating or removing unnecessary intermediate signals can help lower the resource usage and thus save power.

### 6. **Reducing Active Logic**:
   - The module should avoid triggering logic for every clock cycle if it's not needed. For instance, in the digital clock section, if the `set_time_enable` is not active, you can deactivate the relevant logic that updates the time.

   **Example**:
   ```verilog
   digital_clock digital_clock_inst (
       .clk_div(clk_div), 
       .reset(rst), 
       .set_time_enable(set_time_enable),  // Only enable when needed
       .set_hours({2'b00, set_hours}),
       .set_minutes(set_minutes),
       .set_seconds(6'b000000),
       .timezone_select(timezone_select),
       .hours(hours),
       .minutes(minutes),
       .seconds(seconds),
       .adjusted_hours(adjusted_hours),
       .is_pm(is_pm)
   );
   ```

### 7. **Deactivating Alarm Module**:
   - The alarm module should only be active when required (i.e., in `ALARM_STATE`). By default, ensure that the alarm system is inactive when not in use.

### 8. **Optimize Power Consumption of Clock Dividers**:
   - In high-frequency designs, the clock divider consumes considerable power. If your system does not need a very high clock frequency for certain operations, consider using a slower clock divider. This will reduce the toggling frequency of the registers that rely on the clock.

### 9. **Use of FSM for State Control**:
   - Ensure that the FSM controlling the states (e.g., `CLOCK_STATE`, `STOPWATCH_STATE`, `ALARM_STATE`, etc.) is minimal, as each additional state machine transition or logic computation adds to the power consumption. You can consider rethinking how you manage transitions to avoid redundant logic.

By implementing these changes, you can ensure that the power consumption is reduced while maintaining the functionality of the system.

### 👤User ### 
Which one of these can I implement safely?

### ⚡️Assistant
Let's break down the power optimization techniques and evaluate which ones can be implemented safely without affecting the core functionality of your system:

### 1. **Clock Gating**:
   - **Safe to Implement**: Yes.
     - **Reason**: Clock gating is a standard method to reduce power consumption, and in your design, it is safe to gate clocks to modules that are not actively in use (e.g., turning off the clock to the stopwatch when it's not in `STOPWATCH_STATE`).
     - **Implementation**: Clock gating for modules like the stopwatch, alarm, and 7-segment display is straightforward and can be done safely by controlling the clock input to these modules using simple logic based on the state of the system.

### 2. **Reducing Resource Usage in State Machine**:
   - **Safe to Implement**: Yes, with caution.
     - **Reason**: This primarily involves ensuring that the state transitions are meaningful and not overly frequent. You can reduce redundant transitions and avoid unnecessary logic evaluation, but ensure the state machine still behaves as expected.
     - **Implementation**: You can optimize the state transitions by ensuring that states only change when necessary. This would generally not cause problems unless you incorrectly manage state transitions.

### 3. **Minimizing Display Activity**:
   - **Safe to Implement**: Yes.
     - **Reason**: The display activity can be reduced based on the current state. For example, in the `ALARM_STATE`, the display might not need to update as frequently as in the `CLOCK_STATE` or `STOPWATCH_STATE`. This change should not affect the functionality as long as you display relevant information only when needed.
     - **Implementation**: A simple `always` block for selecting what to display based on the current state, and turning off the display when it's not needed, will work without causing issues.

### 4. **Voltage Scaling**:
   - **Safe to Implement**: No, unless explicitly supported by your platform (e.g., FPGA with voltage scaling capabilities).
     - **Reason**: Voltage scaling requires hardware support for reducing the voltage without causing instability. If your platform supports voltage scaling, you could use it, but in the context of standard FPGA designs (such as the Basys 3 board), this might not be feasible without explicit support for voltage reduction and stability checks.
     - **Implementation**: Not recommended unless you confirm that the FPGA supports this feature.

### 5. **Optimizing Internal Registers and Wires**:
   - **Safe to Implement**: Yes.
     - **Reason**: Optimizing internal registers and wires by removing unused ones or consolidating them can reduce logic complexity and save resources, leading to lower power consumption. This will not affect the functionality if done correctly.
     - **Implementation**: Ensure that only necessary signals are kept and used throughout the design. For example, if `adjusted_hours` is not needed in certain states, it could be safely removed or not assigned values in those states.

### 6. **Reducing Active Logic**:
   - **Safe to Implement**: Yes.
     - **Reason**: Deactivating logic in certain states (e.g., disabling certain modules when `set_time_enable` is not active) can save power. It ensures that only the required modules are active, avoiding unnecessary logic operations.
     - **Implementation**: This is a safe optimization and involves enabling/disabling parts of the design based on the state, without affecting the core functionality.

### 7. **Deactivating Alarm Module**:
   - **Safe to Implement**: Yes.
     - **Reason**: The alarm module should only be active in the `ALARM_STATE`. Turning off the alarm logic in other states will save power. It’s safe to gate the clock to this module or disable the alarm logic entirely when it’s not in use.
     - **Implementation**: Implement clock gating or control the alarm module's enable signals based on the current state. This will reduce unnecessary power consumption when the alarm is not needed.

### 8. **Optimize Power Consumption of Clock Dividers**:
   - **Safe to Implement**: Yes, with caution.
     - **Reason**: The clock divider should be configured to provide the correct clock frequency for each module. Reducing the clock frequency of the clock divider can save power, but make sure the resulting frequency still meets the timing requirements of the modules (e.g., for debouncing, timekeeping, or display).
     - **Implementation**: If the clock frequency is not critical for your application, you could safely lower it. However, make sure to check the timing requirements before making significant reductions.

### 9. **Use of FSM for State Control**:
   - **Safe to Implement**: Yes.
     - **Reason**: Ensuring that state transitions are necessary and only happen when required will prevent unnecessary logic from toggling. This can be safely implemented without affecting functionality.
     - **Implementation**: This is part of the normal FSM optimization and would not cause issues as long as it’s done correctly. Just ensure that your state transitions still lead to the correct state sequence.

---

### Summary of Safe Optimizations:
- **Clock Gating** (safe and effective for reducing power when modules are idle)
- **Reducing Resource Usage in State Machine** (safe, but ensure state machine functionality is maintained)
- **Minimizing Display Activity** (safe, and reduces unnecessary display updates)
- **Optimizing Internal Registers and Wires** (safe, simplifies design and reduces resource usage)
- **Reducing Active Logic** (safe, deactivate non-essential logic in certain states)
- **Deactivating Alarm Module** (safe, turn off alarm logic when not needed)
- **Optimize Power Consumption of Clock Dividers** (safe, but ensure timing requirements are met)
- **Use of FSM for State Control** (safe, improves state machine efficiency)

### **Unsafe or Platform-Dependent Optimizations**:
- **Voltage Scaling** (not feasible unless supported by the platform)

In summary, the first 7 optimizations are safe and can be implemented to reduce power consumption without affecting the core functionality. You should test and verify after implementing each optimization to ensure that the system still functions as intended. The voltage scaling approach is platform-dependent and is generally not feasible in standard FPGA designs without specific support.

### 👤User ### 
Please implement those that are safe.

### ⚡️Assistant
Let's implement the **safe optimizations** identified earlier for your design. We will focus on clock gating, reducing display activity, optimizing internal registers and wires, and deactivating modules when not in use.

### 1. **Clock Gating**:

We will gate the clock to specific modules when they are not needed. This can be done by controlling the clock input to the modules based on the current state of the system. For example, we'll gate the clock for the stopwatch, alarm, and display modules.

#### Clock Gating Logic:
```verilog
// Define the gated clock
wire gated_clk;

// Gating logic: Only keep the clock for modules that need it
assign gated_clk = (current_state == CLOCK_STATE || current_state == STOPWATCH_STATE) ? clk_div : 1'b0;
```

Now, use `gated_clk` for the modules instead of `clk_div` directly:

```verilog
// Use gated clock for button debouncers
buttonDebouncer button0_debouncer (
    .clk(gated_clk),  // Use gated clock here
    .rst(rst),
    .button_in(button0),
    .button_out(button0_debounced)
);

buttonDebouncer button1_debouncer (
    .clk(gated_clk),
    .rst(rst),
    .button_in(button1),
    .button_out(button1_debounced)
);

buttonDebouncer button2_debouncer (
    .clk(gated_clk),
    .rst(rst),
    .button_in(button2),
    .button_out(button2_debounced)
);

// Use gated clock for the stopwatch
stopwatch stopwatch_inst (
    .clk(gated_clk),               // Use the gated clock here
    .rst(rst),
    .start_stop(button0_debounced),
    .reset_button(button1_debounced),
    .time_out(stopwatch_value)
);

// Use gated clock for the 7-segment display
seven_segment_display seg_display (
    .clk(gated_clk),               // Use gated clock here
    .rst(rst),
    .number(display_value),        // Display value from the state machine
    .seg(seg),
    .an(an)
);
```

### 2. **Minimizing Display Activity**:

We will minimize the display activity by only updating it when necessary, depending on the current state.

```verilog
// Multiplexer for display value based on the state
always @(*) begin
    case (current_state)
        CLOCK_STATE: display_value = {hours_24, minutes_24};
        STOPWATCH_STATE: display_value = stopwatch_value;
        ALARM_STATE: display_value = alarm_time;
        CONVERT_STATE: display_value = {adjusted_hours, minutes};
        default: display_value = 16'h0000;  // Turn off display when not needed
    endcase
end
```

### 3. **Optimizing Internal Registers and Wires**:

We'll clean up unused signals to ensure we're not using extra registers or wires. For example, ensure that `adjusted_hours` and `is_pm` are only used when necessary.

In the code snippet below, we won't assign `adjusted_hours` or `is_pm` in the `STOPWATCH_STATE` or `ALARM_STATE` since those are only relevant in `CLOCK_STATE` and `CONVERT_STATE`.

```verilog
// Only assign adjusted hours and is_pm in the appropriate states
always @(*) begin
    case (current_state)
        CLOCK_STATE: begin
            // Use adjusted_hours and is_pm only in CLOCK_STATE
            display_value = {adjusted_hours, minutes};  
            // Other logic
        end
        STOPWATCH_STATE: begin
            // Only display stopwatch value here
            display_value = stopwatch_value;
        end
        ALARM_STATE: begin
            // Handle alarm display and logic
            display_value = alarm_time;
        end
        CONVERT_STATE: begin
            // Display adjusted time in 12-hour format
            display_value = {adjusted_hours, minutes};
        end
        default: display_value = 16'h0000;  // Default: turn off display
    endcase
end
```

### 4. **Deactivating Alarm Module**:

We'll ensure the alarm logic is only active in the `ALARM_STATE`. If it's not in use, we can gate off the clock to the alarm module or disable its logic.

```verilog
// Alarm logic, only active in ALARM_STATE
always @(*) begin
    if (current_state == ALARM_STATE) begin
        // Alarm logic here
        alarm_led = alarm_led_logic;
    end else begin
        // Disable the alarm logic when not needed
        alarm_led = 1'b0;
    end
end
```

Alternatively, you can use clock gating for the alarm module similar to the approach for the stopwatch.

```verilog
// Gated clock for the alarm module
assign gated_alarm_clk = (current_state == ALARM_STATE) ? clk_div : 1'b0;

alarm alarm_inst (
    .clk(gated_alarm_clk),         // Gated clock for alarm
    .reset(rst),
    .select_btn(select_btn),
    .increment_btn(increment_btn),
    .toggle_alarm_btn(toggle_alarm_btn),
    .current_hours(hours),
    .current_minutes(minutes),
    .current_seconds(seconds),
    .alarm_led(alarm_led)
);
```

### 5. **Optimizing Power Consumption of Clock Dividers**:

If your clock divider is not already configured for an optimal clock frequency, ensure that it is divided to the minimum required frequency. A frequency of 1 Hz is often enough for timekeeping and display updates.

```verilog
// For clock division, ensure that the clock frequency is minimal and meets the system requirements
clock_divider clock_div_inst (
    .clk_in(clk),   // High-frequency input clock (e.g., 100 MHz)
    .rst(rst),
    .clk_out(clk_div)  // Divided clock for lower frequency usage
);
```

If a slower clock is needed for specific modules, you can further adjust the divider to achieve lower frequencies.

---

### Full Optimized Code Snippet:

Here is a consolidated view of the changes, focusing on the safe power optimizations:

```verilog
module top_level(
    input wire clk,
    input wire rst,
    input wire button0,
    input wire button1,
    input wire button2,
    input wire [5:0] set_hours,
    input wire [5:0] set_minutes,
    input wire [5:0] set_seconds,
    input wire [4:0] timezone_select,
    output wire [6:0] seg,
    output wire [3:0] an,
    output reg is_pm,
    output reg alarm_led
);

    // State encoding
    localparam CLOCK_STATE = 2'b00;
    localparam STOPWATCH_STATE = 2'b01;
    localparam ALARM_STATE = 2'b10;
    localparam CONVERT_STATE = 2'b11;

    // State registers
    reg [1:0] current_state, next_state;

    // Internal wires
    wire button0_debounced, button1_debounced, button2_debounced;
    wire clk_div, gated_clk, gated_alarm_clk;
    wire [15:0] stopwatch_value;
    wire [5:0] hours, minutes, seconds, hours_24, minutes_24, adjusted_hours;
    wire alarm_time;

    // Clock gating logic
    assign gated_clk = (current_state == CLOCK_STATE || current_state == STOPWATCH_STATE) ? clk_div : 1'b0;
    assign gated_alarm_clk = (current_state == ALARM_STATE) ? clk_div : 1'b0;

    // Clock divider instance
    clock_divider clock_div_inst (
        .clk_in(clk),
        .rst(rst),
        .clk_out(clk_div)
    );

    // Button debouncers
    buttonDebouncer button0_debouncer (.clk(gated_clk), .rst(rst), .button_in(button0), .button_out(button0_debounced));
    buttonDebouncer button1_debouncer (.clk(gated_clk), .rst(rst), .button_in(button1), .button_out(button1_debounced));
    buttonDebouncer button2_debouncer (.clk(gated_clk), .rst(rst), .button_in(button2), .button_out(button2_debounced));

    // Stopwatch
    stopwatch stopwatch_inst (
        .clk(gated_clk), 
        .rst(rst),
        .start_stop(button0_debounced),
        .reset_button(button1_debounced),
        .time_out(stopwatch_value)
    );

    // Digital clock
    digital_clock digital_clock_inst (
        .clk_div(gated_clk), 
        .reset(rst), 
        .set_time_enable(set_time_enable),
        .set_hours({2'b00, set_hours}),
        .set_minutes(set_minutes),
        .set_seconds(set_seconds),
        .timezone_select(timezone_select),
        .hours(hours),
        .minutes(minutes),
        .seconds(seconds),
        .adjusted_hours(adjusted_hours),
        .is_pm(is_pm)
    );

    // 12-hour to 24-hour conversion
    convert_12_to_24 convert_dut (
        .hours_12(adjusted_hours),
        .minutes_12(minutes),
        .is_pm(is_pm),
        .hours_24(hours_24),
        .minutes_24(minutes_24)
    );

    // Alarm
    alarm alarm_inst (
        .clk(gated_alarm_clk),
        .reset(rst),
        .select_btn(select_btn),
        .increment_btn(increment_btn),
        .toggle_alarm_btn(toggle_alarm_btn),
        .current_hours(hours),
        .current_minutes(minutes),
        .current_seconds(seconds),
        .alarm_led(alarm_led)
    );

    // State machine
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            current_state <= CLOCK_STATE;
        end else if (button2_debounced) begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case (current_state

### 👤User ### 
Which ones are done automatically by Vivado?

### ⚡️Assistant
Vivado, as an FPGA design tool, can automatically handle certain optimizations when you perform synthesis and implementation, especially related to power consumption. However, not all power optimizations are automatic, and some require you to explicitly guide Vivado through certain practices (like clock gating or minimizing unnecessary logic). Here's an overview of the optimizations Vivado typically handles automatically and those that require manual intervention:

### Automatic Power Optimizations by Vivado:
1. **Clock Gating (Simple Cases)**:
   - Vivado can automatically detect opportunities for clock gating and insert logic to gate clocks to unused modules in certain conditions. This happens during synthesis and placement, and Vivado will remove clocks from modules that do not need them (e.g., clock to logic that's disabled by control signals).
   - However, if you use manual control, such as gating the clock explicitly in your RTL code, Vivado will likely optimize the clock routing and logic even more effectively. This explicit approach might be needed for more fine-grained control.

2. **Clock Domain Crossing (CDC) Handling**:
   - Vivado can automatically handle the insertion of synchronizers when signals cross between different clock domains, helping to avoid metastability issues and reducing power consumption by optimizing signal routing between clocks.

3. **Unreachable Logic Removal**:
   - Vivado removes any unused or dead logic during synthesis. If parts of your design are not connected or become redundant based on the inputs, Vivado will automatically eliminate them to save resources and power.

4. **Unused I/O Pin Optimization**:
   - Vivado will remove any unused I/O pins from the design, as they consume unnecessary power.

5. **Resource Sharing (e.g., Multipliers, Adders)**:
   - Vivado can automatically share resources for arithmetic blocks (like multipliers, adders, and other combinational logic). This helps to reduce the overall power consumption by using fewer resources more efficiently.

6. **Power Optimization for Static Logic**:
   - Static logic (e.g., combinational logic that does not change once its inputs are set) is optimized to minimize power usage during synthesis.

7. **Optimization of Register Power**:
   - Vivado will automatically apply techniques to reduce the power consumption of registers, including using the smallest feasible flip-flop types and optimizing the clock trees.

### Manual Power Optimizations (Needs to be Explicit in RTL Code):
1. **Clock Gating (Advanced)**:
   - While Vivado will perform clock gating automatically in simple cases, for more precise control over power consumption, you may need to explicitly insert clock gating logic as you did in the example:
     ```verilog
     assign gated_clk = (current_state == CLOCK_STATE || current_state == STOPWATCH_STATE) ? clk_div : 1'b0;
     ```
     Manual clock gating can result in better power savings, especially in designs with multiple clock domains or state-dependent clock usage.

2. **Reducing Display Activity**:
   - Vivado cannot automatically decide to reduce display updates based on the current state of your system. This is something that should be manually optimized by only updating the display when necessary, as shown in the code for multiplexing the display based on states.

3. **Selective Module Enablement**:
   - Vivado does not automatically deactivate modules when they are not in use. For example, disabling the alarm module when it's not needed requires you to control its clock or power through manual gating or enable signals. This approach can significantly reduce power consumption for modules that are idle.

4. **Voltage Scaling and Power Supply Management**:
   - Vivado does not handle dynamic voltage scaling or power supply control directly within the RTL code. These features are generally managed at the board level (e.g., through a power management unit) or via configuration settings. You'll need to manually ensure that power supplies are properly managed if you're using advanced FPGA boards with multiple voltage domains.

5. **Multiplexer and Logic Optimization**:
   - Vivado can optimize combinational logic automatically, but if you're designing complex multiplexers or control logic, it's often beneficial to manually optimize the logic paths to minimize transitions, which directly impacts power. For example, ensuring that a multiplexer only switches when absolutely necessary will reduce dynamic power.

6. **Reducing Switching Activity (Glitching)**:
   - Vivado can remove unnecessary logic, but it does not automatically optimize the switching activity of the signals (i.e., reducing glitching caused by unnecessary logic transitions). This requires manual RTL optimization, like minimizing signal transitions or controlling how signals are driven to avoid unnecessary activity.

### In Summary:
Vivado handles a lot of optimizations automatically, especially when it comes to clock management, removing unused logic, and sharing resources. However, for more advanced optimizations like explicit clock gating, controlling display activity, and minimizing module activity, you need to explicitly write RTL code that guides Vivado in implementing these optimizations.

By applying the manual optimizations outlined earlier (clock gating, reducing display updates, etc.), you'll get more precise control over power consumption and ensure that Vivado synthesizes the design in the most efficient way possible.

