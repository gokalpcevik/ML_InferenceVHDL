library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

entity CFD_Model_tb is
end CFD_Model_tb;

architecture testbench of CFD_Model_tb is
    CONSTANT C_CLOCK_PERIOD: time := 5 ns;

    signal SysCLK:   std_logic := '0';
    signal RESETN:   std_logic := '0';
    signal START:    std_logic := '0';
    signal FINISHED: std_logic := '0';
    signal BUSY:     std_logic := '0';

    signal INPUTS:      fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0)  := (others=>to_fixed_t(0.5));
    signal PRED_OUTPUT: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));

begin
    SysClk <= not SysClk after (C_CLOCK_PERIOD / 2);

    process
      begin 
        RESETN <= '1' after 4 ns;
        START <= '1' after 6 ns, '0' after 8.5 ns;
        wait;
    end process;

    cfd_model_inst: entity work.CFD_Model
      generic map (
        L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
        L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
        L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
      )
      port map (
        SysCLK   => SysCLK,
        RESETN   => RESETN,
        START    => START,
        INPUTS   => INPUTS,
        OUTPUT   => PRED_OUTPUT,
        FINISHED => FINISHED,
        BUSY     => BUSY
      );


end testbench;
