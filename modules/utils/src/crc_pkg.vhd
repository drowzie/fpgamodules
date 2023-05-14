library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package crc_pkg is

	--! Polynom constants
	constant C_CRC_ETH_POLY : std_logic_vector(31 downto 0) := x"04C11DB7";

	function calculate_crc (
		data_in : std_logic_vector;
		polynom : std_logic_vector;
		lfsr_reg : std_logic_vector;
		output_xor : std_logic_vector;
		reversed_input : boolean := false;
		reversed_output : boolean := false
	) return std_logic_vector;
	
end crc_pkg;

package body crc_pkg is

	function reverse_slv (
		data_in : std_logic_vector
	) return std_logic_vector
	is
		variable v_temp : std_logic_vector(data_in'range);
		variable v_data_reversed : std_logic_vector(data_in'reverse_range) := data_in;
	begin
		for i in data_in'reverse_range loop
			v_temp(i) := v_data_reversed(i);
		end loop;
		return v_temp;
	end reverse_slv;
	
	--! Calculates CRC with a LFSR design
	--! The caclulation is done through a external lfsr
	--! Meaning each step is dependent on data_in xor register msb.
	function calculate_crc (
		data_in : std_logic_vector;
		polynom : std_logic_vector;
		lfsr_reg : std_logic_vector;
		output_xor : std_logic_vector;
		reversed_input : boolean := false;
		reversed_output : boolean := false
		) return std_logic_vector 
	is
		variable v_lfsr_temp : std_logic_vector(polynom'range);
		variable v_data_temp : std_logic_vector(data_in'range);
	begin

		--! Reverse input if requested
		v_data_temp := reverse_slv(data_in) when reversed_input else
					   data_in;

		v_lfsr_temp := lfsr_reg;

		--! Iterate over each bit and calculate the CRC
		--! The CRC caclulation is done by shifting the register once
		--! XOR each shift reg with the polynom when (data xor MSB) is '1'.
		for d_bit in v_data_temp'range loop
			v_lfsr_temp := (
				(v_lfsr_temp(v_lfsr_temp'left-1 downto 0) & '0') xor
				(polynom and (polynom'range => (v_data_temp(d_bit) xor v_lfsr_temp(v_lfsr_temp'left))))
			);
		end loop;

		--! Reverse output if requested
		v_lfsr_temp := reverse_slv(v_lfsr_temp) when reversed_output else v_lfsr_temp;

		--! XOR the output register. xor with 0 is bypass.
		return v_lfsr_temp xor output_xor;

	end calculate_crc;

end crc_pkg;
