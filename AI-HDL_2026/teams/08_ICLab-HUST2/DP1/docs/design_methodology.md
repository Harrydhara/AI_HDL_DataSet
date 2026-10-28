# Design Methodology

## 1. Design Choice & Rationale

### 1.1 Introduction

Convolutional Neural Networks (CNNs) form the foundation of many computer vi
sion tasks due to their strong capability to exploit local features and spatial correlations in
image data. However, this advantage comes at the cost of high computational complexity
, especially in convolution layers employing 3×3 kernels, which are ubiquitous in most m
odern CNN architectures. 
While GPUs are the dominant solution for accelerating CNN workloads on servers 
and high-performance computing platforms, their high power consumption and substantial 
hardware resource requirements make them unsuitable for low-power embedded systems. 
Consequently, research into dedicated CNN accelerator architectures implemented on 
FPGA or ASIC platforms has become increasingly important, particularly for minimalist 
RISC-V platforms such as TinyQV, which are designed with strict area and energy 
efficiency constraints.  
In this context, this work focuses on the design of a convolution accelerator based 
on the Winograd algorithm, aiming to reduce computational complexity 
while maintaining adequate throughput and acceptable latency.

### 1.2.   Problem Statement 
The deployment of CNN inference on the TinyQV RISC-V core faces several key 
challenges, including:
- High Computational Cost: Standard 3×3 convolution requires 9 
multiplications per output pixel 
- Memory Bandwidth: Continuous data movement between memory and 
compute units
- Energy Consumption: Multiplication operations are power-hungry 
- Real-time Constraints: Edge AI applications demand low-latency 
inference  

### 1.3. Why Winograd Algorithm?

The Winograd minimal filtering algorithm, particularly the F(2×2, 3×3) configuration, is selected due to its ability to significantly reduce the number of multiplications compared to conventional convolution, while preserving numerical accuracy.

Based on research by Lavin & Gray (2016), the Winograd minimal filtering algorithm offers compelling advantages:

---

#### Quantitative Comparison

| Metric | Standard Conv 3×3 | Winograd F(2×2, 3×3) | Improvement |
|--------|-------------------|----------------------|-------------|
| Multiplications | 9 per output | 4 per output | 2.25× reduction |
| Arithmetic Intensity | 9 ops/pixel | 4 ops/pixel | 56% fewer ops |
| Memory Footprint | Moderate | Small (4×4 tiles) | Better cache utilization |
| Latency | 1 output/cycle | 4 outputs/cycle | 4× throughput |

---

#### Key Advantages for TinyQV:

##### Multiplication Reduction

• F(2×2,3×3) requires only 16 multiplications vs. 36 for direct convolution  
• Critical for area-constrained FPGAs with limited DSP blocks  
• Reduces power consumption by ~40–60%

---

##### Small Tile Size (4×4)

• Minimal on-chip buffer requirements (16 registers vs. 64+ for FFT)  
• Fits well with TinyQV's 4-bit nibble architecture  
• Enables efficient pipelining with existing core structure  

---

##### Parallelism

• Computes 4 outputs simultaneously (2×2 tile)  
• Matches well with RISC-V vector extension opportunities  
• Scalable: can process multiple channels in parallel  

---

##### Energy Efficiency

• Fewer memory accesses due to spatial locality  
• Transform operations use only additions/shifts  
• Suitable for battery-powered edge devices  

---

### Comparison with Alternative Approaches:

• Significantly reduces the number of multiplication operations  
• Provides better data reuse capability  
• At the cost of moderately increased control logic complexity, which remains acceptable  

---

#### Compared with FFT-based convolution

• Requires significantly lower memory capacity  
• Does not involve complex arithmetic operations  
• More suitable for small batch sizes and embedded systems  
• Limited kernel size support, primarily 3×3 kernels  

---

#### Compared with Strassen-based algorithms:

• Allows direct mapping to hardware  
• Provides deterministic latency, facilitating verification  
• Does not require complex recursive decomposition  

### 1.4. Summary of Design Choices

The selection of Winograd F(2×2,3×3) for the convolution accelerator on TinyQV represents a well-balanced trade-off among:

• Computational performance  
• Hardware area  
• Power consumption  
• Design complexity  

This design demonstrates strong potential for efficient CNN inference deployment on compact RISC-V platforms, targeting low-power Edge AI systems.

