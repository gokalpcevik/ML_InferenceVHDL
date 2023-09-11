library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.ALL;

entity dense_tb is
end dense_tb;

architecture testbench of dense_tb is
    CONSTANT C_CLOCK_PERIOD: time := 5 ns;
    CONSTANT C_INPUT_WIDTH: INTEGER := 2;
    CONSTANT C_NUM_NEURONS: INTEGER := 3;

    signal SysClk:   std_logic := '0';
    signal resetn:   std_logic := '0';
    signal start:    std_logic := '0';
    signal finished: std_logic := '0';
    signal busy:     std_logic := '0';

    signal inputs: fixed_vector_t(C_INPUT_WIDTH - 1 downto 0) := (0=>to_fixed_t(1.0),1=>to_fixed_t(-0.5));
    signal activations: fixed_vector_t(C_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));

begin
    SysClk <= not SysClk after (C_CLOCK_PERIOD / 2);

    process
      begin 
        resetn <= '1' after 4 ns;
        start <= '1' after 6 ns, '0' after 8.5 ns;
        wait;
    end process;

    dense_inst: entity work.dense
      generic map (
        MEM_FILE_NAME       => "test.mem",
        INPUT_WIDTH         => C_INPUT_WIDTH,
        NUM_NEURONS         => C_NUM_NEURONS,
        ACTIVATION_FUNCTION => ReLU
      )
      port map (
        SysClock    => SysClk,
        RESETN      => resetn,
        START       => START,
        INPUTS      => INPUTS,
        ACTIVATIONS => ACTIVATIONS,
        BUSY        => BUSY,
        FINISHED    => FINISHED
      );

end testbench;
