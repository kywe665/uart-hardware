----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:00 10/25/2012 
-- Design Name: 
-- Module Name:    rx - Behavioral 
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

entity rx is
	generic (
		CLK_RATE: natural := 50000000;
		BAUD_RATE: natural := 19200
	);
   Port ( clk : in  STD_LOGIC;
          rst : in  STD_LOGIC;
          rx_in : in  STD_LOGIC;
          data_out : out  STD_LOGIC_VECTOR (7 downto 0);
          data_strobe : out  STD_LOGIC;
          rx_busy : out  STD_LOGIC);
end rx;

architecture Behavioral of rx is
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
	signal tx_timer : unsigned(BIT_COUNTER_BITS-1 downto 0) := (others => '0'); --previously named bit_time
	signal tx_bit, half_bit, clrTimer, load, strobe : std_logic := '0';
	signal current_shift, test_shift : std_logic_vector(7 downto 0) := (others => '0');
	
	type state_type is (power_up, strt, idle, half_way, b0,b1,b2,b3,b4,b5,b6,b7, stp);
	signal state_reg, state_next : state_type := power_up;
	
begin
	data_strobe <= strobe;
	process(clk, half_bit, state_reg, load)
	begin
		if(clk'event and clk = '1') then
			if(state_reg = idle or state_reg = power_up) then
				test_shift <= (others => '0');
			elsif(load = '1' and half_bit = '1') then
				test_shift <= rx_in & test_shift(7 downto 1);
			end if;
		end if;
	end process;

--BIT TIMER
	process(clk, rst, clrTimer, tx_timer)
	begin
		if(rst = '1') then
			tx_timer <= (others=>'0');
			half_bit <= '0';
			tx_bit <= '0';
		elsif(clk'event and clk = '1') then
			if(clrTimer = '1') then
				tx_timer <= (others=>'0');
			elsif(tx_timer = BIT_COUNTER_MAX_VAL/2) then
				half_bit <= '1';
				tx_timer <= tx_timer + 1;
			elsif(tx_timer = BIT_COUNTER_MAX_VAL) then
				tx_timer <= (others=>'0');
				tx_bit <= '1';
			else
				tx_timer <= tx_timer + 1;
				half_bit <= '0';
				tx_bit <= '0';
			end if;
		end if;
	end process;
	
--DATA REGISTER
	process(clk, rst)
	begin
		if(rst = '1') then
			current_shift <= (others=>'0');
		elsif(clk'event and clk='1') then
			if(state_reg = idle) then
				current_shift <= (others=>'0');
			elsif(load = '1' and half_bit = '1') then
				current_shift <= rx_in & current_shift(7 downto 1);
			else
				current_shift <= current_shift;
			end if;
		end if;
	end process;
	
--DATA OUT
--	process(clk, rst, strobe)
--	begin
--		if(clk'event and clk='1') then
--			if(strobe = '1') then
--				data_out <= test_shift;
--			else
--				data_out <= (others => '0');
--			end if;
--		end if;
--	end process;

--STATE MACHINE
	process(clk, rst)
	begin
		if(rst = '1') then
			state_reg <= idle;
		elsif(clk'event and clk = '1') then
			state_reg <= state_next;
		end if;
	end process;
	
	process(state_reg, rx_in, half_bit, tx_bit)
	begin
		--defaults
		rx_busy <= '1';
		state_next <= state_reg;
		clrTimer <= '0';
		strobe <= strobe;
		load <= load;
		case state_reg is
	--powerup
			when power_up =>
				strobe <= '1';
				load <= '0';
				current_shift <= (others=>'0');
				if(rx_in = '1') then
					state_next <= idle;
				end if;
	--idle
			when idle =>
				strobe <= '0';
				clrTimer <= '1';
				rx_busy <= '0';
				if(rx_in = '0') then
					state_next <= strt;
				end if;
	--start (start counter)
			when strt =>
				if(half_bit = '1') then
					state_next <= half_way;
					strobe <= '0';
				end if;
	--halfway (I waited an initial half bit period)
			when half_way =>
				if(half_bit = '1') then
					state_next <= b0;
					load <= '1';
				end if;
			when stp =>
				if(half_bit = '1') then
					state_next <= idle;
					if(rx_in = '1') then
						strobe <= '1';
						data_out <= test_shift;
					end if;
				end if;
	--bits!
			when others => --b0-7
			--(I waited until the next half bit, which was a full bit)
				if(half_bit = '1') then
					load <= '1';
					if(state_reg = b7) then
						state_next <= stp;
						load <= '0';
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
				elsif(tx_bit = '1') then
					load <= '0';
				end if;
		end case;
	end process;
	

end Behavioral;

-----I tried tb and hung