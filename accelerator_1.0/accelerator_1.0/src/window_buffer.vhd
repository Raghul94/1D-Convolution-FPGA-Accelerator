-- Raghul Shivakumar
-- Johnny Klarenbeek
--
-- Entity: window_buffer
-- Description: This entity buffers input from memory and assembles it into windows required for pipelines.
-- In this bufffer, the window shifts by one register every stride.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.user_pkg.all;
use work.config_pkg.all;

-------------------------------------------------------------------------------
-- Generic Descriptions
-- buffer_size 	: size of the buffer (required)
-- window_size  : size of the window (required)
-- width  		: The width of the input signal (required)
-- init   		: An initial value (of width bits) for the first "cycles" output
--          	  after a reset (required)
-------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Port Description
-- clk 		: clock
-- rst 		: reset
-- en 		: enable (active high), '0' stalls the delay pipeline
-- input 	: The input from the memory
-- output 	: The output of window of registers.
-------------------------------------------------------------------------------

entity window_buffer is
  generic(buffer_size :     positive := C_BUFFER_SIZE;
		  window_size :		positive := C_KERNEL_SIZE;
          width  	  :     positive := WORD_SIZE
         );
  port( clk      : in  std_logic;
        rst      : in  std_logic;
        en       : in  std_logic;
		full	 : out std_logic;
		empty	 : out std_logic;
		rd_en	 : in  std_logic;
		wr_en	 : in std_logic;
        input    : in  std_logic_vector(width-1 downto 0);
		output 	 : out REG_ARRAY(0 to buffer_size-1)
		);
end window_buffer;


architecture FF of window_buffer is

constant COUNTER_WIDTH : positive := 17;

signal regs: REG_ARRAY(buffer_size downto 0);
signal shift	: std_logic;
signal count,next_count    : std_logic_vector(COUNTER_WIDTH-1 downto 0) := (others=>'0');
signal empty_s,next_empty	: std_logic;
begin  -- BHV
	output(0 to C_BUFFER_SIZE-1) <= regs(C_BUFFER_SIZE-1 downto 0);
	full <= '0';
	regs(C_BUFFER_SIZE) <= input;
	
	U_REGISTERS: for i in 0 to C_BUFFER_SIZE-1 generate
		U_REG : entity work.reg
		generic map (
					width => width)
		port map(
				clk		=> clk,
				rst		=> rst,
				en		=> shift,
				input 	=> regs(C_BUFFER_SIZE - i),
				output	=> regs(C_BUFFER_SIZE - 1 - i)
				);
	end generate U_REGISTERS;
	process(clk,rst)
	begin 
		if (rst = '1') then
			count <= (others => '0');
			empty_s <= '1';
		elsif (rising_edge(clk)) then
			count <= next_count;
			empty_s <= next_empty;
		end if;
	end process;
	
	--- update shift reg data count
	process(count,wr_en,rd_en,en,empty_s)
		begin
			--- shift logic
			shift <= (en and wr_en and (empty_s or rd_en));

			--- default behavior: keep old value
			empty <= empty_s;
			next_empty <= empty_s;
			next_count <= count;
			
			--- empty state and counter control
			if(en = '1') then
				if(wr_en = '1' and rd_en = '0' and empty_s = '1') then
					if(unsigned(count) >= window_size - 1) then
						next_empty <= '0';
					end if;
					next_count <= std_logic_vector(unsigned(count) + to_unsigned(1,COUNTER_WIDTH));
				elsif(wr_en = '0' and rd_en = '1') then
					if(unsigned(count) > 0) then
						if(unsigned(count) >= window_size) then
							next_empty <= '1';
						end if;
						next_count <= std_logic_vector(unsigned(count) - to_unsigned(1,COUNTER_WIDTH));
					end if;
				end if;
			end if;
	end process;
			
end FF;
