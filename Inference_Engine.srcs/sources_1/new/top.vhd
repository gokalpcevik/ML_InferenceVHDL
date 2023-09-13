library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port (
        sysclk: in std_logic;
        BTN:    in std_logic_vector(3 downto 0);
        LED:    out std_logic_vector(3 downto 0)
        );
end top;

architecture RTL of top is
    signal RSTN0: std_logic := '0';
    signal RSTN1: std_logic := '0';
    signal RSTN2: std_logic := '0';

    signal START0: std_logic := '0';
    signal START1: std_logic := '0';
    signal START2: std_logic := '0';

    signal INPUTS:      fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0)  := (others=>to_fixed_t(0.5));
    signal PRED_OUTPUT: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));
    signal FINISHED:    std_logic := '0';
    signal BUSY:        std_logic := '0';

begin

    process(sysclk) 
    begin 
        if rising_edge(sysclk) then
            -- * Synchronize Reset
            RSTN0 <= not BTN(0);
            RSTN1 <= RSTN0;
            RSTN2 <= RSTN1;

            -- * Synchronize Start
            START0 <= BTN(1);
            START1 <= START0;
            START2 <= START1;
        end if;
    end process;

    process(sysclk) 
    begin
        if rising_edge(sysclk) then
            LED(0) <= FINISHED;
            LED(1) <= PRED_OUTPUT(0)(0);
        end if;
    end process;

    cfd_model_inst: entity work.CFD_Model
      generic map (
        L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
        L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
        L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
      )
      port map (
        SysCLK   => sysclk,
        RESETN   => RSTN2,
        START    => START2,
        INPUTS   => INPUTS,
        OUTPUT   => PRED_OUTPUT,
        FINISHED => FINISHED,
        BUSY     => BUSY
      );

end RTL;
