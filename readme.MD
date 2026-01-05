# Basys-3 4-Bit Calculator (VHDL)

A digital **4-bit calculator** implemented in **VHDL** for the **Basys-3 FPGA**.  
Supports **Add / Sub / Mul / Div**, a simple **FSM-based input flow**, and multiplexed **4-digit seven-seg output**.

---

## Features
- ✅ 4-bit input operands (**0–15 / hex**)
- ✅ Operations:
  - **Addition** (btnU)
  - **Subtraction** (btnD) *(error if negative)*
  - **Multiplication** (btnR)
  - **Division** (btnL) *(error on divide-by-zero; shows decimals when needed)*
- ✅ FSM flow: input A → input B → compute → result / error
- ✅ 4-digit multiplexed seven-seg display + optional decimal point for division
- ✅ Master display ON/OFF switch

---

## Controls (Basys-3)
| Input | Meaning |
|------|---------|
| `sw[3:0]` | Current 4-bit value (0–15) |
| `btnU` | Select **ADD** |
| `btnD` | Select **SUB** |
| `btnR` | Select **MUL** |
| `btnL` | Select **DIV** |
| `sw[15]` | **Equal (=)** confirm B + compute |
| `btnC` | **Clear / Reset** |
| `sw[4]` | Display ON/OFF |

---

## How it works (High-level)
This design uses a **Finite State Machine (FSM)**:
1. **Input A**: choose operand A using `sw[3:0]`, then select an operation via a button.
2. **Input B**: choose operand B using `sw[3:0]`, then press `sw[15]` to compute.
3. **Result**: shows the computed output on the 7-seg display.
4. **Error**: shows `Err` for invalid operations (e.g., divide-by-zero or negative subtraction).

Division supports **up to 2 decimal places** (e.g., `2.33`) by scaling the numerator before dividing.

---

## Build & Program (Vivado)
1. Open **Vivado** → Create Project (RTL)
2. Add VHDL source files from `src/`
3. Add constraints file from `constraints/basys3.xdc`
4. Set top module: `project_mydecoder`
5. Run:
   - Synthesis
   - Implementation
   - Generate Bitstream
6. Program the Basys-3 board

---
