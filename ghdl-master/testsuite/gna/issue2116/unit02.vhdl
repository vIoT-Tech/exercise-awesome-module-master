library ieee;use ieee.numeric_std.all;use ieee.std_logic_1164.all;entity generic_fifo_fwft_inst is
port(c:std_logic;e:integer:=0;a:std_logic_vector(0 downto 0);dataout:out std_logic_vector(0 to 0);e0:std_logic;l:std_logic;r:std_logic);end;architecture t of generic_fifo_fwft_inst is type mystream_t is record
x:std_logic_vector(0 downto 0);y:integer range 0 to 0;end record;signal m:mystream_t;signal i:mystream_t;begin dataout<=min.x((0));r(((0)));o generic map(0);end architecture;