## 2. Winograd Algorithm

The standard algorithm for $F(2,3)$ uses $2 \times 3 = 6$ multiplications. Winograd [16, p. 43] documented the following minimal algorithm:

$$
F(2,3) =
\begin{bmatrix}
d_0 & d_1 & d_2 \\
d_1 & d_2 & d_3
\end{bmatrix}
\begin{bmatrix}
g_0 \\
g_1 \\
g_2
\end{bmatrix}
=
\begin{bmatrix}
m_1 + m_2 + m_3 \\
m_2 - m_3 - m_4
\end{bmatrix}
$$

Where:

$$
m_1 = (d_0 - d_2) g_0
$$

$$
m_2 = (d_1 + d_2) \frac{g_0 + g_1 + g_2}{2}
$$

$$
m_3 = (d_2 - d_1) \frac{g_0 - g_1 + g_2}{2}
$$

$$
m_4 = (d_1 - d_3) g_2
$$

This algorithm uses just 4 multiplications and is therefore minimal by the formula:

$$
\mu(F(2,3)) = 2 + 3 - 1 = 4
$$

It also uses:

- 4 additions involving the data  
- 3 additions and 2 multiplications by a constant involving the filter  
  (the sum $g_0 + g_2$ can be computed just once)  
- 4 additions to reduce the products to the final result  

---

Fast filtering algorithms can be written in matrix form as:

$$
Y = A^T \left[ (Gg) \odot (B^T d) \right]
$$

where $\odot$ indicates element-wise multiplication.

For $F(2,3)$, the matrices are:

$$
B^T =
\begin{bmatrix}
1 & 0 & -1 & 0 \\
0 & 1 & 1 & 0 \\
0 & -1 & 1 & 0 \\
0 & 1 & 0 & -1
\end{bmatrix}
$$

$$
G =
\begin{bmatrix}
1 & 0 & 0 \\
\frac{1}{2} & \frac{1}{2} & \frac{1}{2} \\
\frac{1}{2} & -\frac{1}{2} & \frac{1}{2} \\
0 & 0 & 1
\end{bmatrix}
$$

$$
A^T =
\begin{bmatrix}
1 & 1 & 1 & 0 \\
0 & 1 & -1 & -1
\end{bmatrix}
$$

$$
g = [g_0 \quad g_1 \quad g_2]^T
$$

$$
d = [d_0 \quad d_1 \quad d_2 \quad d_3]^T
$$

---

A minimal 1D algorithm $F(m,r)$ is nested with itself to obtain a minimal 2D algorithm, $F(m \times m, r \times r)$:

$$
Y = A^T \left[ (G g G^T) \odot (B^T d B) \right] A
$$

Where $g$ and $d$ are the filter and the input data tile, $G$ and $B^T$ are their respective transformation matrices and $A^T$ is the inverse transformation matrix. The purpose of the transformations is to have the filter and inputs with the same dimensions so that an element-wise multiplication can be performed. The inverse transformation then brings the output back to the pixel space.

## 3. Overview of the Winograd Convolution Core Architecture 

### 3.1. Module winograd

The `winograd_conv_top` module is the highest-level control block (top-level controller) of the Winograd F(2×2,3×3) convolution accelerator. This module is responsible for orchestrating the entire data processing flow, from receiving the start command to producing the final convolution output.

Specifically, the module controls and coordinates the operation of four main functional sub-blocks:

- Filter Transform  
- Input Transform  
- Element-wise Multiplication & Accumulation  
- Output Transform  

The entire process is managed by a finite state machine (FSM) to ensure correct execution order of the Winograd algorithm and to support multi-channel processing.

#### Input/Output Signal Description Table of winograd_conv_top Module

| Signal            | Bits | I/O | Active Level | Function |
|-------------------|------|-----|-------------|----------|
| clk               | 1    | I   | High        | Clock signal, control logic operates on the rising edge of clk |
| rstn              | 1    | I   | Low         | Reset signal, initializes the system to its default state |
| start             | 1    | I   | High        | Start the transform process |
| num_channels      | 8    | I   | N/A         | Number of input channels |
| filter_idx        | 8    | I   | N/A         | Current filter index |
| data_in           | 32   | I   | N/A         | Input data |
| data_valid        | 1    | I   | N/A         | Valid data_in |
| filter_in         | 32   | I   | N/A         | Input filter |
| filter_valid      | 1    | I   | N/A         | Valid filter_in |
| done              | 1    | O   | High        | Done signal |
| ready             | 1    | O   | High        | Module is ready to receive data |
| data_out          | 32   | O   | N/A         | Convolution result |
| data_out_valid    | 1    | O   | N/A         | Valid data_out |
| current_state     | 4    | O   | N/A         | Current state |

