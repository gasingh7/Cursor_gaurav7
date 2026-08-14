#!/usr/bin/env python3
"""
Golden model for top (dual LEFT lpm_shiftreg, outputs ANDed).
Same inputs drive both instances; each test case varies one control.
"""

from __future__ import annotations


class LpmShiftReg:
    def __init__(self, width: int = 4, direction: str = "LEFT"):
        self.width = width
        self.direction = direction
        self.q = 0

    @property
    def shiftout(self) -> int:
        if self.direction == "LEFT":
            return (self.q >> (self.width - 1)) & 1
        return self.q & 1

    def aclr(self) -> None:
        self.q = 0

    def clock(self, enable: int, sclr: int, load: int, data: int, shiftin: int) -> None:
        if not enable:
            return
        if sclr:
            self.q = 0
        elif load:
            self.q = data & ((1 << self.width) - 1)
        else:
            if self.direction == "LEFT":
                self.q = ((self.q << 1) | (shiftin & 1)) & ((1 << self.width) - 1)
            else:
                self.q = ((shiftin & 1) << (self.width - 1)) | (self.q >> 1)


class Top:
    def __init__(self):
        self.a = LpmShiftReg()
        self.b = LpmShiftReg()

    @property
    def q_out(self) -> int:
        return self.a.q & self.b.q

    @property
    def shiftout(self) -> int:
        return self.a.shiftout & self.b.shiftout

    def aclr(self) -> None:
        self.a.aclr()
        self.b.aclr()

    def step(self, enable, sclr, load, data, shiftin) -> None:
        self.a.clock(enable, sclr, load, data, shiftin)
        self.b.clock(enable, sclr, load, data, shiftin)

    def show(self, label: str, **kw) -> None:
        en = kw.get("en", "-")
        load = kw.get("load", "-")
        sin = kw.get("sin", "-")
        data = kw.get("data", None)
        sclr = kw.get("sclr", "-")
        aclr = kw.get("aclr", "-")
        data_s = f"{data:04b}" if isinstance(data, int) else "-"
        print(
            f"  {label:42s} | en={en} load={load} sin={sin} data={data_s} "
            f"sclr={sclr} aclr={aclr} | q_out={self.q_out:04b} shiftout={self.shiftout}"
        )


def run() -> None:
    dut = Top()
    dut.aclr()

    print("==== TC1: Asynchronous Clear (aclr=1) ====")
    dut.step(1, 0, 1, 0b1010, 0)
    dut.show("After parallel load of 1010", en=1, load=1, data=0b1010, sclr=0, aclr=0)
    dut.aclr()
    dut.show("aclr asserted (async) — expect q=0000", en=1, load=1, data=0b1010, sclr=0, aclr=1)
    assert dut.q_out == 0b0000

    print("\n==== TC2: Synchronous Clear (sclr=1) ====")
    dut.step(1, 0, 1, 0b1111, 0)
    dut.show("Loaded 1111", en=1, load=1, data=0b1111, sclr=0)
    dut.step(1, 1, 0, 0, 0)
    dut.show("sclr on posedge — expect q=0000", en=1, load=0, sclr=1)
    assert dut.q_out == 0b0000

    print("\n==== TC3: Parallel Load (load=1) ====")
    dut.step(1, 0, 1, 0b1001, 0)
    dut.show("load data=1001 — expect q=1001, so=1", en=1, load=1, data=0b1001)
    assert dut.q_out == 0b1001 and dut.shiftout == 1
    dut.step(1, 0, 1, 0b0110, 0)
    dut.show("load data=0110 — expect q=0110, so=0", en=1, load=1, data=0b0110)
    assert dut.q_out == 0b0110 and dut.shiftout == 0

    print("\n==== TC4: Serial LEFT Shift (load=0) ====")
    dut.step(1, 0, 1, 0b0000, 0)
    dut.show("Reset via load 0000", en=1, load=1, data=0)
    for bit, expect in [(1, 0b0001), (0, 0b0010), (1, 0b0101), (1, 0b1011)]:
        dut.step(1, 0, 0, 0, bit)
        dut.show(f"shiftin={bit}", en=1, load=0, sin=bit)
        assert dut.q_out == expect, f"got {dut.q_out:04b} expected {expect:04b}"
    print("  (final expect q=1011, so=1)")

    print("\n==== TC5: Enable=0 Hold (no update) ====")
    # previous q=1011
    dut.step(0, 1, 1, 0b0101, 0)  # enable=0: ignore sclr/load
    dut.show("en=0 with load+sclr — expect HOLD 1011", en=0, load=1, data=0b0101, sclr=1)
    assert dut.q_out == 0b1011
    dut.step(1, 0, 0, 0, 0)
    dut.show("en=1 shiftin=0 — expect q=0110", en=1, load=0, sin=0)
    assert dut.q_out == 0b0110

    print("\n==== TC6: Priority sclr > load ====")
    dut.step(1, 0, 1, 0b1100, 0)
    dut.show("Loaded 1100", en=1, load=1, data=0b1100)
    dut.step(1, 1, 1, 0b1111, 0)
    dut.show("sclr+load same cycle — expect q=0000", en=1, load=1, data=0b1111, sclr=1)
    assert dut.q_out == 0b0000

    print("\n==== TC7: Priority load > shift ====")
    dut.step(1, 0, 1, 0b0011, 1)
    dut.show("load=1 with shiftin=1 — expect q=0011", en=1, load=1, sin=1, data=0b0011)
    assert dut.q_out == 0b0011
    dut.step(1, 0, 0, 0, 1)
    dut.show("now shift — expect q=0111", en=1, load=0, sin=1)
    assert dut.q_out == 0b0111

    print("\n==== TC8: shiftout = MSB during LEFT shift ====")
    dut.step(1, 0, 1, 0b1000, 0)
    dut.show("Loaded 1000 — expect so=1", en=1, load=1, data=0b1000)
    assert dut.shiftout == 1
    dut.step(1, 0, 0, 0, 0)
    dut.show("shift left, sin=0 — expect q=0000 so=0", en=1, load=0, sin=0)
    assert dut.q_out == 0b0000 and dut.shiftout == 0

    print("\n==== TC9: aclr mid-operation ====")
    dut.step(1, 0, 1, 0b1110, 0)
    dut.show("Loaded 1110", en=1, load=1, data=0b1110)
    dut.aclr()
    dut.show("aclr mid-cycle — expect q=0000 immediately", aclr=1)
    assert dut.q_out == 0b0000

    print("\n==== TC10: Dual-instance AND consistency ====")
    dut.step(1, 0, 1, 0b1010, 0)
    dut.show("Both loaded same — q_out must equal 1010", en=1, load=1, data=0b1010)
    assert dut.q_out == 0b1010
    assert dut.a.q == dut.b.q
    print("  PASS: dual instances match (q_out = q_w1 & q_w2)")

    print("\n==== All directed test cases PASS ====\n")


if __name__ == "__main__":
    run()
