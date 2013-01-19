----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:03:38 10/25/2012 
-- Design Name: 
-- Module Name:    topModule9 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.NUMERIC_STD.ALL;

entity topModule9 is
    Port ( clk : in  STD_LOGIC;
           btn : in  STD_LOGIC_VECTOR(3 downto 0);
			  rx : in  STD_LOGIC;
           seg : out  STD_LOGIC_VECTOR (6 downto 0);
           an : out  STD_LOGIC_VECTOR (3 downto 0);
           dp : out  STD_LOGIC);
           
end topModule9;

architecture Behavioral of topModule9 is

	signal outOfReceiver,outOfReceiver1, outOfReceiver1Next, outOfReceiver2, outOfReceiver2Next :  std_logic_vector(7 downto 0);
	signal strobe, rx_busy, rxMid, rxInternal : std_logic;
	signal data_in_segment : std_logic_vector(15 downto 0);
	

begin

process(clk)
begin
	if (rising_edge(clk)) then
		rxInternal <= rxMid;
		rxMid <= rx;
		if(btn(0) = '1') then
			outOfReceiver1 <= (others => '0');
			outOfReceiver2 <= (others => '0');
		else
			outOfReceiver1 <= outOfReceiver1Next;
			outOfReceiver2 <= outOfReceiver2Next;
		end if;
	end if;
end process;

--------------RECEIVER INSTANTIATION-------------------------------------------

	receiver : entity work.rx
	port map ( clk => clk, rst => btn(0), rx_in =>rxInternal, data_out => outOfReceiver, data_strobe =>strobe,  rx_busy =>rx_busy);
--------------------------------------------------------------------------------


---------------------------SEVEN SEGMENT DISPLAY------------------------------------
	sevenDisplay : entity work.seven_segment_display
		port map( clk=>clk, data_in=> data_in_segment, dp_in=>"0100", 
		          blank=>"0000", seg=>seg, dp=>dp, an=>an		
		);
		
		data_in_segment <= outOfReceiver2 & outOfReceiver1;
		
		outOfReceiver2Next <= (others => '0') when btn(0) = '1' else
									 outOfReceiver1 when strobe = '1' else
									 outOfReceiver2;
									 
		outOfReceiver1Next <= (others => '0') when btn(0) = '1' else
									 outOfReceiver when strobe ='1' else
									 outOfReceiver1;
----------------------------------------------------------------------------------------


end Behavioral;

