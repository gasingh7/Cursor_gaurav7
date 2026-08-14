# Dual LPM Shift Register (`top`) — Test Cases

Verilog DUT: two identical 4-bit LEFT `lpm_shiftreg` instances with shared inputs and ANDed outputs.

## Layout

| Path | Description |
|------|-------------|
| `rtl/lpm_shiftreg.v` | Behavioral LPM shift register |
| `rtl/shift.v` | Wrapper used by the first instance |
| `rtl/top.v` | DUT (your module) |
| `tb/tb_top.v` | Directed Verilog testbench (TC1–TC10) |
| `sim/golden_model.py` | Python golden model + assertions |
| `docs/TEST_CASES.md` | Per-case stimulus, expected outputs, rationale |

## Quick start

```bash
python3 sim/golden_model.py
```

See [docs/TEST_CASES.md](docs/TEST_CASES.md) for full explanations of every control-signal test case.
