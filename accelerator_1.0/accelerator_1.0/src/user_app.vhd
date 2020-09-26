-- Greg Stitt
-- University of Florida

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config_pkg.all;
use work.user_pkg.all;
use work.math_custom.all;

entity user_app is
    port (
        clks   : in  std_logic_vector(NUM_CLKS_RANGE);
        rst    : in  std_logic;
        sw_rst : out std_logic;

        -- memory-map interface
        mmap_wr_en   : in  std_logic;
        mmap_wr_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        mmap_wr_data : in  std_logic_vector(MMAP_DATA_RANGE);
        mmap_rd_en   : in  std_logic;
        mmap_rd_addr : in  std_logic_vector(MMAP_ADDR_RANGE);
        mmap_rd_data : out std_logic_vector(MMAP_DATA_RANGE);

        -- DMA interface for RAM 0
        -- read interface
        ram0_rd_rd_en : out std_logic;
        ram0_rd_clear : out std_logic;
        ram0_rd_go    : out std_logic;
        ram0_rd_valid : in  std_logic;
        ram0_rd_data  : in  std_logic_vector(RAM0_RD_DATA_RANGE);
        ram0_rd_addr  : out std_logic_vector(RAM0_ADDR_RANGE);
        ram0_rd_size  : out std_logic_vector(RAM0_RD_SIZE_RANGE);
        ram0_rd_done  : in  std_logic;
        -- write interface
        ram0_wr_ready : in  std_logic;
        ram0_wr_clear : out std_logic;
        ram0_wr_go    : out std_logic;
        ram0_wr_valid : out std_logic;
        ram0_wr_data  : out std_logic_vector(RAM0_WR_DATA_RANGE);
        ram0_wr_addr  : out std_logic_vector(RAM0_ADDR_RANGE);
        ram0_wr_size  : out std_logic_vector(RAM0_WR_SIZE_RANGE);
        ram0_wr_done  : in  std_logic;

        -- DMA interface for RAM 1
        -- read interface
        ram1_rd_rd_en : out std_logic;
        ram1_rd_clear : out std_logic;
        ram1_rd_go    : out std_logic;
        ram1_rd_valid : in  std_logic;
        ram1_rd_data  : in  std_logic_vector(RAM1_RD_DATA_RANGE);
        ram1_rd_addr  : out std_logic_vector(RAM1_ADDR_RANGE);
        ram1_rd_size  : out std_logic_vector(RAM1_RD_SIZE_RANGE);
        ram1_rd_done  : in  std_logic;
        -- write interface
        ram1_wr_ready : in  std_logic;
        ram1_wr_clear : out std_logic;
        ram1_wr_go    : out std_logic;
        ram1_wr_valid : out std_logic;
        ram1_wr_data  : out std_logic_vector(RAM1_WR_DATA_RANGE);
        ram1_wr_addr  : out std_logic_vector(RAM1_ADDR_RANGE);
        ram1_wr_size  : out std_logic_vector(RAM1_WR_SIZE_RANGE);
        ram1_wr_done  : in  std_logic
        );
end user_app;

