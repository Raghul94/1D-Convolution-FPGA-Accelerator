-- Raghul Shivakumar
-- Johnny Klarenbeek

-- Produces outputs from buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.user_pkg.all;
use work.config_pkg.all;


entity output_generator is
  generic (window_size    :     positive := 128);
  port(
       input        : in  REG_ARRAY(window_size-1 downto 0);
       output       : out REG_ARRAY(window_size-1 downto 0)
	   );
end output_generator;

architecture bhv of output_generator is
begin
	output <= input;
end bhv;
