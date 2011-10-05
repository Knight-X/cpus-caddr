/*
 * top for running with cver
 */

//`define patch_rw_test // test rw
`define debug_vcd
`define debug
//`define DBG_DLY #1
`define DBG_DLY #0

//`define debug_xbus
//`define debug_vmem
`define debug_md
`define debug_vma

`define build_test

`include "rtl.v"

`include "ram_s3board.v"
`include "debug-spy-driver.v"

`timescale 1ns / 1ns

module test;
   reg sysclk;
   reg reset;
   reg interrupt;

   // controlled by rc circuit at power up
   reg boot;

   wire [15:0] spyin;
   wire [15:0] spyout;
   wire        dbread, dbwrite;
   wire [3:0]  eadr;

   wire [15:0] 	ide_data_bus;
   wire [15:0] 	ide_data_in;
   wire [15:0] 	ide_data_out;
   wire 	ide_dior;
   wire 	ide_diow;
   wire [1:0] 	ide_cs;
   wire [2:0] 	ide_da;

   wire [13:0] 	 mcr_addr;
   wire [48:0] 	 mcr_data_out;
   wire [48:0] 	 mcr_data_in;
   wire 	 mcr_ready;
   wire 	 mcr_write;
   wire 	 mcr_done;

   wire [21:0] 	 sdram_addr;
   wire [31:0] 	 sdram_data_out;
   wire [31:0] 	 sdram_data_in;
   wire 	 sdram_ready;
   wire 	 sdram_req;
   wire 	 sdram_write;
   wire 	 sdram_done;

   wire [14:0] 	 vram_cpu_addr;
   wire [31:0] 	 vram_cpu_data_out;
   wire [31:0] 	 vram_cpu_data_in;
   wire 	 vram_cpu_req;
   wire 	 vram_cpu_ready;
   wire 	 vram_cpu_write;
   wire 	 vram_cpu_done;

   wire [14:0] 	 vram_vga_addr;
   wire [31:0] 	 vram_vga_data_out;
   wire 	 vram_vga_req;
   wire 	 vram_vga_ready;

   wire [17:0] 	 sram_a;
   wire 	 sram_oe_n, sram_we_n;
   wire [15:0] 	 sram1_in;
   wire [15:0] 	 sram1_out;
   wire [15:0] 	 sram2_in;
   wire [15:0] 	 sram2_out;
   wire 	 sram1_ce_n, sram1_ub_n, sram1_lb_n;
   wire 	 sram2_ce_n, sram2_ub_n, sram2_lb_n;

   //
   reg [4:0] slow;
   wire      clk1x, clk2x;
   wire      clk100, clk50;

   initial
     slow = 0;

   always @(posedge sysclk)
     slow <= slow + 1;

   assign clk1x = slow[3];
   assign clk2x = ~slow[1];

   assign clk50 = ~slow[0];
   assign clk100 = sysclk;

   //    
   wire [13:0]   pc;
   wire [5:0]    state;
   wire          machrun;
   wire 	 prefetch;
   wire 	 fetch;
   wire [4:0] 	 disk_state_out;
   wire [3:0] 	 bus_state_out;
   wire [3:0] 	 rc_state_out;
   
   caddr cpu (.clk(clk1x),
	      .ext_int(interrupt),
	      .ext_reset(reset),
	      .ext_boot(boot),
	      .ext_halt(halt),

	      .spy_in(spyin),
	      .spy_out(spyout),
	      .dbread(dbread),
	      .dbwrite(dbwrite),
	      .eadr(eadr),

	      .pc_out(pc),
	      .state_out(state),
	      .machrun_out(machrun),
	      .prefetch_out(prefetch),
	      .fetch_out(fetch),
	      .disk_state_out(disk_state),
	      .bus_state_out(bus_state),
     
	      .mcr_addr(mcr_addr),
	      .mcr_data_out(mcr_data_out),
	      .mcr_data_in(mcr_data_in),
	      .mcr_ready(mcr_ready),
	      .mcr_write(mcr_write),
	      .mcr_done(mcr_done),

	      .sdram_addr(sdram_addr),
	      .sdram_data_in(sdram_data_in),
	      .sdram_data_out(sdram_data_out),
	      .sdram_req(sdram_req),
	      .sdram_ready(sdram_ready),
	      .sdram_write(sdram_write),
	      .sdram_done(sdram_done),
      
	      .vram_addr(vram_cpu_addr),
	      .vram_data_in(vram_cpu_data_in),
	      .vram_data_out(vram_cpu_data_out),
	      .vram_req(vram_cpu_req),
	      .vram_ready(vram_cpu_ready),
	      .vram_write(vram_cpu_write),
	      .vram_done(vram_cpu_done),

	      .ide_data_in(ide_data_in),
	      .ide_data_out(ide_data_out),
	      .ide_dior(ide_dior),
	      .ide_diow(ide_diow),
	      .ide_cs(ide_cs),
	      .ide_da(ide_da));

`ifdef use_ram_controller   

