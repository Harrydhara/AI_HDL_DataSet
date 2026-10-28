// RISC-V C code for PWM demo
// ====================================================
// RISC-V PWM Integration Module
// Connects PWM Generator to RISC-V core
// ====================================================

// ====================================================
// RISC-V PWM Demo Program
// For AI-HDL 2026 League
// ====================================================

#include <stdint.h>

// Memory-mapped PWM registers
#define PWM_BASE_ADDRESS 0x40000000

// Register offsets (word-aligned)
#define PWM_CTRL    ((volatile uint32_t*)(PWM_BASE_ADDRESS + 0x00))
#define PWM_PERIOD  ((volatile uint32_t*)(PWM_BASE_ADDRESS + 0x04))
#define PWM_DUTY0   ((volatile uint32_t*)(PWM_BASE_ADDRESS + 0x08))
#define PWM_DUTY1   ((volatile uint32_t*)(PWM_BASE_ADDRESS + 0x0C))

// Control register bits
#define PWM_ENABLE  0x01
#define PWM_POL0    0x02
#define PWM_POL1    0x04

// Simple delay function
void delay(uint32_t cycles) {
    for (volatile uint32_t i = 0; i < cycles; i++);
}

// Initialize PWM
void pwm_init(uint32_t period) {
    *PWM_PERIOD = period;      // Set period
    *PWM_DUTY0 = 0;            // Start with 0% duty
    *PWM_DUTY1 = 0;            // Start with 0% duty
    *PWM_CTRL = PWM_ENABLE;    // Enable PWM
}

// Set PWM duty cycles
void pwm_set_duty(uint32_t duty0, uint32_t duty1) {
    *PWM_DUTY0 = duty0;
    *PWM_DUTY1 = duty1;
}

// PWM fade demo
void pwm_fade_demo(uint32_t period) {
    uint32_t duty = 0;
    int8_t direction = 1;
    
    while (1) {
        // Update duty cycle
        duty += direction;
        
        // Reverse direction at boundaries
        if (duty >= period) {
            duty = period;
            direction = -1;
        } else if (duty == 0) {
            direction = 1;
        }
        
        // Set PWM outputs
        *PWM_DUTY0 = duty;
        *PWM_DUTY1 = period - duty;  // Opposite phase
        
        // Small delay
        delay(10000);
    }
}

// Main function
int main() {
    uint32_t period = 1000;  // 1000 clock cycles period
    
    // Initialize PWM
    pwm_init(period);
    
    // Example 1: Fixed duty cycles
    *PWM_DUTY0 = period / 4;    // 25% duty
    *PWM_DUTY1 = period * 3 / 4; // 75% duty
    delay(1000000);
    
    // Example 2: Breathing LED effect
    pwm_fade_demo(period);
    
    return 0;
}