# TI | Altera — Agilex 5 Quartus notes

Working notes for the TI FPGA bring-up discussion (JESD204B/C on Altera devices, Quartus toolchain).

## Current issue

Ameet Bagwe (TI) compiles an Agilex 5 design (`A5ED065BB32AE4S`) in Quartus Prime Pro **25.3** on the TI compute farm. The compile finishes, but no programming file is generated:

`Critical Warning (18636) … No programming file will be generated.`

- Technical analysis: [`docs/agilex5-quartus-25.3-warning-18636.md`](docs/agilex5-quartus-25.3-warning-18636.md)
- Draft FAE reply: [`drafts/email-reply-ti-ameet-sof.md`](drafts/email-reply-ti-ameet-sof.md)

**Short answer:** expected Advance-device behavior in 25.3.0. Stay on the 25.3 family by installing **25.3.1.100** side-by-side (Preliminary SOF). Use **26.1** for Final/production models.
