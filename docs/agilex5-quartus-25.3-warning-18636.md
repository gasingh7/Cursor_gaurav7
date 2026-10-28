# Agilex 5 / Quartus 25.3: Critical Warning 18636 (no programming file)

Technical note for the TI | Altera thread started by Ameet Bagwe on 28 Oct 2026.

## Symptom

Quartus Prime Pro **25.3** completes compile for device **A5ED065BB32AE4S**, but the Assembler does not emit a `.sof` / bitfile. The report shows:

```
Critical Warning(18636): Compilation Report contains advance information.
Specifications for device A5ED065BB32AE4S are subject to change.
Contact Altera for information on availability.
No programming file will be generated.
```

Agilex 7 designs on the same farm (25.1.1 and 25.3) generate programming files as expected.

## Root cause

This is **device-support maturity**, not a broken Quartus install.

Altera ships three support levels:

| Level | Compile / timing / pin-out | Programming file (`.sof`) | Models / bitstream |
| --- | --- | --- | --- |
| Advance | Yes | **No** | Not finalized |
| Preliminary | Yes | **Yes** | Not finalized (lab / debug only) |
| Final | Yes | **Yes** | Finalized (production) |

In Quartus Prime Pro **25.3**, the production OPN family **A5ED065BB32** (covers `A5ED065BB32AE4S` and the other E4/E5/E6 speed grades of that package) is listed under **Advance** device support. Advance devices intentionally skip Assembler output. That is exactly warning 18636.

Ameet's guess is directionally right: Agilex 5 bitstream support lagged Agilex 7. It is more precise than "Agilex 5 was rolled in later":

- Smaller Agilex 5 E-Series devices (008 / 013, especially `-CS` OPNs) reached Final support in 25.1.1 / 25.3.
- The **065B B32** production OPN stayed Advance in 25.3.0, moved to **Preliminary in 25.3.1**, and reached **Final in 26.1**.

Official sources:

- [25.3 Advance device support](https://docs.altera.com/r/docs/683706/25.3/quartus-prime-pro-edition-version-25.3-software-and-device-support-release-notes/devices-with-advance-device-support) — includes `A5ED065BB32`
- [25.3 Preliminary device support](https://docs.altera.com/r/docs/683706/25.3/quartus-prime-pro-edition-version-25.3-software-and-device-support-release-notes/devices-with-preliminary-device-support) — `A5ED065BB32-R0` only (ES revision)
- [25.3.1 Preliminary device support](https://docs.altera.com/r/docs/683706/25.3.1/quartus-prime-pro-edition-version-25.3.1-software-and-device-support-release-notes/devices-with-preliminary-device-support) — includes production `A5ED065BB32`
- [26.1 Final device support](https://docs.altera.com/r/docs/683706/26.1/quartus-prime-pro-edition-version-26.1-software-and-device-support-release-notes/devices-with-final-device-support) — includes `A5ED065BB32`
- [KDB 345059](https://community.altera.com/kb/knowledge-base/why-cant-the-agilex%E2%84%A2-5-or-agilex%E2%84%A2-7-fpga-programming-file-be-generated-in-the-qu/345059) — same 18636 warning on a 065B B32 OPN

## Can TI stay on the 25.3 family?

**Not on stock 25.3.0** for this production OPN. **Yes on 25.3.1**, which is the smallest move that enables `.sof` generation.

### Recommended path (stay in 25.3.x)

1. Install Quartus Prime Pro **25.3.1** (Linux build **25.3.1.100**) side-by-side on the TI compute farm.
   - Download: [Quartus Prime Pro 25.3.1 for Linux](https://www.altera.com/downloads/fpga-development-tools/quartus-prime-pro-edition-design-software-version-25-3-1-linux)
   - Required packages: `agilex5-25.3.1.100.qdz` and `agilex_common-25.3.1.100.qdz`
   - 25.3.1 is **Agilex 3 / 5 / 7 only**. Do not replace a 25.3 install that is also used for Arria 10, Cyclone 10 GX, or Stratix 10. Put 25.3.1 next to it.
   - Apply the **mandatory post-install patch** linked from that download page.
2. Keep the Quartus device set to the **exact OPN printed on the silicon / board**, currently `A5ED065BB32AE4S` if that is what is on the hardware.
3. Confirm every user pin has both a **location** and an **I/O standard**. Starting in 25.1.1, missing either also suppresses the `.sof` (different critical warning; see I/O Assignment Warnings in the Fitter report).
4. Recompile. Warning 18636 should go away and Assembler should emit `*.sof`.

Caveat: in 25.3.1 the 065B B32 production OPN is **Preliminary**. Timing, power, and bitstream models are not frozen. Use the file for bring-up and IP debug. Production sign-off should move to **26.1**, where `A5ED065BB32` is Final (models marked Final – 26.1).

### If 25.3.1 cannot be installed this week

| Hardware marking | 25.3.0 action |
| --- | --- |
| ES / revision **R0** (for example `A5ED065BB32AE4SR0`) | Retarget the project to that exact R0 OPN. `A5ED065BB32-R0` is Preliminary in 25.3, so a `.sof` is generated. |
| Production OPN **without** R0 (`A5ED065BB32AE4S`) | No supported Assembler output in 25.3.0. FAE can request a **temporary `quartus.ini`** from Altera software/support for lab debug only ([KDB 345059](https://community.altera.com/kb/knowledge-base/why-cant-the-agilex%E2%84%A2-5-or-agilex%E2%84%A2-7-fpga-programming-file-be-generated-in-the-qu/345059)). Do not use that bitstream for production. |

Do **not** compile for R0 and program production silicon (or the reverse). SKU mismatch fails in the programmer (`Error 18948`, device specification / SKU ID does not match).

## OPN checklist (easy to get wrong)

Match the full string on the package, not just "065B":

| Field | Example | Why it matters |
| --- | --- | --- |
| Variant letter | `C` vs `D` (`A5EC…` vs `A5ED…`) | HPS / crypto feature set. Wrong letter programs then fails at ~30–44%. |
| Density + package | `065BB32A` | Must match the board. |
| Speed + temp | `E4S` | Must match silicon. |
| Revision / sample | none vs `R0` / `R1` / `CS` | Controls Advance vs Preliminary vs Final in a given Quartus. |

Premium 065B development kits are often `A5ED065BB32AExSR0` (ES), not the production `…E4S` string.

## Why Agilex 7 was fine

Agilex 7 F/I/M production OPNs have had Final (or at least Preliminary) programming-file support for several 25.x releases. Warning 18636 is OPN- and revision-specific, not a generic "Agilex 5 is unsupported in 25.3" problem.

## Suggested next step on the TI call

1. Confirm the **exact marking** on the TI board (photo of the package or `jtagconfig` / programmer device ID).
2. If they must stay on 25.3.x: install **25.3.1.100** side-by-side and rebuild.
3. If they can take a newer tool: **26.1** is the first release with Final support for `A5ED065BB32`.
4. In parallel, keep the JESD204B/C / AFE79xx timing-constraint discussion on the original meeting request (separate from this Assembler issue).