#### State Diagram

The `winograd` module is controlled by a finite state machine (FSM) that manages the full computation flow of the Winograd F(2×2,3×3) accelerator. The FSM consists of the following states:

---

##### STATE_IDLE

- Default reset state.
- `ready = 1`, `done = 0`.
- The module waits for `start = 1`.
- Internal counters such as `filter_count` and `data_count` are initialized.

**Transition:**
- When `start = 1`, the FSM moves to `STATE_FILTER_LOAD`.

---

##### STATE_FILTER_LOAD

- Loads 3×3 filter coefficients.
- Asserts `filter_start`.
- Updates `filter_g_count`.

**Transition condition:**
- When `filter_g_count >= 4'd8` (all 9 filter values loaded),
  the FSM transitions to `STATE_FILTER_TRANS`.

---

##### STATE_FILTER_TRANS

- Waits for completion of the filter transformation.
- Performs the Winograd filter transform:
  
  G · g · Gᵀ

**Transition condition:**
- When `filter_done = 1`, transition to `STATE_INPUT_LOAD`.

---

##### STATE_INPUT_LOAD

- Loads 4×4 input tile data.
- Asserts `input_start`.
- Updates `input_d_count`.

**Transition condition:**
- When `input_d_count >= 4'd15` (all 16 input values loaded),
  the FSM transitions to `STATE_INPUT_TRANS`.

---

##### STATE_INPUT_TRANS

- Waits for completion of the input transformation.
- Performs the Winograd input transform:
  
  Bᵀ · D · B

**Transition condition:**
- When `input_done = 1`, transition to `STATE_ELEM_MULT`.

---

##### STATE_ELEM_MULT

- Performs element-wise multiplication between transformed input (V) and transformed filter (U).
- Accumulates results across all channels.
- Processes 16 Winograd elements per channel.

**Transition condition:**
- When all channels are processed,
  transition to `STATE_OUTPUT_TRANS`.

---

##### STATE_OUTPUT_TRANS

- Loads intermediate matrix M (4×4).
- Asserts `output_start`.
- Updates `output_m_count`.

**Transition condition:**
- When `output_m_count >= 4'd15` (all 16 M elements processed),
  transition to `STATE_OUTPUT_COLLECT`.

---

##### STATE_OUTPUT_COLLECT

- Collects the final 2×2 output tile.
- Sets `data_out_valid = 1`.

**Transition condition:**
- When `output_done = 1` and `y_count == 3`,
  transition to `STATE_DONE`.

---

##### STATE_DONE

- `done = 1`.
- Indicates that the full Winograd convolution operation is completed.

**Transition condition:**
- When `rst = 0` and `start = 0`,
  the FSM returns to `STATE_IDLE`.

---

### 3.2. Module winograd_input_transform

#### Input/Output Signal Description Table of input-transform module

| Signal   | Bits | I/O | Active Level | Function |
|-----------|------|-----|--------------|----------|
| clk       | 1    | I   | High | Clock signal; control logic operates on the rising edge of clk |
| rstn      | 1    | I   | Low  | Reset signal, initializes the module to its default state |
| start     | 1    | I   | High | Starts the transform operation |
| d_in      | 32   | I   | N/A  | 32-bit input data (received sequentially as 16 values) |
| d_count   | 4    | I   | N/A  | Input data position counter (0–15) |
| done      | 1    | O   | High | Done signal |
| v_out     | 32   | O   | N/A  | Output data after the transform |
| v_count   | 4    | O   | N/A  | Output data counter |

---

### Functional Operation Specification

The Winograd input-transform module performs the Winograd transform on the input data of a convolutional layer in a CNN, aiming to optimize 3×3 convolution computation.

The module performs the transform:

$$
V = B^T \times D \times B
$$

Including:

