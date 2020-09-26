-- Raghul Shivakumar
-- Johnny Klarenbeek

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity window_buffer_tb is
end window_buffer_tb;

architecture behavior of window_buffer_tb is

    constant TEST_SIZE : integer := 256;
    constant MAX_CYCLES : integer  := TEST_SIZE*4;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
	signal en  : std_logic := '1';

    signal wr_en   : std_logic := '0';
	signal kernel_wr_en : std_logic := '0';
    --signal mmap_wr_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal wr_data : std_logic_vector(15 downto 0) := (others => '0');

    signal rd_en   : std_logic   	:= '0';
	
    signal mmap_rd_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal rd_data : REG_ARRAY(0 to 2);

    signal sim_done : std_logic := '0';
	signal full: std_logic := '0';
	signal kernel_full : std_logic := '0';
	signal kernel_empty : std_logic := '0';
	signal empty: std_logic := '1';
	signal kernel_input : std_logic_vector(15 downto 0) := (others => '0');
	signal kernel_output :REG_ARRAY(0 to 2);

begin
	
    UUT : entity work.window_buffer
		generic map(
				buffer_size => 3,
				window_size => 3)
			
        port map (
            clk         => clk,
            rst         => rst,
			en			=> en,
			full		=> full,
			empty		=> empty,
			rd_en		=> rd_en,
			wr_en		=> wr_en,
			input		=> wr_data,
			output		=> rd_data
			);
    UUT_KERNEL_BUFFER : entity work.kernel_buffer
		generic map(
				buffer_size => 3,
				window_size => 3)
			
        port map (
            clk         => clk,
            rst         => rst,
			en			=> en,
			full		=> kernel_full,
			empty		=> kernel_empty,
			rd_en		=> '0',
			wr_en		=> kernel_wr_en,
			input		=> kernel_input,
			output		=> kernel_output
			);
    -- toggle clock
    clk <= not clk after 5 ns when sim_done = '0' else clk;

    -- process to test different inputs

    write_data: process
	variable j : natural:=0;
	variable m : natural:=0;
    begin
	    -- reset circuit  
        rst <= '1';
        wait for 200 ns;
        rst <= '0';
        wait until clk'event and clk = '1';
        wait until clk'event and clk = '1';
		-- Writing to buffer
		for i in 0 to 100 loop
			if(j = 10) then 
				wait for 100 ns;
			end if;
			if(full /= '1') then
				wr_en 	<= '1';
				wr_data <=	std_logic_vector(to_unsigned((j*4) mod 256, 8) &
												 to_unsigned((j*4+1) mod 256, 8));
				j:= j+1;
			end if;
			if(kernel_full /= '1') then
				kernel_wr_en 	<= '1';
				kernel_input <=	std_logic_vector(to_unsigned((m*4) mod 256, 8) &
												 to_unsigned((m*4+1) mod 256, 8));
				m := m+1;
			end if;


			wait until clk'event and clk = '1';
		end loop;
    end process write_data;

	rd_en <= not(empty);

		--Reading from buffer

end behavior;
