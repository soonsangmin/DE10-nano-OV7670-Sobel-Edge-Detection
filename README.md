# Real-Time Sobel Edge Detection Hardware Accelerator on FPGA

![FPGA](https://img.shields.io/badge/Platform-Intel%20Cyclone%20V-blue)
![Language](https://img.shields.io/badge/Language-Verilog%20HDL-brightgreen)
![Resolution](https://img.shields.io/badge/Resolution-640x480%20%40%2060fps-orange)
![License](https://img.shields.io/badge/License-MIT-green)

A high-performance, real-time edge detection hardware accelerator built on an Intel Cyclone V FPGA (DE10-Nano development board). The system captures a live video stream from an **OV7670 camera module**, applies an optimized **Sobel filter algorithm** on-the-fly in hardware, and drives a live output display to an **HDMI monitor at 640x480 @ 60 FPS** with near-zero latency.

---

## 🌟 Key Features

* **Real-Time Zero-Latency Processing**: Pipelined hardware design processes streaming pixels at 60 FPS without storing full video frames in external memory.
* **Efficient Memory Management**: Utilizes only **2 physical Line Buffers** mapped into internal Block RAM (M10K) instead of 3, cutting BRAM consumption significantly.
* **Look-Ahead Addressing**: Mitigates native 1-cycle BRAM read latency using early read-address generation (`col_count + 1`).
* **Hardware Boundary Handling (Pixel Clamping)**: Smart edge clamping prevents line buffer boundary corruptions, retaining maximum visual fidelity at image edges without falling back on zero-padding or resolution reduction.
* **L1-Norm Mathematical Approximation**: Replaces resource-heavy arithmetic ($G = \sqrt{G_x^2 + G_y^2}$) with absolute sum approximation ($|G| \approx |G_x| + |G_y|$) and bit-shift multiplication.
* **Ultra-Low Resource Footprint**: Consumes less than **1% of Logic Synthesis resources (ALMs)** on the Cyclone V board.

---
+-----------+    Raw Pixel Stream    +-------------------+    3x3 Matrix    +------------------+    Edge Map    +-----------------+
|  OV7670   | ---------------------> | Line Buffer Ctrl  | ---------------> |  Sobel Arithmetic| -------------> | HDMI Controller | ---> Monitor
|  Camera   |  (pixel_in, enable)    | (2x BRAM + Shift) |    (p00..p22)    |     Pipeline     |  (pixel_out)   |   (640x480@60)  |
+-----------+                        +-------------------+                  +------------------+                +-----------------+
^                                                                                                                 ^
|==================================== I2C / SCCB Config Master ===================================================|


---

## 🛠 Hardware Pipeline Breakdown

### 1. Line Buffer Controller (`line_buffer_ctrl.v`)
To generate a continuous $3 \times 3$ sliding window matrix from a sequential 1D pixel stream without external SDRAM:
* **2-Line BRAM Buffering**: Stores Row $N-2$ and Row $N-1$, while the streaming camera input directly serves as Row $N$.
* **Look-Ahead Read Addressing**: Predicts the next column address (`read_addr = col_count + 1`) to ensure data is fetched from BRAM synchronously with the clock cycle.
* **Pixel Clamping Logic**: Automatically duplicates border pixels at the frame boundaries (`col_count == 0`, `col_count == 1`, `col_count == WIDTH - 1`) to preserve full $640 \times 480$ spatial resolution without border visual artifacts.

### 2. Sobel Processing Engine (`sobel_calc.v`)
Calculates intensity gradients in parallel across a 3-stage arithmetic pipeline:
* **Kernel Execution**:
  $$G_x = (p_{02} + 2 \cdot p_{12} + p_{22}) - (p_{00} + 2 \cdot p_{10} + p_{20})$$
  $$G_y = (p_{20} + 2 \cdot p_{21} + p_{22}) - (p_{00} + 2 \cdot p_{01} + p_{02})$$
* **Bit-Shift Multiplication**: Multiplication by 2 is executed via hardware bit-shifts (`<< 1`), saving DSP slices.
* **L1-Norm Approximation**: Total Gradient $|G| = |G_x| + |G_y|$.
* **Binarization / Thresholding**: Compares $|G|$ against a predefined threshold to output binary edge pixels (High = White Edge, Low = Black Background).

---

## 📊 Performance & Resource Utilization

Synthesized on **Intel Cyclone V CSXFC6C6U23I7N (DE10-Nano)**:

| Resource Type | Used | Total Available | Utilization (%) |
| :--- | :---: | :---: | :---: |
| **Logic Utilization (ALMs)** | ~320 | 41,910 | **~1%** |
| **Total Block Memory (M10K)** | ~2,400 Kbits | 5,570 Kbits | **~44%** |
| **DSP Blocks** | 2 | 112 | **~2%** |
| **Frame Rate** | **60 FPS** | - | **100% Real-Time** |
| **Resolution** | **640 x 480** | - | **NTSC Standard** |

---

## 🚀 Getting Started

### Prerequisites
* **Hardware**: 
  * Intel Cyclone V FPGA Board (e.g., Terasic DE10-Nano )
  * OV7670 CMOS Camera Module
  * HDMI Display & Cable
* **Software**: 
  * Intel Quartus Prime (Lite / Standard Edition v18.1 or later)
  * ModelSim / QuestaSim for Simulation
## 📐 System Architecture

The overall hardware structure forms a continuous pipeline connecting the CMOS camera directly to the HDMI output controller:
