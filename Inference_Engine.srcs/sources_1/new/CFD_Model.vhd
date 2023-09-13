library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

entity CFD_Model is
  Generic (
    L1_WEIGHT_BIAS_MEM_FILE: STRING := "test.mem";
    L2_WEIGHT_BIAS_MEM_FILE: STRING := "test.mem";
    L3_WEIGHT_BIAS_MEM_FILE: STRING := "test.mem"
  );
  Port (
    SysCLK:   in std_logic;                                           -- * system clock
    RESETN:   in std_logic;                                           -- * active-low sync. reset
    START:    in std_logic;                                           -- * start signal (pull high for 1 cycle)
    INPUTS:   in fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0);  -- * prediction input
    OUTPUT:   out fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0);-- * prediction output
    FINISHED: out std_logic;                                          -- * pulled high for 1 cycle when prediction is finished
    BUSY:     out std_logic                                           -- * pulled high until prediction is finished
  );
end CFD_Model;

architecture RTL of CFD_Model is
  signal X: fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0)  := (others=>to_fixed_t(0.0));
  signal L1_Y: fixed_vector_t(CFD_MODEL_L1_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));
  signal L2_Y: fixed_vector_t(CFD_MODEL_L2_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));
  signal L3_Y: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0) := (others=>to_fixed_t(0.0));

  signal START_PREDICTION: std_logic := '0';

  signal L1_FINISHED: std_logic := '0';
  signal L1_BUSY:     std_logic := '0';
  signal L2_FINISHED: std_logic := '0';
  signal L2_BUSY:     std_logic := '0';
  signal L3_FINISHED: std_logic := '0';
  signal L3_BUSY:     std_logic := '0';

begin

  INPUT_exec: process(SysCLK)
  begin
    if rising_edge(SysCLK) then
      if RESETN = '0' then
        START_PREDICTION <= '0';
      else
        START_PREDICTION <= START;
        if START = '1' then
          X <= INPUTS;
        end if;
      end if;
    end if;
  end process;

  OUTPUT_exec: process(SysCLK)
  begin
    if rising_edge(SysCLK) then
      if RESETN = '0' then
      else
        FINISHED <= L3_FINISHED;
        if L3_FINISHED = '1' then
          OUTPUT <= L3_Y;
        end if;
      end if;
    end if;
  end process;

  Layer1: entity work.dense
    generic map (
      WEIGHT_BIAS_MEMORY_FILE => L1_WEIGHT_BIAS_MEM_FILE,
      INPUT_WIDTH             => CFD_MODEL_INPUT_WIDTH,
      NUM_NEURONS             => CFD_MODEL_L1_NUM_NEURONS,
      ACTIVATION_FUNCTION     => ReLU
    )
    port map (
      SysClock    => SysCLK,
      RESETN      => RESETN,
      START       => START_PREDICTION,
      INPUTS      => X,
      ACTIVATIONS => L1_Y,
      BUSY        => L1_BUSY,
      FINISHED    => L1_FINISHED
    );

Layer2: entity work.dense
    generic map (
      WEIGHT_BIAS_MEMORY_FILE => L2_WEIGHT_BIAS_MEM_FILE,
      INPUT_WIDTH             => CFD_MODEL_L1_NUM_NEURONS,
      NUM_NEURONS             => CFD_MODEL_L2_NUM_NEURONS,
      ACTIVATION_FUNCTION     => ReLU
    )
    port map (
      SysClock    => SysCLK,
      RESETN      => RESETN,
      START       => L1_FINISHED,
      INPUTS      => L1_Y,
      ACTIVATIONS => L2_Y,
      BUSY        => L2_BUSY,
      FINISHED    => L2_FINISHED
    );

  Layer3: entity work.dense
    generic map (
      WEIGHT_BIAS_MEMORY_FILE => L3_WEIGHT_BIAS_MEM_FILE,
      INPUT_WIDTH             => CFD_MODEL_L2_NUM_NEURONS,
      NUM_NEURONS             => CFD_MODEL_L3_NUM_NEURONS,
      ACTIVATION_FUNCTION     => Linear
    )
    port map (
      SysClock    => SysCLK,
      RESETN      => RESETN,
      START       => L2_FINISHED,
      INPUTS      => L2_Y,
      ACTIVATIONS => L3_Y,
      BUSY        => L3_BUSY,
      FINISHED    => L3_FINISHED
    );

end RTL;