- **D**: 4×4 input matrix (input tile)  
- **Bᵀ**: Input transform matrix (4×4)  
- **B**: Transform matrix (transpose of Bᵀ)  
- **V**: 4×4 transformed output matrix  

---

### Transform Matrix \( B^T \)

$$
B^T =
\begin{bmatrix}
1 & 0 & -1 & 0 \\
0 & 1 & 1 & 0 \\
0 & -1 & 1 & 0 \\
0 & 1 & 0 & -1
\end{bmatrix}
$$

---

#### Active States

##### Stage 1: 
Initialization (IDLE)

- The module waits for the `start = 1` signal.  
- Registers `row`, `col`, and `done` are reset.  

---

##### Stage 2: 
Data Loading (LOAD)

- Receives 16 input values sequentially from `d_in`.  
- Stores the data into `d_matrix[4][4]` according to the `d_count` index.  
- Example: d_count = 5 → stored in d_matrix[1][1]
- Applies the Bᵀ transform matrix to each column of matrix D. 
- Computation for each column is defined as: 



##### Stage 3: 
$\text{Compute } B^\top \times D \quad (\text{COMPUTE\_BTD})$

- row 0: d[0][col] - d[2][col]
- row 1: d[1][col] + d[2][col]
- row 2: -d[1][col] + d[2][col]
- row 3: d[1][col] - d[3][col]
- The results are stored in `temp_matrix[4][4]`.

---

##### Stage 4: 
$\text{Compute } (B^\top \times D) \times B \quad (\text{COMPUTE\_BTDB})$

- Multiplies `temp_matrix` with matrix B (transpose of Bᵀ) along each row.  
- Computation for each row is defined as:
  - col 0: temp[row][0] - temp[row][2]
  - col 1: temp[row][1] + temp[row][2]
  - col 2: -temp[row][1] + temp[row][2]
  - col 3: temp[row][1] - temp[row][3]

- The results are stored in `v_matrix[4][4]`.

---

##### Stage 5: Output Results (OUTPUT)

- Outputs 16 values sequentially from `v_matrix` to `v_out`.  
- `v_count` increments from 0 to 15.  
- Sets `done = 1` when `v_count = 15`.


### 3.3. Module winograd_filter_transform

#### Input/Output Signal Description Table of filter-transform module

| Signal   | Bits | I/O | Active Level | Function |
|----------|------|-----|--------------|----------|
| clk      | 1    | I   | High | Clock signal; control logic operates on the rising edge of clk |
| rstn     | 1    | I   | Low  | Reset signal, initializes the module to its default state |
| start    | 1    | I   | High | Starts the transform operation |
| g_in     | 32   | I   | N/A  | Filter coefficient |
| g_count  | 4    | I   | N/A  | Input data position index |
| done     | 1    | O   | High | Complete flag |
| u_out    | 32   | O   | N/A  | Transformed output data |
| u_count  | 4    | O   | N/A  | Output data counter |

---

#### Functional Operation Specification

The winograd filter-transform module performs the transformation of a 3×3 convolution kernel into the Winograd domain using the following formula:

$$
U = G \cdot g \cdot G^T
$$

Including:

- **g** is the 3×3 convolution kernel  
- **G** is the Winograd transformation matrix for F(2×2,3×3)  
- **U** is the transformed kernel with a size of 4×4 (16 elements)  

The output `u_out` is directly used as the input to the element-wise multiplication block in the accelerator.

#### State Description of winograd_filter_transform Module

The `winograd_filter_transform` module is controlled by a finite state machine (FSM) that performs the Winograd filter transformation:

U = G · g · Gᵀ

The FSM consists of five main states:

---

##### IDLE

- Default state after reset.
- Internal registers are initialized:
  - `done <= 0`
  - `u_count <= 0`
  - `row <= 0`
  - `col <= 0`
- The module waits for `start = 1`.

**Transitions:**
- If `start = 0`, remain in `IDLE`.
- If `start = 1`, transition to `LOAD`.

---

##### LOAD

- Sequentially loads 9 filter coefficients into the 3×3 matrix `g_matrix`.
- Data is written as:

  g_matrix[g_row][g_col] <= g_in

- The write position is controlled by `g_count`.

**Transition condition:**
- When `g_count == 4'd8` (all 9 kernel elements loaded),
  transition to `COMPUTE_GG`.

---

##### COMPUTE_GG

