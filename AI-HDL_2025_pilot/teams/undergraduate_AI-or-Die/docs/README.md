# AI-HDL-Team-AI-or-Die-

## **Digital Watch Project**  

### **Project Overview**  
This project implements a **digital smartwatch** using Verilog for the **Basys 3 FPGA** board. The system includes:  
- A **real-time clock with timezone support**  
- A **stopwatch**  
- An **alarm system**  
- **PIN authentication** for security  
- **7-segment display multiplexing**
- **12 to 24 hour time conversion** 

### **Repository Contents**  
The repository contains the following files:  

#### **Verilog Source Files**
- `top_level.v` – The main module integrating all components.  
- `clock_divider.v` – Divides the 100 MHz clock for timing control.  
- `debouncer.v` – Debounces button inputs for stable state transitions.  
- `pin_auth.v` – Manages user authentication using a 4-digit PIN.  
- `stopwatch.v` – Implements a simple stopwatch with start, stop, and reset functionality.  
- `clock_timezone.v` – Handles real-time clock updates and timezone adjustments.  
- `convert_12_to_24.v` – Converts 12-hour time to 24-hour format.  
- `alarm.v` – Allows users to set an alarm and triggers an LED when the time matches.  
- `SevenSegmentDisplay.v` – Controls the 7-segment display for numerical output.  

#### **Testbenches**
- `top_level_tb_2.v` – Tests the **full system** including authentication, clock, stopwatch, and alarm.  
---

## **AI-Generated Components**
All files in this repository were created and modified with **AI assistance**. All file contents are the result of AI prompt engineering except for a handful of lines where
manual edits were made. These lines are identified in the files with the comment "***Manually edited" inserted to the right side of the line.

The AI-generated content was **reviewed and refined** to ensure correctness, efficiency, and maintainability.  

---

## **How to Run the Project**
1. Load the **Verilog files** into **Vivado Design Suite 2022**.  
2. Simulate using the **provided testbenches**.  
3. Synthesize and implement on the **Basys 3 FPGA board**.  

For testing, modify `top_level_tb.v` to adjust test scenarios and run simulations in Vivado.  

---

## **Acknowledgments**  
This project was developed using **Vivado 2022**, with **AI assistance** for structuring and debugging Verilog components.  

For any questions, contact: **Member A at [email]**  
