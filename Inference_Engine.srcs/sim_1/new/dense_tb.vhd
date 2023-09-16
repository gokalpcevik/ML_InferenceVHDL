library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.ALL;

entity dense_tb is
end dense_tb;

architecture testbench of dense_tb is
    CONSTANT C_CLOCK_PERIOD: time := 5 ns;
    CONSTANT C_INPUT_WIDTH: INTEGER := 3;
    CONSTANT C_NUM_NEURONS: INTEGER := 3;

    signal SysClk:   std_logic := '0';
    signal RESETN:   std_logic := '0';
    signal START:    std_logic := '0';
    signal FINISHED: std_logic := '0';
    signal BUSY:     std_logic := '0';

    signal inputs: fixed_vector_t(C_INPUT_WIDTH - 1 downto 0) := (0=>to_fixed_t(0.5),1=>to_fixed_t(1.0),2=>to_fixed_t(0.8));
    signal activations: fixed_vector_t(C_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));

begin
    SysClk <= not SysClk after (C_CLOCK_PERIOD / 2);

    process
      begin 
        RESETN <= '1' after 4 ns;
        START <= '1' after 6 ns, '0' after 8.5 ns;
        wait;
    end process;

    dense_inst: entity work.dense
      generic map (
        WEIGHT_BIAS_MEMORY_FILE => "test.mem",
        INPUT_WIDTH             => C_INPUT_WIDTH,
        NUM_NEURONS             => C_NUM_NEURONS,
        ACTIVATION_FUNCTION     => ReLU
      )
      port map (
        SysClock    => SysClk,
        RESETN      => RESETN,
        START       => START,
        INPUTS      => INPUTS,
        ACTIVATIONS => ACTIVATIONS,
        BUSY        => BUSY,
        FINISHED    => FINISHED
      );

end testbench;
