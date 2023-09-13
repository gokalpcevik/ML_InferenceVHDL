library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
-- Local fixed package(vectors, matrices, etc.)
use WORK.TYPES.ALL;
use IEEE.fixed_pkg.ALL;
-- For BRAM
Library xpm;
use xpm.vcomponents.all;

entity dense is
    Generic(
        -- BRAM init file
        WEIGHT_BIAS_MEMORY_FILE : STRING := "DENSE_0.mem";
        -- Layer properties
        INPUT_WIDTH : INTEGER := 8;
        NUM_NEURONS: INTEGER := 4;
        ACTIVATION_FUNCTION: activation_t := ReLU    
        );
    Port (
        -- Inputs
        SysClock:      in std_logic;
        RESETN:   in std_logic;
        START:    in std_logic;
        INPUTS:   in fixed_vector_t(INPUT_WIDTH - 1 downto 0);
        -- Outputs
        ACTIVATIONS: out fixed_vector_t(NUM_NEURONS - 1 downto 0);
        BUSY:        out std_logic;
        FINISHED:    out std_logic
    );
end dense;

architecture RTL of dense is

    -- Memory size in bits (for BRAM)
    CONSTANT C_MEMORY_SIZE:     INTEGER := NUM_NEURONS * INPUT_WIDTH * FP_TOTAL_WIDTH + NUM_NEURONS * FP_TOTAL_WIDTH;
    CONSTANT C_READ_DATA_WIDTH: INTEGER := FP_TOTAL_WIDTH;
    CONSTANT C_READ_ADDR_WIDTH: INTEGER := clog2(C_MEMORY_SIZE/C_READ_DATA_WIDTH);
    -- ! Do not change this
    CONSTANT C_READ_LATENCY: INTEGER := 2;

    type layer_state_t is (LAYER_IDLE, LAYER_MUL, LAYER_MUL_BUF, LAYER_BIAS, LAYER_ACTIVATION, LAYER_OUTPUT);
    signal layer_state: layer_state_t := LAYER_IDLE;    

    -- * Input and Output for this layer(buffered)
    signal X: fixed_vector_t(INPUT_WIDTH - 1 downto 0);
    signal Y: fixed_vector_t(NUM_NEURONS - 1 downto 0);

    signal Y_YPXDATA: fixed_mul_vector_t(NUM_NEURONS - 1 downto 0);

    -- * Read Enable | Port A
    signal en_rea: std_logic := '0';
    signal addr_rea: std_logic_vector(C_READ_ADDR_WIDTH - 1 downto 0) := (others=>'0');
    signal data_rea0: std_logic_vector(C_READ_DATA_WIDTH - 1 downto 0) := (others=>'0');
    signal data_rea1: std_logic_vector(C_READ_DATA_WIDTH - 1 downto 0) := (others=>'0');
    signal data_rea2: std_logic_vector(C_READ_DATA_WIDTH - 1 downto 0) := (others=>'0');
    signal incr_addr: std_logic := '0';

    -- * Start SR signals
    signal start1: std_logic := '0';
    signal start2: std_logic := '0';

    -- * Signals to select elements from the weight matrix(or bias vector) and inputs
    signal NEURON_SELECT: unsigned(5 downto 0) := to_unsigned(0,6);
    signal WEIGHT_SELECT: unsigned(5 downto 0) := to_unsigned(0,6);

    -- * Asserted when XXXX_SELECT has reached the maximum index in bounds
    signal WEIGHTS_EXH: std_logic := '0'; 
    signal NEURONS_EXH: std_logic := '0';

    signal S_BUSY: std_logic := '0';
