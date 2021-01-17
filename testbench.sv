// Code your testbench here
// or browse Examples
 `timescale 1ns/100ps 
 interface intf();
	logic rd_wr;
	logic [7:0] wr_data;
	logic [7:0] rd_data;
	logic reset;
   	logic [7:0] addr;
 endinterface

 interface clk_if();
 	logic tb_clk;
	initial tb_clk =0;
	always #10 tb_clk = ~tb_clk;
 endinterface

 class packet;

 	rand bit rd_wr;

	rand bit [7:0] wr_data;
	rand bit reset;
   	rand bit [7:0] addr;

	bit [7:0] rd_data;
	
 endclass
                        
 class scoreboard;
	
	mailbox scb_m;
   logic [7:0] ref_item[255:0]; 
     
	task run();
      
		forever begin
          
			packet item;
			scb_m.get(item);    
                 
            
          if(item.reset == 0 && item.rd_wr == 1) begin
            if(ref_item[item.addr] == item.rd_data) $display("pass for read, addr=%0h, ref_item=%0h, item =%0h", item.addr, ref_item[item.addr], item.rd_data);
            else $display("fail for read, addr=%0h, ref_item=%0h, item =%0h", item.addr, ref_item[item.addr], item.rd_data);
            
          end
          else if(item.reset == 0 && item.rd_wr == 0)begin
            ref_item[item.addr] = item.wr_data;
            
          end
          else if (item.reset == 1)begin
            for(int i=0; i<=255; i++) begin
              ref_item[i] = 8'hff;
            end
          end  

        	end  
    	endtask

 endclass

 class monitor;

	virtual intf inf;
    	virtual clk_if i_clk_if;
	mailbox scb_m;

	task run();

		forever begin
			packet item = new();
          @(negedge i_clk_if.tb_clk);
			item.rd_wr = inf.rd_wr;
            		item.wr_data = inf.wr_data;
          		item.rd_data = inf.rd_data;
			item.reset = inf.reset;
			item.addr = inf.addr;
			scb_m.put(item);			
		end
	endtask

 endclass

 class generator;

	mailbox drv_m;

	task run();		
      		packet item = new();
      		item.randomize with { reset == 1;};
      		drv_m.put(item);
      
            for ( int i = 0; i<=255; i++)begin
			packet item = new();
              item.randomize() with { reset == 0; rd_wr == 1; addr == i;};
			drv_m.put(item);
      		end
      
      		for ( int i = 0; i<=255; i++)begin
			packet item = new();
        		item.randomize() with { reset == 0; rd_wr == 0; wr_data == addr; addr ==  i;};
			drv_m.put(item);
      		end
      
      		for ( int i = 0; i<=255; i++)begin
			packet item = new();
        		item.randomize() with { reset == 0; rd_wr == 1; addr == i;};
			drv_m.put(item);
      		end
	endtask	

 endclass

 class driver;

	virtual intf inf;
    	virtual clk_if i_clk_if;
	mailbox drv_m;

	task run();
		forever begin
			packet item;
			drv_m.get(item);
			@(posedge i_clk_if.tb_clk);
			inf.rd_wr = item.rd_wr;
          if(item.rd_wr == 0)inf.wr_data = item.wr_data;
			inf.reset = item.reset;
			inf.addr = item.addr;
		end
	endtask

 endclass
	

 class env;

	generator g;
	driver d;
	monitor m;
	scoreboard s;

	virtual intf inf;
    	virtual clk_if i_clk_if;
	
	mailbox drv_m, scb_m;

	function new();
		d = new();
		m = new();
		g = new();
		s = new();
		drv_m = new();
		scb_m = new();
	endfunction	

	virtual task run();
		g.drv_m = drv_m;
		d.drv_m = drv_m;
		m.scb_m = scb_m;
		s.scb_m = scb_m;

		d.inf = inf;
		m.inf = inf;
        	d.i_clk_if = i_clk_if;
		m.i_clk_if = i_clk_if;

		fork 
			g.run();
			d.run();
			s.run();
			m.run();
        	join_any
	endtask	

 endclass

 class test;

	env i_env;

	function new();
		i_env = new();
	endfunction
	
	virtual task run();
		i_env.run();
	endtask

 endclass

 module tb;
  
 	intf inf();
 	clk_if i_clk_if ();
 	memory i_memory(inf, i_clk_if.tb_clk);

 	initial begin
		test i_test = new();
		i_test.i_env.inf = inf;
    		i_test.i_env.i_clk_if = i_clk_if;
		i_test.run();	
   
   		#20000 $finish;
 	end
 	initial begin
		$dumpvars;
		$dumpfile("dump.vcd");
 	end
 
 endmodule