architecture default of user_app is

    signal go        : std_logic;
    signal sw_rst_s  : std_logic;
    signal rst_s     : std_logic;
    signal size      : std_logic_vector(RAM0_RD_SIZE_RANGE);
    signal done      : std_logic;
	signal signal_buffer_full : std_logic;
	signal signal_buffer_empty : std_logic;
	signal signal_buffer_rd_en : std_logic;
	signal signal_buffer_wr_en : std_logic;
	signal mult_add_input_1_array,mult_add_input_2_array : REG_ARRAY(0 to C_BUFFER_SIZE-1);
	signal mult_add_input_1,mult_add_input_2 : std_logic_vector(C_BUFFER_SIZE*WORD_SIZE - 1 downto 0);
	signal buffer_size : positive := 128;
	signal window_size : positive := 128;
    signal kernel_data : std_logic_vector(KERNEL_WIDTH_RANGE);
    signal kernel_load :std_logic;
    signal kernel_loaded : std_logic;
	signal valid_in : std_logic;
	signal kernel_buffer_empty : std_logic;
	signal ram1_wr_data_unclipped : std_logic_vector(WORD_SIZE+WORD_SIZE+clog2(C_KERNEL_SIZE)-1 downto 0);
	signal sel : unsigned(WORD_SIZE+WORD_SIZE+clog2(C_KERNEL_SIZE)-1 downto 0);
	
	--Declaring Functions
	-- converts from input_array to std_logic_vector
  function vectorize(input        : REG_ARRAY;
                     arraySize    : natural;
                     elementWidth : positive) return std_logic_vector is
    variable temp : std_logic_vector(arraySize*elementWidth-1 downto 0);
  begin
    for i in 0 to arraySize-1 loop
      temp((i+1)*elementWidth-1 downto i*elementWidth) := input(input'left+i);
    end loop;

    return temp;
  end function;
  


begin
	sel <= unsigned(ram1_wr_data_unclipped);
	mult_add_input_1 <= vectorize(mult_add_input_1_array, C_BUFFER_SIZE, WORD_SIZE);
	mult_add_input_2 <= vectorize(mult_add_input_2_array, C_KERNEL_SIZE, WORD_SIZE);
	
	ram1_wr_data <= "1111111111111111"  when sel > to_unsigned(65535,40) else
					ram1_wr_data_unclipped(WORD_SIZE-1 downto 0);
	ram0_rd_addr <= std_logic_vector(to_unsigned(0, C_RAM0_ADDR_WIDTH));
    ram0_rd_size <= std_logic_vector(unsigned(size) + 2*(C_KERNEL_SIZE-1));	
	ram1_wr_addr <= std_logic_vector(to_unsigned(0, C_RAM0_ADDR_WIDTH));
	ram1_wr_size <= std_logic_vector(unsigned(size) + (C_KERNEL_SIZE-1));
	
    U_MMAP : entity work.memory_map
        port map (
            clk     => clks(C_CLK_USER),
            rst     => rst,
            wr_en   => mmap_wr_en,
            wr_addr => mmap_wr_addr,
            wr_data => mmap_wr_data,
            rd_en   => mmap_rd_en,
            rd_addr => mmap_rd_addr,
            rd_data => mmap_rd_data,


            -- dma interface for accessing DRAM from software
            ram0_wr_ready => ram0_wr_ready,
            ram0_wr_clear => ram0_wr_clear,
            ram0_wr_go    => ram0_wr_go,
            ram0_wr_valid => ram0_wr_valid,
            ram0_wr_data  => ram0_wr_data,
            ram0_wr_addr  => ram0_wr_addr,
            ram0_wr_size  => ram0_wr_size,
            ram0_wr_done  => ram0_wr_done,

            ram1_rd_rd_en => ram1_rd_rd_en,
            ram1_rd_clear => ram1_rd_clear,
            ram1_rd_go    => ram1_rd_go,
            ram1_rd_valid => ram1_rd_valid,
            ram1_rd_data  => ram1_rd_data,
            ram1_rd_addr  => ram1_rd_addr,
            ram1_rd_size  => ram1_rd_size,
            ram1_rd_done  => ram1_rd_done,

            -- circuit interface from software
            go             => go,
            sw_rst         => sw_rst_s,
            signal_size    => size,
            kernel_data    => kernel_data,
            kernel_load    => kernel_load,
            kernel_loaded  => kernel_loaded,
			done    	   => done
            );

    rst_s  <= rst or sw_rst_s;
    sw_rst <= sw_rst_s;

    U_CTRL : entity work.ctrl
        port map (
            clk           => clks(C_CLK_USER),
            rst           => rst_s,
            go            => go,
            mem_in_go     => ram0_rd_go,
            mem_out_go    => ram1_wr_go,
            mem_in_clear  => ram0_rd_clear,
            mem_out_clear => ram1_wr_clear,
            mem_out_done  => ram1_wr_done,
            done          => done,
			signal_buffer_rd_en => signal_buffer_rd_en,
			signal_buffer_wr_en => signal_buffer_wr_en,
			signal_buffer_full  => signal_buffer_full,
			signal_buffer_empty => signal_buffer_empty,
			kernel_buffer_empty => kernel_buffer_empty,
			ram0_rd_valid 		=> ram0_rd_valid,
			ram0_rd_rd_en		=> ram0_rd_rd_en,
			ram1_wr_ready		=> ram1_wr_ready,
			valid_in	  		=> valid_in);

	U_SIGNAL_BUFFER: entity work.window_buffer
		generic map(
				buffer_size => C_BUFFER_SIZE,
				window_size => C_KERNEL_SIZE)
		port map (
			clk			=> clks(C_CLK_USER),			
			rst         => rst_s,
			en          => std_logic'('1'),
			full	    => signal_buffer_full,
			empty	    => signal_buffer_empty,
			rd_en	    => signal_buffer_rd_en,
			wr_en	    => signal_buffer_wr_en,
			input       => ram0_rd_data,
			output      => mult_add_input_1_array);
	U_KERNEL_BUFFER: entity work.kernel_buffer
		port map (
			clk			=> clks(C_CLK_USER),
			rst			=> rst_s,
			en			=> std_logic'('1'),
			full		=> kernel_loaded,
			empty		=> kernel_buffer_empty,
			rd_en		=> std_logic'('0'),
			wr_en		=> kernel_load,
			input		=> kernel_data,
			output		=> mult_add_input_2_array);
	U_MULT_ADD_TREE: entity work.mult_add_tree
		generic map(
			num_inputs	=> C_KERNEL_SIZE,
			input1_width => WORD_SIZE,
			input2_width => WORD_SIZE)
		port map(
			clk => clks(C_CLK_USER),
			rst => rst,
			en => std_logic'('1'),
			input1 => mult_add_input_1,
			input2 => mult_add_input_2,
			output => ram1_wr_data_unclipped);

--Delay entity to delay the valid output signal from signal buffer

	U_DELAY: entity work.delay
		generic map(
			cycles => 8,
			width => 1,
			init(0)  => '0')
		port map(
			clk => clks(C_CLK_USER),
			rst => rst_s,
			en  => '1',
			input(0) => valid_in,
			output(0) => ram1_wr_valid);
end default;
