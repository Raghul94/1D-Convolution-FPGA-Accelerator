library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config_pkg.all;
use work.user_pkg.all;


entity dma_addr_gen is
  port (
    dram_clk    : in  std_logic;
    rst         : in  std_logic;
    size        : in  std_logic_vector(16 downto 0);
	start_addr  : in  std_logic_vector(14 downto 0);
    go          : in  std_logic;
	-- en = dram_ready & ~stall & ~prog_full & take_it_tg_ff & take_it_tg_sync && state 
	-- 	state = reg(dram_clk,take_it_tg_ff_reg)
	--	take_it_tg_ff = reg(dram_clk,take_it_tg_ff_sync)
	-- use en like a stall signal - stay in active state but do not count up
    en          : in  std_logic;
    addr		: out std_logic_vector(14 downto 0);
	addr_valid	: out std_logic
	);
end dma_addr_gen;

architecture FSM of dma_addr_gen is
  type state_type is (S_RESET, S_WAIT_GO, S_INIT, S_COUNT_ADDR,
                      S_DONE);
  signal state, next_state    : state_type;
  signal size_s, next_size_s : std_logic_vector(16 downto 0);
  signal start_addr_s, next_start_addr_s : std_logic_vector(14 downto 0);
  signal addr_s, next_addr_s   : std_logic_vector(15 downto 0);

begin 
  process (dram_clk, rst)
  begin
    if (rst = '1') then
      addr_s   <= (others => '0');
      size_s <= (others => '0');
	  start_addr_s <= (others => '0');
      state    <= S_RESET;
    elsif (dram_clk'event and dram_clk = '1') then
      addr_s   <= next_addr_s;
      size_s <= next_size_s;
	  start_addr_s <= next_start_addr_s;
      state    <= next_state;
    end if;
  end process;

  process(state, addr_s, size_s, start_addr_s, go, en, size, start_addr)
  begin
    next_size_s <= size_s;
    next_addr_s <= addr_s;
	next_start_addr_s <= start_addr_s;
    next_state <= state;
    addr_valid <= '0';
	
    case state is
	  when S_RESET =>
		next_state <= S_WAIT_GO;
      when S_WAIT_GO =>
		next_start_addr_s <= start_addr;
		next_size_s <= size;
        next_addr_s <= std_logic_vector(to_unsigned(0, 16));
        if (go = '1') then
          next_state    <= S_INIT;
        end if;
      when S_INIT =>
        next_addr_s <= '0' & start_addr_s;
		next_state <= S_COUNT_ADDR;
      when S_COUNT_ADDR =>
		-- en stalls the counter (but does not reset it).
		-- should be driven by external stall/prog_full/dram_ready logic
		addr_valid <= '1';
		if(en = '1') then
			if(unsigned(size_s) > 0) then
				next_size_s <= std_logic_vector(unsigned(size_s)-1);
				next_addr_s <= std_logic_vector(unsigned(addr_s)+1);
			end if;
		end if;
		
		if(size_s = std_logic_vector(to_unsigned(0, 17))) then 
			next_state <= S_DONE;
		end if;
	  when S_DONE =>
		if(go = '0') then
		  next_state <= S_WAIT_GO;
		end if;
      when others => null;
    end case;
  end process;

  addr <= addr_s(14 downto 0);

end FSM;