library ieee;
use ieee.std_logic_1164.all;

entity dma_ctrl is
  port (
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
end dma_ctrl;

architecture FSM of dma_ctrl is

  type state_type_src is (S_RESET, S_WAIT_FOR_ACK_HIGH, S_WAIT_FOR_ACK_LOW, S_WAIT_FOR_GO_LOW);
  type state_type_dest is (S_RESET, S_WAIT_FOR_REQ_LOW, S_ASSERT_GO_S, S_WAIT_ADDR_VALID);
  signal state_src, next_state_src   : state_type_src;
  signal state_dest, next_state_dest : state_type_dest;
  
  ---- user_clk domain:
  signal req : std_logic;
  signal ack_s1, ack_s2 : std_logic;
  
  ---- dram_clk domain:
  signal ack : std_logic;
  signal req_s1, req_s2 : std_logic;
  
begin

  -----------------------------------------------------------------------------
  -- State machine in source domain that sends to dest domain and then waits
  -- for an ack
  process(user_clk, rst)
  begin
	-- State control + dual flop synchronizer (dest --> src ack)
    if (rst = '1') then
      state_src <= S_RESET;
      ack_s1 <= '0';
	  ack_s2 <= '0';
    elsif(user_clk'event and user_clk = '1') then
      state_src <= next_state_src;
	  ack_s1 <= ack;
	  ack_s2 <= ack_s1;
    end if;
  end process;

  -- simple handshake synchronizer (source side)
  --   after receiving ACK, we wait for the falling edge of 'go' before accepting further input
  process(go, ack_s2, state_src)
  begin
	req <= '0';
	next_state_src <= state_src;
	
	case state_src is
      when S_RESET =>    
        if (go = '1') then
          next_state_src <= S_WAIT_FOR_ACK_HIGH;        
        end if;
      when S_WAIT_FOR_ACK_HIGH =>
        req <= '1';
        if (ack_s2 = '1') then
          next_state_src <= S_WAIT_FOR_ACK_LOW;
        end if;
      when S_WAIT_FOR_ACK_LOW =>
        if (ack_s2 = '0') then
          next_state_src <= S_WAIT_FOR_GO_LOW;
        end if;
      when S_WAIT_FOR_GO_LOW =>
        if (go = '0') then
          next_state_src <= S_RESET;
        end if;
      when others => null;
    end case;
  end process;  

  -----------------------------------------------------------------------------
  -- State machine in dest domain that waits for source domain to send signal,
  -- which then gets acknowledged
  process(dram_clk, rst)
  begin
	-- State control + dual flop synchronizer (src --> dest req)
    if (rst = '1') then
      state_dest <= S_RESET;
      req_s1 <= '0';
	  req_s2 <= '0';
    elsif(dram_clk'event and dram_clk = '1') then
      state_dest <= next_state_dest;
	  req_s1 <= req;
	  req_s2 <= req_s1;
    end if;
  end process;

  -- simple handshake synchronizer (dest side)
  --   after receiving REQ, send back the acknowledge until the falling edge of REQ
  --   go_s is asserted for one cycle after the falling edge of REQ
  process(req_s2, state_dest)
  begin
  
	dram_rd_flush <= '0';
	go_s <= '0';
	ack <= '0';
	next_state_dest <= state_dest;
	
	case state_dest is
      when S_RESET =>    
        if (req_s2 = '1') then
          next_state_dest <= S_WAIT_FOR_REQ_LOW;        
        end if;
      when S_WAIT_FOR_REQ_LOW =>
        ack <= '1';
        if (req_s2 = '0') then
          next_state_dest <= S_ASSERT_GO_S;
        end if;
      when S_ASSERT_GO_S =>
        go_s <= '1';
		dram_rd_flush <= '1';
		next_state_dest <= S_WAIT_ADDR_VALID;
	  when S_WAIT_ADDR_VALID =>
		go_s <= '1';
		if (addr_valid = '1') then
			next_state_dest <= S_RESET;
		end if;
	  when others => null;
    end case;
  end process;  
  
  --- combinatorial logic to control dram read and address generator
  process(dram_ready, prog_full, addr_valid)
  begin
	ag_en <= dram_ready and (not prog_full);
	dram_rd_en <= addr_valid and dram_ready and (not prog_full);
  end process;
  
end FSM;