`ifdef real_rc
   ram_controller
`endif
`ifdef debug_rc
   debug_ram_controller
`endif
`ifdef fast_rc
   fast_ram_controller
`endif
`ifdef slow_rc
   slow_ram_controller
`endif
`ifdef min_rc
   min_ram_controller
`endif
`ifdef pipe_rc
   pipe_ram_controller
`endif
     		   rc
		     (.clk(clk100),
		      .vga_clk(clk50),
		      .cpu_clk(clk1x),
		      .reset(reset),
		      .prefetch(prefetch),
		      .fetch(fetch),
		      .machrun(machrun),
		      .state_out(rc_state_out),
		      
		      .mcr_addr(mcr_addr),
		      .mcr_data_out(mcr_data_in),
		      .mcr_data_in(mcr_data_out),
		      .mcr_ready(mcr_ready),
		      .mcr_write(mcr_write),
		      .mcr_done(mcr_done),

		      .sdram_addr(sdram_addr),
		      .sdram_data_in(sdram_data_out),
		      .sdram_data_out(sdram_data_in),
		      .sdram_req(sdram_req),
		      .sdram_ready(sdram_ready),
		      .sdram_write(sdram_write),
		      .sdram_done(sdram_done),
      
		      .vram_cpu_addr(vram_cpu_addr),
		      .vram_cpu_data_in(vram_cpu_data_out),
		      .vram_cpu_data_out(vram_cpu_data_in),
		      .vram_cpu_req(vram_cpu_req),
		      .vram_cpu_ready(vram_cpu_ready),
		      .vram_cpu_write(vram_cpu_write),
		      .vram_cpu_done(vram_cpu_done),
      
		      .vram_vga_addr(vram_vga_addr),
		      .vram_vga_data_out(vram_vga_data_in),
		      .vram_vga_req(vram_vga_req),
		      .vram_vga_ready(vram_vga_ready),
      
		      .sram_a(sram_a),
		      .sram_oe_n(sram_oe_n),
		      .sram_we_n(sram_we_n),
		      .sram1_in(sram1_in),
		      .sram1_out(sram1_out),
		      .sram1_ce_n(sram1_ce_n),
		      .sram1_ub_n(sram1_ub_n),
		      .sram1_lb_n(sram1_lb_n),
		      .sram2_in(sram2_in),
		      .sram2_out(sram2_out),
		      .sram2_ce_n(sram2_ce_n),
		      .sram2_ub_n(sram2_ub_n),
		      .sram2_lb_n(sram2_lb_n)
		      );
