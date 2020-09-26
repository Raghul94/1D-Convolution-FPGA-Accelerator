-- Raghul Shivakumar
-- Johnny Klarenbeek
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.user_pkg.all;
use work.config_pkg.all;


entity valid is
generic(
		depth : natural);
port(
	clk : in std_logic;
	rst : in std_logic;
	en : in std_logic;
	input : in std_logic;
	output : out std_logic);
end valid;

architecture structural of valid is
begin
U_DELAY: entity work.delay
	generic map(
			cycles => depth,
			width => 1,
			init(0) => '0')
	port map(
			clk => clk,
			rst => rst,
			en => en,
			input(0) => input,
			output(0) => output);		
end structural;