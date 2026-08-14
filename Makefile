.PHONY: golden sim clean

golden:
	python3 sim/golden_model.py

sim:
	mkdir -p sim
	iverilog -o sim/tb_top.vvp rtl/lpm_shiftreg.v rtl/shift.v rtl/top.v tb/tb_top.v
	cd sim && vvp tb_top.vvp

clean:
	rm -f sim/tb_top.vvp sim/tb_top.vcd
