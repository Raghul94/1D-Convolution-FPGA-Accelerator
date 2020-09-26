library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config_pkg.all;
use work.user_pkg.all;


entity dram_rd_ram0_jk is
  port (
    dram_clk : in STD_LOGIC;
    user_clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    clear : in STD_LOGIC;
    go : in STD_LOGIC;
    rd_en : in STD_LOGIC;
    stall : in STD_LOGIC;
    start_addr : in STD_LOGIC_VECTOR ( 14 downto 0 );
    size : in STD_LOGIC_VECTOR ( 16 downto 0 );
    valid : out STD_LOGIC;
    data : out STD_LOGIC_VECTOR ( 15 downto 0 );
    done : out STD_LOGIC;
	
    dram_ready : in STD_LOGIC;
    dram_rd_en : out STD_LOGIC;
    dram_rd_addr : out STD_LOGIC_VECTOR ( 14 downto 0 );
    dram_rd_data : in STD_LOGIC_VECTOR ( 31 downto 0 );
    dram_rd_valid : in STD_LOGIC;
    dram_rd_flush : out STD_LOGIC
  );
end dram_rd_ram0_jk;

architecture STR of dram_rd_ram0_jk is

    signal f32_empty : STD_LOGIC;
    signal f32_prog_full : STD_LOGIC;
    signal f32_wr_rst_busy : STD_LOGIC;
    signal f32_rd_rst_busy : STD_LOGIC;
	signal rst_int : STD_LOGIC;
	signal go_s : STD_LOGIC;
	signal addr_valid : STD_LOGIC;
	signal ag_en : STD_LOGIC;
	signal counter_en : STD_LOGIC;
    signal done_int: STD_LOGIC;
	
COMPONENT fifo_32_16
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    prog_full : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT dma_ctrl
  PORT (	
    user_clk   : in  std_logic;
    dram_clk  : in  std_logic;
    rst       : in  std_logic;
    go        : in  std_logic;
	go_s	  : out std_logic;

	dram_ready : in std_logic;
	prog_full  : in std_logic;
	addr_valid : in std_logic;
	ag_en      : out std_logic;
	dram_rd_en : out std_logic;
	dram_rd_flush : out std_logic
  );
END COMPONENT;

COMPONENT dma_addr_gen
  PORT (	
    dram_clk    : in  std_logic;
    rst         : in  std_logic;
    size        : in  std_logic_vector(16 downto 0);
	start_addr  : in  std_logic_vector(14 downto 0);
    go          : in  std_logic;
    en          : in  std_logic;
    addr		: out std_logic_vector(14 downto 0);
	addr_valid	: out std_logic
  );
END COMPONENT;

COMPONENT data_counter
  PORT (	
    user_clk    : in  std_logic;
    rst         : in  std_logic;
	clear		: in  std_logic;
    size        : in  std_logic_vector(16 downto 0);
    go          : in  std_logic;
    en          : in  std_logic;
	done		: out std_logic
  );
END COMPONENT;


begin
	
	-- clear and reset signals perform the same function internally
	process(rst,clear,done_int)
	begin
		rst_int <= rst or clear or done_int;
	end process;
	
	process(f32_empty,done_int)
	begin
		---valid <= (not f32_empty);
		valid <= (not f32_empty) and (not done_int);
	end process;
	
	process(f32_empty, stall, rd_en)
	begin
		counter_en <= (not f32_empty) and (not stall) and rd_en;
	end process;
	
	
	process(done_int)
	begin
	   done <= done_int;
	end process;

	---done <= '1';
	---valid <= '1';
  
U_DMA_CTRL : dma_ctrl
  PORT MAP (	
    user_clk  => user_clk,
    dram_clk  => dram_clk,
    rst       => rst_int,
    go        => go,
	go_s	  => go_s,

	dram_ready 		=> dram_ready,
	prog_full  		=> f32_prog_full,
	addr_valid 		=> addr_valid,
	ag_en      		=> ag_en,
	dram_rd_en 		=> dram_rd_en,
	dram_rd_flush 	=> dram_rd_flush
  );

U_DMA_ADDR_GEN : dma_addr_gen
  PORT MAP (	
    dram_clk    => dram_clk,
    rst         => rst_int,
    size        => size,
	start_addr  => start_addr,
    go          => go_s,
    en          => ag_en,
    addr		=> dram_rd_addr,
	addr_valid	=> addr_valid
  );

U_DATA_COUNTER :  data_counter
  PORT MAP (	
    user_clk    => user_clk,
    rst         => rst,
	clear		=> clear,
    size        => size,
    go          => go,
    en          => counter_en,
	done		=> done_int
  );
  
  
U_FIFO_32_16 : fifo_32_16
  PORT MAP (
    rst => rst_int,
    wr_clk => dram_clk,
    rd_clk => user_clk,
    din(31 downto 16) => dram_rd_data(15 downto 0),
    din(15 downto 0) => dram_rd_data(31 downto 16),
    wr_en => dram_rd_valid,
    rd_en => rd_en,
    dout => data,
    full => open,
    empty => f32_empty,
    prog_full => f32_prog_full,
    wr_rst_busy => f32_wr_rst_busy,
    rd_rst_busy => f32_rd_rst_busy
  );
  
  
end STR;