- Computes the first matrix multiplication:

  temp_matrix = G × g_matrix

- Computation is performed element-by-element using `row` and `col`.

- Iteration behavior:
  - If `row < 4'd3 || col < 4'd2`, remain in `COMPUTE_GG`.
  - When `(col == 4'd2) && (row == 4'd3)`,
    transition to `COMPUTE_GGGT`.

---

##### COMPUTE_GGGT

- Computes the second matrix multiplication:

  u_matrix = temp_matrix × Gᵀ

- Each clock cycle updates:

  u_matrix[row][col] = temp_matrix[row][col] × Gᵀ

- Iteration behavior:
  - If `row < 4'd3 || col < 4'd3`, remain in `COMPUTE_GGGT`.
  - When `(col == 4'd3) && (row == 4'd3)`,
    transition to `OUTPUT`.

---

##### OUTPUT

- Sequentially outputs the 16 transformed kernel values:

  u_out <= u_matrix[u_count[3:2]][u_count[1:0]]

- `u_count` increments each clock cycle.

**Transition condition:**
- When `u_count == 15`:
  - `done = 1`
  - Transition back to `IDLE`.

---

### 3.4. Module winograd_elementwise

#### Input/Output Signal Description Table of element-wise module

| Signal     | Bits | I/O | Active Level | Function |
|------------|------|-----|--------------|----------|
| clk        | 1    | I   | High | Clock signal; control logic operates on the rising edge of clk |
| rstn       | 1    | I   | Low  | Reset signal, initializes the module to its default state |
| start      | 1    | I   | High | Starts the transform operation |
| u_in       | 32   | I   | N/A  | U matrix (winograd_filter_transform) |
| v_in       | 32   | I   | N/A  | V matrix (winograd_input_transform) |
| elem_idx   | 4    | I   | N/A  | Winograd element index (0–15) |
| ch_idx     | 8    | I   | N/A  | Current channel index |
| num_ch     | 8    | I   | N/A  | Cumulative channel count |
| all_done   | 1    | O   | High | Complete flag |
| m_out      | 32   | O   | N/A  | M matrix |
| valid_out  | 1    | O   | N/A  | Output valid |

---

#### Functional Behavior Specification

The `winograd_elementwise` module is the core computation block of the Winograd accelerator. It performs:

- Element-wise multiplication between the transformed input tensor (V) and the transformed kernel tensor (U).  
- Accumulation across the channel dimension to produce the partial convolution results.  

$$
M_{i,j} = \sum_{c=0}^{C-1} U_{i,j,c} \times V_{i,j,c}
$$

Including:

- \( i, j \in [0..3] \), resulting in a total of 16 Winograd elements.  
- \( c \) denotes the channel index.  
- In each clock cycle, the module processes one element (`elem_idx`) of one channel.  
- The control of the processing order for `elem_idx` and `ch_idx` is handled by the top-level module.

#### State Diagram Description of winograd_elementwise Module

The `winograd_elementwise` module performs element-wise multiplication and channel-wise accumulation in the Winograd domain. The FSM controls initialization, accumulation across channels, and output validation.

The computation performed is:

M[i,j] = Σ ( U[i,j,c] × V[i,j,c] )

for each Winograd element (16 elements total).

The FSM consists of five main states:

---

##### 1. RESET

- Active when `rst_n = 0`.
- Initializes internal registers:
  - `valid_out <= 0`
  - `elem_complete <= 16'b0`
  - `m_buffer[0:15] <= 0`
- When `rst_n = 1`, transition to `IDLE`.

---

##### 2. IDLE

- Default waiting state.
- `valid_out <= 0`.
- Waits for `start = 1`.

**Transitions:**

- If `(start = 1) && (ch_idx == 0)`  
  → transition to `INITIALIZE`.

- If `(start = 1) && (ch_idx > 0)`  
  → transition to `ACCUMULATE`.

- If `rst_n = 0` or `start = 0`, remain in `IDLE`.

---

##### 3. INITIALIZE

- Used when processing the first channel (`ch_idx == 0`).
- Initializes accumulation buffer for the current Winograd element:

  m_buffer[elem_idx] <= fp_mult(u_in, v_in)

- Marks element as not yet completed:
  
  elem_complete[elem_idx] <= 1'b0

**Transition:**

