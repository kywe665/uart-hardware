----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:39:48 10/17/2012 
-- Design Name: 
-- Module Name:    tx - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tx is
	generic (
		CLK_RATE: natural := 50000000;
		BAUD_RATE: natural := 19200
	);
	Port (
		clk : in  STD_LOGIC;
      rst : in  STD_LOGIC;
      data_in : in  STD_LOGIC_VECTOR (7 downto 0);
      send_character : in  STD_LOGIC;
      tx_out : out  STD_LOGIC;
      tx_busy : out  STD_LOGIC
	);
end tx;

architecture Behavioral of tx is
	function log2c(n: integer) return integer is
		variable m, p: integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m + 1;
			p := p * 2;
		end loop;
		return m;
	end log2c;
	
	constant BIT_COUNTER_MAX_VAL : Natural := CLK_RATE / BAUD_RATE - 1;
	constant BIT_COUNTER_BITS : Natural := log2c(BIT_COUNTER_MAX_VAL);
	signal tx_timer : unsigned(BIT_COUNTER_BITS-1 downto 0);
	signal tx_bit, clrTimer, load, shift, shift_out, start, stop : std_logic;
	signal current_shift : std_logic_vector(7 downto 0);
	
	type state_type is (idle, strt, b0,b1,b2,b3,b4,b5,b6,b7, stp, ret);
	signal state_reg, state_next : state_type;
	
begin

--STATE MACHINE
	process(clk, rst)
	begin
		if(rst = '1') then
			state_reg <= idle;
		elsif(clk'event and clk = '1') then
			state_reg <= state_next;
		end if;
	end process;
	
	process(state_reg, send_character, tx_bit)
	begin
		--defaults
		tx_busy <= '1';
		state_next <= state_reg;
		start <= '0';
		stop <= '0';
		load <= '0';
		shift <= '0';
		clrTimer <= '0';
		case state_reg is
			when idle =>
				clrTimer <= '1';
				stop <= '1';
				tx_busy <= '0';
				if(send_character = '1') then
					state_next <= strt;
					load <= '1';
				end if;
			when strt =>
				start <= '1';
				if(tx_bit = '1') then
					shift <= '1';
					state_next <= b0;
				end if;
			when stp =>
				stop <= '1';
				if(tx_bit = '1') then
					state_next <= ret;
				end if;
			when ret =>
				stop <= '1';
				if(send_character = '0') then
					state_next <= idle;
				end if;
			when others => --b0-7
				if(tx_bit = '1') then
					shift <= '1';
					if(state_reg = b7) then
						state_next <= stp;
						shift <= '0';
					elsif(state_reg = b6) then
						state_next <= b7;
					elsif(state_reg = b5) then
						state_next <= b6;
					elsif(state_reg = b4) then
						state_next <= b5;
					elsif(state_reg = b3) then
						state_next <= b4;
					elsif(state_reg = b2) then
						state_next <= b3;
					elsif(state_reg = b1) then
						state_next <= b2;
					else
						state_next <= b1;
					end if;
				end if;
		end case;
	end process;

--BIT TIMER
	process(clk, rst, clrTimer, tx_timer)
	begin
		if(rst = '1') then
			tx_timer <= (others=>'0');
		elsif(clk'event and clk = '1') then
			if(clrTimer = '1') then
				tx_timer <= (others=>'0');
				tx_bit <= '0';
			elsif(tx_timer = BIT_COUNTER_MAX_VAL) then
				tx_timer <= (others=>'0');
				tx_bit <= '1';
			else
				tx_timer <= tx_timer + 1;
				tx_bit <= '0';
			end if;
		end if;
	end process;
	
--SHIFT REGISTER
	process(clk, rst, data_in, shift)
	begin
		if(rst = '1') then
			current_shift <= (others=>'0');
		elsif(clk'event and clk='1') then
			if(load = '1') then
				current_shift <= data_in;
			elsif(shift = '1') then
				shift_out <= current_shift(0);
				current_shift <= '0' & current_shift(7 downto 1);
			end if;
		end if;
	end process;
	
--TRANSMIT OUT
	process(clk, start, stop, shift_out)
	begin
		if(clk'event and clk = '1') then
			tx_out <= '1';
			if(start = '1') then
				tx_out <= '0';
			elsif(stop = '0') then
				tx_out <= shift_out;
			end if;
		end if;
	end process;

end Behavioral;