`else
   assign mcr_ready = 1;
`endif // use_ram_controller   

   ram_s3board ram(.ram_a(sram_a),
		   .ram_oe_n(sram_oe_n),
		   .ram_we_n(sram_we_n),
		   .ram1_in(sram1_out),
		   .ram1_out(sram1_in),
		   .ram1_ce_n(sram1_ce_n),
		   .ram1_ub_n(sram1_ub_n),
		   .ram1_lb_n(sram1_lb_n),
		   .ram2_in(sram2_out),
		   .ram2_out(sram2_in),
		   .ram2_ce_n(sram2_ce_n),
		   .ram2_ub_n(sram2_ub_n),
		   .ram2_lb_n(sram2_lb_n));

   spy_port_test spy_port(
		     .sysclk(sysclk),
		     .clk(clk1x),
		     .reset(reset),
		     .rs232_rxd(rs232_rxd),
		     .rs232_txd(rs232_txd),
		     .spy_in(spyout),
		     .spy_out(spyin),
		     .dbread(dbread),
		     .dbwrite(dbwrite),
		     .eadr(eadr)
		     );

   integer     addr;
   integer     debug_level;
   integer     dumping;
   integer     cycles;
   integer     max_cycles;
     
   reg [1023:0]  arg;
   integer 	n;

   initial
     begin
	$timeformat(-9, 0, "ns", 7);

`ifdef debug_log
`else
`ifdef __CVER__
	$nolog;
`endif
`endif

	debug_level = 1;
	dumping = 0;
	cycles = 0;
	max_cycles = 0;

`ifdef debug_vcd
	$dumpfile("caddr.vcd");
	$dumpvars(0, test);
	dumping = 1;
`endif

`ifdef __ICARUS__
       n = $value$plusargs("cycles=%d", arg);
	if (n > 0)
	  begin
	     max_cycles = arg;
	     $display("arg cycles %d", max_cycles);
	  end
`endif       
`ifdef __CVER__
       n = $scan$plusargs("cycles=", arg);
	if (n > 0)
	  begin
	     n = $sscanf(arg, "%d", max_cycles);
	     $display("arg cycles %d", max_cycles);
	  end
`endif
     end

   initial
     begin
	sysclk = 0;
	interrupt = 0;
	reset = 0;

	ram.ram1.ram_h[0] = 0;
	ram.ram2.ram_l[0] = 0;
		
	#1 begin
	   reset = 1;
	   boot = 0;

        end

	#500 boot = 1;

	#500 reset = 0;
	#500 boot = 0;
     end

   // 50mhz clock
   always
     begin
	#10 sysclk = 0;
	#10 sysclk = 1;
     end

   // ide
   assign ide_data_bus = ~ide_diow ? ide_data_out : 16'bz;

   assign ide_data_in = ide_data_bus;
     
   always @(posedge clk1x)
     begin
	$pli_ide(ide_data_bus, ide_dior, ide_diow, ide_cs, ide_da);
     end

   //
   // debug
   //
   always @(posedge cpu.clk)
     begin
	if (cpu.state == 6'b000001)
	  cycles = cycles + 1;

	case (cpu.state)
  6'b000000: $display("%0o %o reset  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
  6'b000001: $display("%0o %o decode lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
//  6'b000010: $display("%0o %o read   lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
//  6'b000100: $display("%0o %o alu    lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
//  6'b001000: $display("%0o %o write  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
//  6'b010000: $display("%0o %o mmu    lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
//  6'b100000: $display("%0o %o fetch  lc=%o; %t",cpu.lpc,cpu.ir,cpu.lc,$time);
	endcase

	if (cpu.state == 6'b000001)
	$display("    A=%x M=%x, MD=%x, VMA=%x, ob=%x %b alu=%x nop=%b %b%b",
		 cpu.a, cpu.m, cpu.md, cpu.vma, cpu.ob, cpu.osel, cpu.alu, cpu.nop,
		 cpu.inop, cpu.nop11);
//	$display("    %b",
//		 {cpu.irbyte,cpu.irdisp,cpu.irjump,cpu.iralu});
	  
`ifdef xxx
	if (cycles > 25 && (cpu.lpc > 7 && cpu.lpc < 14'o50) &&
	    (cpu.npc < 14'o50) && cpu.promdisable == 0)
	  begin
	     $display("in microcode error routine; lpc %o", cpu.lpc);
	     $finish;
	  end
`endif

	if (max_cycles > 0 && cycles >= max_cycles)
	  begin
	     $display("maximum cycles count (%0d) exceeded", max_cycles);
	     $finish;
	  end
     end
   

endmodule