begin

    -- * Xilinx XPM macro(Single port block ROM)
    xpm_memory_sprom_inst : xpm_memory_sprom
   generic map (
      ADDR_WIDTH_A => C_READ_ADDR_WIDTH, -- DECIMAL
      AUTO_SLEEP_TIME => 0,           -- Disable auto-sleep
      CASCADE_HEIGHT => 0,            -- Allow Vivado to choose
      ECC_BIT_RANGE => "7:0",         -- No ECC for now
      ECC_MODE => "no_ecc",           -- No ECC for now
      ECC_TYPE => "none",             -- No ECC for now
      --IGNORE_INIT_SYNTH => 0,         -- Use both for sim. and synth.
      MEMORY_INIT_FILE => WEIGHT_BIAS_MEMORY_FILE,  -- Init from generic param.
      MEMORY_INIT_PARAM => "0",       -- String (no initialization through parameter, only from file)
      MEMORY_OPTIMIZATION => "true",  -- String
      MEMORY_PRIMITIVE => "block",    -- String(Weights and biases are generally large so block is more appropriate)
      MEMORY_SIZE => C_MEMORY_SIZE,   -- DECIMAL(in bits)
      MESSAGE_CONTROL => 0,           -- DECIMAL
      RAM_DECOMP => "auto",           -- String(let Vivado choose)
      READ_DATA_WIDTH_A => C_READ_DATA_WIDTH,        -- DECIMAL
      READ_LATENCY_A => C_READ_LATENCY,            -- DECIMAL
      READ_RESET_VALUE_A => "0",      -- String
      RST_MODE_A => "SYNC",           -- String
      SIM_ASSERT_CHK => 1,            -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_MEM_INIT => 1,              -- DECIMAL
      USE_MEM_INIT_MMI => 0,          -- DECIMAL
      WAKEUP_TIME => "disable_sleep"  -- String
   )
   port map (
      douta => data_rea0,     -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      addra => addr_rea,     -- ADDR_WIDTH_A-bit input: Address for port A read operations.
      clka => SysClock,            -- 1-bit input: Clock signal for port A.
      ena => en_rea,        /* 1-bit input: Memory enable signal for port A. Must be high on clock
                                cycles when read operations are initiated. Pipelined internally. */
      injectdbiterra => '1',  -- 1-bit input: Do not change from the provided value.(unused='1')
      injectsbiterra => '1',  -- 1-bit input: Do not change from the provided value.(unused='1')
      regcea => '1',          -- 1-bit input: Do not change from the provided value.
      rsta => '0',            -- 1-bit input: Reset signal for the final port A output register
                              -- stage. Synchronously resets output port douta to the value specified
                              -- by parameter READ_RESET_VALUE_A.
      sleep => '1'            -- 1-bit input: sleep signal to enable the dynamic power saving feature.(tie to '1' if unused)
   );

    -- * I/O
    BUSY <= S_BUSY;

    -- * Index exhaustion logic
    process(WEIGHT_SELECT, NEURON_SELECT)
    begin 
        WEIGHTS_EXH <= '1' when (WEIGHT_SELECT) = (INPUT_WIDTH - 1) else '0';
        NEURONS_EXH <= '1' when (NEURON_SELECT) = (NUM_NEURONS - 1) else '0';
    end process;

    -- * Start SR
    START_SR: process(SysClock)
    begin
        if rising_edge(SysClock) then
            if RESETN = '1' then
                start1 <= start;
                start2 <= start1;    
            end if;
        end if;
    end process;

    -- * Generate master execution logic according to the activation function
    -- TODO: This code needs to be (almost)halved but I don't know how without case generation
    MASTER_EXEC_gen_act: case (ACTIVATION_FUNCTION) generate

    /*******************************************************************
     ** MASTER EXECUTION PROCESS FOR 'RECTIFIED LINEAR UNIT' ACTIVATION *
     *******************************************************************/
    when ReLU =>
    
    MASTER_EXEC_proc: process(SysClock)
    begin
        if rising_edge(SysClock) then
            if RESETN = '0' then
                layer_state <= LAYER_IDLE;
                S_BUSY <= '0';
            else
                -- * Increment address to get the next weight/bias
                if incr_addr = '1' then
                    addr_rea <= std_logic_vector(unsigned(addr_rea) + 1);
                end if;

                data_rea1 <= data_rea0;
                data_rea2 <= data_rea1;

                case layer_state is
                when LAYER_IDLE =>
                    FINISHED <= '0';
                    if (start = '1') and (S_BUSY = '0') then
                        S_BUSY <= '1';
                        -- * Reset the address to 0
                        addr_rea <= (others=>'0');
                        -- * Input buffer
                        X <= INPUTS;
                        -- * Enable read ROM for port A
                        en_rea <= '1';
                        -- * Start incrementing the address
                        incr_addr <= '1';
                    end if;
                    -- * 2 cycles after en_rea is asserted, switch to mult. state.(BROM latency is 2, fixed for now)
                    if start2 = '1' then
                        -- * Reset the neuron and weight sel. index. It'll start from 0,0
                        NEURON_SELECT <= to_unsigned(0,NEURON_SELECT'length);
                        WEIGHT_SELECT <= to_unsigned(0,WEIGHT_SELECT'length);
                        Y_YPXDATA <= (others=>to_fixed_mul_t(0.0));
                        layer_state <= LAYER_MUL;
                    end if;
                when LAYER_MUL =>
                    -- * Accumulate(dot prod.) in the Y vector
                    -- * Y(i) = Y(i) + X(i) * W_i (i = 0 ... INPUT_WIDTH - 1)
                    -- MUL_BUFFER(to_integer(NEURON_SELECT)) <= resize(MUL_BUFFER(to_integer(NEURON_SELECT)) + resize(X(to_integer(WEIGHT_SELECT)) * to_sfixed(data_rea0,-- fixed_t'high,fixed_t'low),fixed_t'high,fixed_t'low),fixed_t'high,fixed_t'low);
                    Y_YPXDATA(to_integer(NEURON_SELECT)) <= 
                        resize(
                            Y_YPXDATA(to_integer(NEURON_SELECT)) 
                            +
                            -- X * data 
                            X(to_integer(WEIGHT_SELECT)) * to_sfixed(data_rea0, fixed_t'high, fixed_t'low),
                            FP_MUL_LEFT_INDEX, FP_MUL_RIGHT_INDEX);

                    if WEIGHTS_EXH = '1' then
                        WEIGHT_SELECT <= to_unsigned(0, WEIGHT_SELECT'length);
                        NEURON_SELECT <= NEURON_SELECT + 1;
                    else
                        WEIGHT_SELECT <= WEIGHT_SELECT + 1;
                    end if;

                    if NEURONS_EXH = '1' AND WEIGHTS_EXH = '1' then
                        layer_state <= LAYER_MUL_BUF;
                    end if;
                when LAYER_MUL_BUF =>

                    for i in 0 to NUM_NEURONS - 1 loop
                        Y(i) <= resize(Y_YPXDATA(i), fixed_t'high, fixed_t'low);
                    end loop;
                    
                    layer_state <= LAYER_BIAS;
                    NEURON_SELECT <= to_unsigned(0,NEURON_SELECT'length);

                when LAYER_BIAS =>
                    -- * Add the bias to the mul. output
                    Y(to_integer(NEURON_SELECT)) <= resize(Y(to_integer(NEURON_SELECT)) + to_sfixed(data_rea1,fixed_t'high,fixed_t'low),fixed_t'high, fixed_t'low);

                    -- * If input sel. is exhausted(reached max index) switch to next layer
                    if NEURONS_EXH = '1' then
                        -- * Reset the neuron selection index for activation
                        NEURON_SELECT <= to_unsigned(0, NEURON_SELECT'length);
                        -- * Disable increment addr.
                        incr_addr <= '0';
                        -- * Disable read ROM
                        en_rea <= '0';
                        -- * Switch to activation state
                        layer_state <= LAYER_ACTIVATION;
                    else
                        NEURON_SELECT <= NEURON_SELECT + 1;
                    end if;

                when LAYER_ACTIVATION =>
                     -- * ReLU: Y(i) <- max(Y(i), 0.0);
                     if Y(to_integer(NEURON_SELECT)) < to_fixed_t(0.0) then
                        Y(to_integer(NEURON_SELECT)) <= to_fixed_t(0.0);
                    end if;

                    if NEURONS_EXH = '1' then
                        layer_state <= LAYER_OUTPUT;
                    else
                        NEURON_SELECT <= NEURON_SELECT + 1;
                    end if;
                when LAYER_OUTPUT =>
                    -- * Output buffer
                    ACTIVATIONS <= Y;
                    -- * Assert finish for one cycle(reset on IDLE)
                    FINISHED <= '1';
                    -- * Not busy anymore
                    S_BUSY <= '0';
                    -- * Switch to idle
                    layer_state <= LAYER_IDLE;
                end case;
            end if;
        end if;
    end process;
    /**************************************************************************
     * ! END OF MASTER EXECUTION PROCESS FOR 'RECTIFIED LINEAR UNIT' ACTIVATION
     **************************************************************************/

    /*******************************************************************
    ** MASTER EXECUTION PROCESS FOR 'LINEAR' ACTIVATION *
    *******************************************************************/
    when Linear =>
    
    MASTER_EXEC_proc: process(SysClock)
    begin
        if rising_edge(SysClock) then
            if RESETN = '0' then
                layer_state <= LAYER_IDLE;
                S_BUSY <= '0';
            else
                -- * Increment address to get the next weight/bias
                if incr_addr = '1' then
                    addr_rea <= std_logic_vector(unsigned(addr_rea) + 1);
                end if;

                data_rea1 <= data_rea0;
                data_rea2 <= data_rea1;

                case layer_state is
                when LAYER_IDLE =>
                    FINISHED <= '0';
                    if (start = '1') and (S_BUSY = '0') then
                        S_BUSY <= '1';
                        -- * Reset the address to 0
                        addr_rea <= (others=>'0');
                        -- * Input buffer
                        X <= INPUTS;
                        -- * Enable read ROM for port A
                        en_rea <= '1';
                        -- * Start incrementing the address
                        incr_addr <= '1';
                    end if;
                    -- * 2 cycles after en_rea is asserted, switch to mult. state.(BROM latency is 2, fixed for now)
                    if start2 = '1' then
                        -- * Reset the neuron and weight sel. index. It'll start from 0,0
                        NEURON_SELECT <= to_unsigned(0,NEURON_SELECT'length);
                        WEIGHT_SELECT <= to_unsigned(0,WEIGHT_SELECT'length);
                        Y_YPXDATA <= (others=>to_fixed_mul_t(0.0));
                        layer_state <= LAYER_MUL;
                    end if;
                when LAYER_MUL =>
                     -- * Accumulate(dot prod.) in the Y vector
                    -- * Y(i) = Y(i) + X(i) * W_i (i = 0 ... INPUT_WIDTH - 1)
                    -- MUL_BUFFER(to_integer(NEURON_SELECT)) <= resize(MUL_BUFFER(to_integer(NEURON_SELECT)) + resize(X(to_integer(WEIGHT_SELECT)) * to_sfixed(data_rea0,-- fixed_t'high,fixed_t'low),fixed_t'high,fixed_t'low),fixed_t'high,fixed_t'low);
                    Y_YPXDATA(to_integer(NEURON_SELECT)) <= 
                        resize(
                            Y_YPXDATA(to_integer(NEURON_SELECT)) 
                            +
                            -- X * data 
                            X(to_integer(WEIGHT_SELECT)) * to_sfixed(data_rea0, fixed_t'high, fixed_t'low),
                            FP_MUL_LEFT_INDEX, FP_MUL_RIGHT_INDEX);

                    if WEIGHTS_EXH = '1' then
                        WEIGHT_SELECT <= to_unsigned(0, WEIGHT_SELECT'length);
                        NEURON_SELECT <= NEURON_SELECT + 1;
                    else
                        WEIGHT_SELECT <= WEIGHT_SELECT + 1;
                    end if;

                    if NEURONS_EXH = '1' AND WEIGHTS_EXH = '1' then
                        layer_state <= LAYER_MUL_BUF;
                    end if;
                when LAYER_MUL_BUF =>
                    
                    for i in 0 to NUM_NEURONS - 1 loop
                        Y(i) <= resize(Y_YPXDATA(i), fixed_t'high, fixed_t'low);
                    end loop;
                    layer_state <= LAYER_BIAS;
                    NEURON_SELECT <= to_unsigned(0,NEURON_SELECT'length);

                when LAYER_BIAS =>
                    -- * Add the bias to the mul. output
                    Y(to_integer(NEURON_SELECT)) <= resize(Y(to_integer(NEURON_SELECT)) + to_sfixed(data_rea1,fixed_t'high,fixed_t'low),fixed_t'high, fixed_t'low);

                    -- * If input sel. is exhausted(reached max index) switch to next layer
                    if NEURONS_EXH = '1' then
                        -- * Disable increment addr.
                        incr_addr <= '0';
                        -- * Disable read ROM
                        en_rea <= '0';
                        -- * Switch to output state(we don't have any activation logic for 'linear')
                        layer_state <= LAYER_OUTPUT;
                    else
                        NEURON_SELECT <= NEURON_SELECT + 1;
                    end if;

                when LAYER_ACTIVATION =>
                     
                when LAYER_OUTPUT =>
                    -- * Output buffer
                    ACTIVATIONS <= Y;
                    -- * Assert finish for one cycle(reset on IDLE)
                    FINISHED <= '1';
                    -- * Not busy anymore
                    S_BUSY <= '0';
                    -- * Switch to idle
                    layer_state <= LAYER_IDLE;
                end case;
            end if;
        end if;
    end process;
    /**************************************************************************
     * ! END OF MASTER EXECUTION PROCESS FOR 'LINEAR' ACTIVATION
     **************************************************************************/
end generate;

end RTL;
