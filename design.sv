 `timescale 1ns/100ps 
 module memory(intf inf, input clk);
   logic [7:0] register [255:0];
   always_ff @(posedge clk)
	begin
      if(inf.reset) for( int i = 0; i<=255; i++) register[i] = 8'hff;
		else if(inf.rd_wr == 1 && inf.reset == 0) inf.rd_data <= register[inf.addr]; 
		else if(inf.rd_wr == 0 && inf.reset == 0) register[inf.addr] <= inf.wr_data;
	end
 endmodule