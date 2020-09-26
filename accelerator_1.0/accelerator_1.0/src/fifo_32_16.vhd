----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/10/2018 07:42:53 PM
-- Design Name: 
-- Module Name: fifo_32_16 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.user_pkg.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_32_16 is
Port ( 
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
end fifo_32_16;

architecture Behavioral of fifo_32_16 is
COMPONENT fifo_generator_32_16
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
begin
U_FIFO3216: fifo_generator_32_16
  PORT MAP (
    rst => rst,
    wr_clk => wr_clk,
    rd_clk => rd_clk,
    din => din,
    wr_en => wr_en,
    rd_en => rd_en,
    dout => dout,
    full => full,
    empty => empty,
    prog_full => prog_full,
    wr_rst_busy => wr_rst_busy,
    rd_rst_busy => rd_rst_busy
  );

end Behavioral;
