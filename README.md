# Pipelined CORDIC Trigonometric & Vector Processing IP Core
## Overview
This repo contains a synthesizable, parameterizable **CORDIC IP core** implemented in SystemVerilog with **two operating modes**:

- **Rotation mode**: computes **sin/cos** for an input angle by rotating an input vector.
- **Vectoring mode**: computes **atan2(y,x)** and **magnitude** by driving the Y component toward zero.

The design is built as a reusable IP block with **ready/valid streaming interfaces**, **pipeline stall support**, and **numeric-quality enhancements** (guard bits + optional gain compensation). It has been implemented on a Xilinx Artix-7 FPGA (Basys3) @ 100MHz and produced accurate calculation across various inputs on real-time hardware.

---

## Key Features

### CORDIC Modes
- **Rotation (Trig)**
  - Inputs: `(x_start, y_start, angle)`
  - Outputs: `(cosine, sine)` = rotated vector components
- **Vectoring (atan2 + Magnitude)**
  - Inputs: `(x_start, y_start)`
  - Outputs: `theta = atan2(y,x)`, `mag = hypot(x,y)` (optionally gain-compensated)

### Numeric Quality
- **Guard bits** (`GUARD`): wider internal datapath prevents overflow / improves accuracy
- **Optional gain compensation** (`GAIN_COMP`)
  - Rotation: post-scales outputs by `1/K` (constant multiply) so amplitude matches the input vector
  - Vectoring: post-scales magnitude by `1/K` so `mag ≈ hypot(x,y)`
- Parameterized precision:
  - `XY_W` (input/output width)
  - `ANGLE_W` (angle width; default 32-bit “turns” format)
  - `ITER` (iteration/stage count)

### Full-Range Angle Handling
- Rotation mode includes **angle normalization/quadrant mapping** for **full 0–2π** coverage using signed arithmetic (`±π/2` offsets).
- Vectoring mode uses **pre-rotation into the right half-plane** (`x0 >= 0`) and seeds `z0` with `0 / ±π / ±π/2` as needed for correct `atan2()` quadrants.

### Interfaces
- **Ready/valid handshake**: `in_valid/in_ready` and `out_valid/out_ready`
- **Backpressure support**: pipeline **stalls** when `out_ready=0` (state held via clock-enable gating)
- **1 sample/cycle throughput:** when pipeline not stalled and after pipeline fill

---

## Architecture Details

### Angle Format
The default `ANGLE_W=32` uses a **“turns” phase accumulator** format:

- `2^ANGLE_W` represents **one full rotation (2π / 360°)**
- For `ANGLE_W=32`:
  - `π = 0x8000_0000`
  - `π/2 = 0x4000_0000`

This format makes wrapping and quadrant detection efficient and synthesizable.

### Pipeline Datapath
The core is implemented as a pipeline:

- A **preprocessing stage** registers `(x0, y0, z0)` on input accept.
- A `generate for` loop instantiates `ITER` copies of `cordic_stage`.
- Each stage contains an `always_ff` register boundary, so every cycle data advances one stage (when not stalled).

Dataflow conceptually: (preproc regs) -> stage0 regs -> stage1 regs -> ... -> stage(ITER-1) regs -> outputs

### Stall / Backpressure
When `out_valid=1` and `out_ready=0`, the core asserts `stall` and:
- Deasserts `in_ready`
- Freezes the entire pipeline with clock-enable gating (`ce = !stall`)
- Holds outputs stable until the downstream accepts the sample

### Mode Selection
Rotation vs vectoring is implemented by using the **same stage module** with different update equations:

- **Rotation mode**: direction `d` derived from `sign(z)`
- **Vectoring mode**: direction `d` derived from `sign(y)`

This maximizes code reuse and keeps both modes behaviorally aligned.

### Gain Compensation
CORDIC outputs are scaled by the gain `K`. When enabled, gain compensation multiplies by `1/K` using a fixed-point constant (e.g., Q1.15) and shifts back down. This is implemented as a **pure combinational post-processing step** from the final pipeline register tap (so it remains stall-stable).

---

## Verification

### Testbenches
- **`tb_cordic_rotator.sv`**
  - Sweeps multiple angles across quadrants (including >180° cases)
  - Compares outputs to `sin()` / `cos()` reference model
  - Includes X-detection and optional randomized `out_ready` backpressure

- **`tb_cordic_vectoring.sv`**
  - Tests all quadrants and axis cases (x=0, y=0)
  - Compares outputs to `atan2()` and `sqrt(x^2+y^2)` reference model
  - Includes wrap-aware angle difference checking (±π normalization)
  - Includes randomized `out_ready` backpressure

- **UVM Verification Environment**
  - Constrained-random sequences to test both modes (checked against golden modules in the `cordic_sb.sv`)
  - Currently achieving ~80-85% code coverage in Cadence Xcelium, plan to refine/enhance the environment to obtain higher coverage (~90-95%) and readability in the future

---

## Known Limitations

- **Fixed-point rounding/saturation**: final output slicing currently truncates. (Optional rounding/saturation can be added for improved numerical behavior.)
- **Iteration/LUT depth**: `ITER` must not exceed the number of available `atan_lut()` entries unless extended.
- **Vectoring input corner case**: `(x,y)=(0,0)` has undefined angle (`atan2(0,0)`); magnitude handling can be defined, but theta is mathematically ambiguous.
- **Magnitude scaling convention**: when `GAIN_COMP=0`, vectoring magnitude is approximately `K * hypot(x,y)`; when `GAIN_COMP=1`, magnitude is approximately `hypot(x,y)`.

---

## Future Improvements

- **Rounding + saturation** on output conversion to `XY_W`
- **Configurable angle formats** (e.g., Q-format radians) via package helpers
- **Shared unified top-level module** with runtime `mode` input (ROT/VEC selectable per transaction)
- **Extended LUT generation** (auto-generate atan table for arbitrary `ITER`)
- **Formal properties** for handshake correctness and pipeline stall
