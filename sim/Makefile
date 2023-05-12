src = " ../src/tb/tb.v ../src/rtl/apb_watchdog.v ../src/rtl/cnt_clk_div.v ../src/rtl/ctrl_reg.vh"

default: test 

test: compile run

run:
	./simv -l simv.log
compile:
	vcs -full64 -l vcs.log -sverilog -kdb -debug_access+all $(src)  +vcs+vcdpluson -lca
dve:
	dve -vpd vcdplus.vpd &
debug:
	./simv -l simv.log -gui=dve
clean:
	rm -rf simv* csrc* *.tmp *.vpd *.key *.log *hdrs.h *.fsdb verdiLog elabcomLog novas.* *.dat DVEfiles .*.old .*.tcl *.vcd

help:
	@echo ==========================================================================
	@echo  " 								       "
	@echo  " USAGE: make target                                                    "
	@echo  " 								       "
	@echo  " ------------------------- Test TARGETS ------------------------------ "
	@echo  " test       => Compile TB and DUT files, runs the simulation.          "
	@echo  " compile    => Compile the TB and DUT. Generates dve and verdi output  "
	@echo  " run        => Run the simulation.                                     "
	@echo  " dve        => Run dve in post-processing mode.          "
	@echo  " debug      => Runs simulation interactively with dve.                  "
	@echo  " clean      => Remove all intermediate simv and log files.             "
	@echo  "                                                                       "
	@echo  " -------------------- ADMINISTRATIVE TARGETS ------------------------- "
	@echo  " help       => Displays this message.                                  "
	@echo ==========================================================================

#.PHONY: run
