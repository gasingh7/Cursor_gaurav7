# Test Cases for `top` (Dual LPM Shift Register)

## Design under test

`top` instantiates **two identical** 4-bit LEFT `lpm_shiftreg` blocks (`shift` wrapper + direct `lpm_shiftreg`).

- **Same inputs** feed both instances: `clock_w`, `enable_w`, `shiftin_w`, `load_w`, `data_w`, `sclr_w`, `aclr_w`.
- Outputs are combined: `q_out = q_w1 & q_w2`, `shiftout = shiftout_w1 & shiftout_w2`.
- When both models match, `q_out` equals either instance’s `q`.

### LEFT shift register rules (width = 4)

| Condition | Effect |
|-----------|--------|
| `aclr=1` | Async clear → `q=0000` (no clock needed) |
| `enable=0` | Hold (ignore `sclr`/`load`/shift on clock) |
| `enable=1`, posedge `clock`, `sclr=1` | Sync clear → `q=0000` |
| `enable=1`, posedge, `sclr=0`, `load=1` | Parallel load → `q=data` |
| `enable=1`, posedge, `sclr=0`, `load=0` | Shift left: `q <- {q[2:0], shiftin}` |
| `shiftout` | Always MSB = `q[3]` |

**Priority on an enabled rising edge:** `sclr` > `load` > shift.

---

## How each test case works

Every case uses the **same shared stimulus** for both instances. Each case focuses on **one control** (or one priority relationship).

### TC1 — Asynchronous clear (`aclr`)

| Step | Controls changed | Action | Expected `q_out` | Expected `shiftout` |
|------|------------------|--------|------------------|---------------------|
| 1 | `enable=1`, `load=1`, `data=1010` | Clock | `1010` | `1` |
| 2 | **`aclr=1`** (others unchanged) | No clock | `0000` | `0` |
| 3 | `aclr=0` | — | stays `0000` | `0` |

**Why:** `aclr` clears immediately, even between clock edges. Proves async path vs sync controls.

---

### TC2 — Synchronous clear (`sclr`)

| Step | Controls changed | Action | Expected `q_out` | Expected `shiftout` |
|------|------------------|--------|------------------|---------------------|
| 1 | `enable=1`, `load=1`, `data=1111`, `sclr=0` | Clock | `1111` | `1` |
| 2 | **`sclr=1`**, `load=0` | Clock | `0000` | `0` |

**Why:** Unlike `aclr`, `sclr` only takes effect on a rising edge while `enable=1`.

---

### TC3 — Parallel load (`load`)

| Step | Controls changed | Action | Expected `q_out` | Expected `shiftout` |
|------|------------------|--------|------------------|---------------------|
| 1 | **`load=1`**, `data=1001`, `enable=1` | Clock | `1001` | `1` (`q[3]`) |
| 2 | `data=0110` (still `load=1`) | Clock | `0110` | `0` |

**Why:** With `load=1`, `data` is written into `q` in one cycle; `shiftin` is ignored.

---

### TC4 — Serial LEFT shift (`load=0`, vary `shiftin`)

Start from `q=0000`, then shift in bits **1, 0, 1, 1** (enter at LSB):

| Cycle | `shiftin` | New `q` | `shiftout` | Explanation |
|-------|-----------|---------|------------|-------------|
| 0 | (load 0000) | `0000` | `0` | Known start |
| 1 | **1** | `0001` | `0` | `{000,1}` |
| 2 | **0** | `0010` | `0` | `{001,0}` |
| 3 | **1** | `0101` | `0` | `{010,1}` |
| 4 | **1** | `1011` | `1` | `{101,1}`; MSB becomes 1 |

**Why:** Isolates shift mode (`load=0`, `sclr=0`, `enable=1`) and shows `shiftout` tracking the MSB.

---

### TC5 — Clock enable (`enable`)

| Step | Controls changed | Action | Expected `q_out` |
|------|------------------|--------|------------------|
| Start | (from TC4) | — | `1011` |
| 1 | **`enable=0`**, also assert `load=1`, `sclr=1`, `data=0101` | Clock | **still `1011`** (hold) |
| 2 | **`enable=1`**, `load=0`, `sclr=0`, `shiftin=0` | Clock | `0110` |

**Why:** When `enable=0`, sync ops are gated. Re-enabling resumes left shift: `{011,0}` from `1011` → `0110`.

---

### TC6 — Priority: `sclr` over `load`

| Step | Controls | Action | Expected `q_out` |
|------|----------|--------|------------------|
| 1 | load `1100` | Clock | `1100` |
| 2 | **`sclr=1` and `load=1`**, `data=1111` | Clock | **`0000`** (not `1111`) |

**Why:** On the same enabled edge, `sclr` wins over `load`.

---

### TC7 — Priority: `load` over shift

| Step | Controls | Action | Expected `q_out` |
|------|----------|--------|------------------|
| 1 | **`load=1`**, `data=0011`, `shiftin=1` | Clock | **`0011`** (load, not shift) |
| 2 | **`load=0`**, `shiftin=1` | Clock | `0111` (`{011,1}`) |

**Why:** `load=1` blocks serial shift; clearing `load` returns to shift mode.

---

### TC8 — `shiftout` = MSB

| Step | Controls | Action | Expected `q_out` | Expected `shiftout` |
|------|----------|--------|------------------|---------------------|
| 1 | load `1000` | Clock | `1000` | **`1`** |
| 2 | shift, `shiftin=0` | Clock | `0000` | **`0`** |

**Why:** Confirms serial output is combinational from `q[3]` for LEFT direction.

---

### TC9 — `aclr` mid-operation

| Step | Controls | Action | Expected `q_out` |
|------|----------|--------|------------------|
| 1 | load `1110` | Clock | `1110` |
| 2 | **`aclr=1`** between edges | Async | **`0000` immediately** |

**Why:** Async clear aborts shifting without waiting for a clock edge.

---

### TC10 — Dual-instance AND consistency

| Step | Controls | Action | Expected |
|------|----------|--------|----------|
| 1 | Same load `1010` to both | Clock | `q_out=1010`, `shiftout=1` |

**Why:** Identical inputs ⇒ `q_w1 == q_w2` ⇒ `q_out = q_w1 & q_w2 = q_w1`. If models diverge, AND would clear mismatched bits.

---

## Control-signal summary matrix

| Test | Primary signal under test | Others held / note |
|------|---------------------------|--------------------|
| TC1 | `aclr` | After a known load |
| TC2 | `sclr` | `enable=1`, rising clock |
| TC3 | `load` + `data` | `enable=1`, `sclr=0` |
| TC4 | `shiftin` (shift mode) | `load=0`, `enable=1` |
| TC5 | `enable` | Hold vs resume |
| TC6 | `sclr` vs `load` | Priority |
| TC7 | `load` vs shift | Priority |
| TC8 | `shiftout` vs `q[3]` | LEFT direction |
| TC9 | `aclr` timing | Mid-cycle |
| TC10 | Dual AND | Consistency check |

## How to run

```bash
# Golden model (no HDL simulator required)
python3 sim/golden_model.py

# With Icarus Verilog (if installed)
iverilog -o sim/tb_top.vvp rtl/lpm_shiftreg.v rtl/shift.v rtl/top.v tb/tb_top.v
vvp sim/tb_top.vvp
```
