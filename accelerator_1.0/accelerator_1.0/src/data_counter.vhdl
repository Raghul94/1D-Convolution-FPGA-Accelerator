library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config_pkg.all;
use work.user_pkg.all;


entity data_counter is
  port (
    user_clk    : in  std_logic;
    rst         : in  std_logic;
	clear		: in  std_logic;
    size        : in  std_logic_vector(16 downto 0);
    go          : in  std_logic;
    en          : in  std_logic;
	done		: out std_logic
	);
end data_counter;

architecture FSM of data_counter is

  type state_type is (S_RESET, S_WAIT_GO, S_INIT, S_COUNT,
                      S_DONE);
  signal state, next_state    : state_type;
  signal size_s, next_size_s : std_logic_vector(16 downto 0);
  signal count_s, next_count_s   : std_logic_vector(15 downto 0);

begin 
  process (user_clk, rst)
  begin
    if (rst = '1') then
      count_s   <= (others => '0');
      size_s <= (others => '0');
	  state    <= S_RESET;
    elsif (user_clk'event and user_clk = '1') then
      count_s   <= next_count_s;
      size_s <= next_size_s;
	  state    <= next_state;
    end if;
  end process;

  process(state, count_s, size_s, go, en, size)
  begin
    next_size_s <= size_s;
    next_count_s <= count_s;
    next_state <= state;
	done <= '0';
	
    case state is
	  when S_RESET =>
		next_state <= S_WAIT_GO;
      when S_WAIT_GO =>
		next_size_s <= size;
		--- delay for one extra cycle if only reading 1 address (prop delay)
		if(size = std_logic_vector(to_unsigned(1, 17))) then
			next_count_s <= std_logic_vector(to_unsigned(0, 16));
        else
			next_count_s <= std_logic_vector(to_unsigned(1, 16));
		end if;
		if (go = '1') then
          next_state    <= S_COUNT;
        end if;
      when S_COUNT =>
		-- en stalls the counter (but does not reset it).
		-- should be driven by FIFO valid (~empty) signal
		if(en = '1') then
			if(unsigned(count_s) < unsigned(size_s)) then
				next_count_s <= std_logic_vector(unsigned(count_s)+1);
			end if;
		end if;
		
		if(unsigned(count_s) >= unsigned(size_s)) then 
			next_state <= S_DONE;
		end if;
	  when S_DONE =>
	    done <= '1';
		if(go = '0' and clear = '1') then
		  next_state <= S_WAIT_GO;
		end if;
      when others => null;
    end case;
  end process;

end FSM;