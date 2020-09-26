library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl is
    port(clk          : in  std_logic;
         rst          : in  std_logic;
         go           : in  std_logic;
         mem_in_go    : out std_logic;
         mem_out_go   : out std_logic;
         mem_in_clear : out std_logic;
         mem_out_clear : out std_logic;
         mem_out_done : in  std_logic;
         done         : out std_logic;
		 signal_buffer_rd_en : out std_logic;
		 signal_buffer_wr_en : out std_logic;
		 signal_buffer_full : in std_logic;
		 signal_buffer_empty : in std_logic;
		 kernel_buffer_empty : in std_logic;
		 ram0_rd_valid 		 : in std_logic;
		 ram0_rd_rd_en		 : out std_logic;
		 ram1_wr_ready		 : in std_logic;
		 valid_in			 : out std_logic
		 );
end ctrl;

architecture bhv of ctrl is

    type STATE_TYPE is (S_WAIT_0, S_WAIT_1, S_WAIT_RAM0_RD_VALID, S_WAIT_DONE);
    signal state, next_state   : STATE_TYPE;
    signal done_s, next_done_s : std_logic;
	signal valid_s, next_valid_s : std_logic;

begin

    process(clk, rst)
    begin
        if (rst = '1') then
            state  <= S_WAIT_0;
            done_s <= '0';
			valid_s <= '0';
        elsif (clk = '1' and clk'event) then
            state  <= next_state;
            done_s <= next_done_s;
			valid_s <= next_valid_s;
        end if;
    end process;

    process(go, state, done_s, mem_out_done, signal_buffer_full, signal_buffer_empty, ram0_rd_valid, ram1_wr_ready, kernel_buffer_empty)
    begin

        -- defaults
        done        <= done_s;
        next_done_s <= done_s;
        next_state  <= state;
		next_valid_s <= valid_s;

        mem_in_go     <= '0';
        mem_out_go    <= '0';
        mem_in_clear  <= '0';
        mem_out_clear <= '0';
		
		valid_in <= '0';
		signal_buffer_rd_en <= '0';
		
		--
		signal_buffer_wr_en <= '0';
		ram0_rd_rd_en <= '0';
        case state is
            when S_WAIT_0 =>

				next_valid_s <= '0';
                mem_in_clear  <= '1';
                mem_out_clear <= '1';

                if (go = '0') then
                    next_state <= S_WAIT_1;
                end if;

            when S_WAIT_1 =>

				next_valid_s <= '0';
                if (go = '1') then
                    mem_in_go   <= '1';
                    mem_out_go  <= '1';
                    next_done_s <= '0';
                    done        <= '0';  -- make sure done updated immediately
                    next_state  <= S_WAIT_RAM0_RD_VALID;
                end if;

			when S_WAIT_RAM0_RD_VALID =>
			
				next_valid_s <= '0';
				if (ram0_rd_valid = '1') then
					next_state <= S_WAIT_DONE;
				end if;
				
				
            when S_WAIT_DONE =>
				
                if (mem_out_done = '1') then
                    next_done_s <= '1';  -- could potentially update done also
                                         -- if we don't want to wait one cycle
                    next_state  <= S_WAIT_0;
                else
					if (signal_buffer_empty = '0' or valid_s = '1') then
						valid_in <= '1';
						next_valid_s <= '1';
					end if;
					
					--if(ram0_rd_valid = '1') then
						if(signal_buffer_empty = '1') then
							ram0_rd_rd_en <= '1';
							signal_buffer_wr_en <= '1';
						elsif(ram1_wr_ready = '1') then
							signal_buffer_wr_en <= '1';
							signal_buffer_rd_en <= '1';
							ram0_rd_rd_en <= '1';
							--valid_in <= '1';
						end if;
					--end if;
				end if;
            when others => null;
        end case;
    end process;
end bhv;
