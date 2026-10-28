# Draft reply — Sahil Patni (FAE) to Ameet Bagwe

Copy the thread. Suggested send time: 28 Oct 2026 (IST).

---

**To:** Bagwe, Ameet \<ameet@ti.com\>; Kothari, Jash \<j-kothari@ti.com\>
**Cc:** Sheikh, Israr \<israr.sheikh@altera.com\>; Murthy, Srinivas \<msrinivas@ti.com\>; Garcia Trujillo, Camilo A \<c-garciatrujillo@ti.com\>; Nagarajan, Gokul \<gokul@ti.com\>; Purohit, Rushikesh \<rushikesh.purohit@altera.com\>
**Subject:** RE: Meeting with TI | ALTERA for few doubts

Hi Ameet,

Thanks for the detailed note, and no worries on the delay. I looked at Critical Warning 18636 on `A5ED065BB32AE4S` under Quartus Prime Pro 25.3.

You are not hitting a farm-install problem. 25.3 compiles this OPN as **Advance** device support: timing and pin-out are available, but the Assembler is defined **not** to emit a programming file until the bitstream/firmware for that SKU is far enough along. That is why the project “runs fine” and still produces no `.sof`. Agilex 7 looking healthy on 25.1.1 / 25.3 is expected; those production OPNs already had programming-file support. For this 065B B32 production part, SOF enablement landed just after 25.3.0.

**Can you stay on 25.3?** Not on 25.3.0 for this production OPN. You can stay on the 25.3 family by moving the Agilex 5 flow to **Quartus Prime Pro 25.3.1** (Linux build **25.3.1.100**). In 25.3.1, `A5ED065BB32` is **Preliminary**, so a `.sof` is generated. Please install it **side-by-side** (25.3.1 is Agilex 3/5/7 only; keep 25.3 if the farm still needs Arria 10 / Stratix 10 / Cyclone 10 GX), install the Agilex 5 + Agilex common device packs, and apply the mandatory post-install patch from the 25.3.1 download page:

https://www.altera.com/downloads/fpga-development-tools/quartus-prime-pro-edition-design-software-version-25-3-1-linux

Two extra checks so the Assembler does not stay silent for a different reason:

1. Device in the `.qsf` must be the **exact** marking on the TI board (`C` vs `D`, speed grade, `R0`/`R1`/`CS` vs production). A 065B Premium kit is often `…R0`, which is a different SKU from `A5ED065BB32AE4S`.
2. Every user pin needs a **location and I/O standard**. From 25.1.1 onward, missing either also suppresses the `.sof` (see I/O Assignment Warnings in the Fitter report).

25.3.1 models for this OPN are still Preliminary, so the file is fine for bring-up and JESD IP debug. For production sign-off, Quartus **26.1** is the first release where `A5ED065BB32` is **Final**.

If 25.3.1 cannot go on the farm before 1 Nov and you only have production (non-R0) silicon, reply with the package marking (or a photo) and I will request a **temporary lab-only `quartus.ini`** from our software team so you can continue debug. That bypass is not for a shippable bitfile.

Happy to join a short call this week (Dallas-friendly) to confirm the OPN and the 25.3.1 install path, and we can keep the JESD204B/C timing-constraint discussion on the same meeting if useful.

Regards,
Sahil