- If `ch_idx != num_ch - 1`  
  → go to `ACCUMULATE`.

- If `ch_idx == num_ch - 1`  
  → go to `COMPLETE`.

---

##### 4. ACCUMULATE

- Performs accumulation across channels:

  m_buffer[elem_idx] <=  
  m_buffer[elem_idx] + fp_mult(u_in, v_in)

- Continues while processing intermediate channels.

**Transitions:**

- If `ch_idx != num_ch - 1`, remain in `ACCUMULATE`.

- If `ch_idx == num_ch - 1`,  
  → transition to `COMPLETE`.

---

##### 5. COMPLETE

- Indicates accumulation for the current element is finished.
- Updates:

  elem_complete[elem_idx] = 1  
  valid_out = 1

- Signals that the output for this Winograd element is valid.

**Transitions:**

- If `(start = 1) && (ch_idx > 0)`  
  → transition back to `ACCUMULATE`.

- If `(start = 1) && (ch_idx == 0)`  
  → transition to `INITIALIZE`.

---
  
### 3.5. Module winograd_output_transform

#### Input/Output Signal Description Table of the output-transform module

| Signal   | Bits | I/O | Active Level | Function |
|----------|------|-----|--------------|----------|
| clk      | 1    | I   | High | Clock signal; control logic operates on the rising edge of clk |
| rstn     | 1    | I   | Low  | Reset signal, initializes the module to its default state |
| start    | 1    | I   | High | Starts the transform operation |
| m_in     | 32   | I   | N/A  | Data từ module element_wise |
| m_count  | 4    | I   | N/A  | The index counter of the m_in signal |
| y_out    | 32   | O   | N/A  | Output data of the Winograd algorithm |
| y_count  | 2    | O   | N/A  | Output element index |
| done     | 1    | O   | High | Complete flag |

---

#### Functional Specification

The `winograd_output_transform` module performs the output transformation of the Winograd F(2×2,3×3) algorithm, specifically:

$$
Y = A^T \cdot M \cdot A
$$

Including:

- **M** is the intermediate 4×4 matrix obtained after the element-wise multiplication and accumulation across channels.  
- **A** is the Winograd output transformation matrix.  
- **Y** is the output matrix with a size of 2×2.

#### State Description of winograd_output_transform Module

##### 1. IDLE

- Default state after reset.
- Initializes internal registers:
  - `done <= 0`
  - `y_count <= 0`
  - `row <= 0`
  - `col <= 0`
- Waits for `start = 1`.

**Transitions:**
- If `start = 0`, remain in `IDLE`.
- If `start = 1`, transition to `LOAD`.

---

##### 2. LOAD

- Sequentially loads 16 elements of matrix M.
- Data storage mapping:

  m_matrix[m_count[3:2]][m_count[1:0]] <= m_in

- Resets `row` and `col` counters for computation.

**Transition condition:**
- When `m_count == 4'd15`,
  transition to `COMPUTE_ATM`.

---

##### 3. COMPUTE_ATM

- Computes the first multiplication:

  temp_matrix = Aᵀ × m_matrix

- Updates:

  temp_matrix[row][col]

- Iteration behavior:
  - If `col < 2'd3 || row < 2'd1`, remain in `COMPUTE_ATM`.
  - When `row == 2'd1 && col == 2'd3`,
    transition to `COMPUTE_ATMA`.

---

##### 4. COMPUTE_ATMA

- Computes the second multiplication:

  y_matrix = temp_matrix × A

- Updates:

  y_matrix[row][col]

- Iteration behavior:
  - If `row < 2'd1 || col < 2'd1`, remain in `COMPUTE_ATMA`.
  - When `row == 2'd1 && col == 2'd1`,
    transition to `PRE_OUTPUT`.

---

##### 5. PRE_OUTPUT

- Waits one clock cycle to stabilize output data.
- Prepares final 2×2 output matrix for serialization.

**Transition:**
- After 1 clock cycle,
  transition to `OUTPUT`.

---

##### 6. OUTPUT

- Sequentially outputs the 4 elements of the 2×2 matrix:

  y_out <= y_matrix[row][col]  
  y_count <= y_count + 1

- Each clock cycle outputs one element.

**Transition condition:**
- When `y_count == 2'd3`:
  - `done = 1`
  - Transition back to `IDLE`.

---
