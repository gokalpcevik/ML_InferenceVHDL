library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;
use work.types.all;

entity CFD_Model_MREF_S00 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
		pred_finished: out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end CFD_Model_MREF_S00;

architecture RTL of CFD_Model_MREF_S00 is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 5;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 50
	-- * CONTROL & STATUS
	signal CTRL_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal STATUS_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- * Inference Engine 0
	signal X00_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X01_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X02_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X03_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X04_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X05_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X06_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X07_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y00_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y01_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y02_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y03_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- * Inference Engine 1
	signal X10_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X11_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X12_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X13_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X14_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X15_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X16_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X17_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y10_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y11_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y12_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y13_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- * Inference Engine 2
	signal X20_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X21_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X22_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X23_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X24_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X25_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X26_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X27_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y20_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y21_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y22_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y23_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- * Inference Engine 3
	signal X30_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X31_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X32_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X33_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X34_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X35_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X36_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal X37_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y30_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y31_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y32_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal Y33_REG	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;

	signal X0: fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0);
	signal X1: fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0);
	signal X2: fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0);
	signal X3: fixed_vector_t(CFD_MODEL_INPUT_WIDTH - 1 downto 0);

	signal YHAT0: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0);
	signal YHAT1: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0);
	signal YHAT2: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0);
	signal YHAT3: fixed_vector_t(CFD_MODEL_L3_NUM_NEURONS - 1 downto 0);
	
	signal pred_finished0: std_logic;
	signal pred_finished1: std_logic;
	signal pred_finished2: std_logic;
	signal pred_finished3: std_logic;
	
	signal busy0: std_logic;
	signal busy1: std_logic;
	signal busy2: std_logic;
	signal busy3: std_logic;
	
	signal start0: std_logic;
	signal start1: std_logic;
	signal start2: std_logic;
	signal start3: std_logic;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      CTRL_REG <= (others => '0');
	      -- STATUS_REG <= (others => '0');
	      X00_REG <= (others => '0');
	      X01_REG <= (others => '0');
	      X02_REG <= (others => '0');
	      X03_REG <= (others => '0');
	      X04_REG <= (others => '0');
	      X05_REG <= (others => '0');
	      X06_REG <= (others => '0');
	      X07_REG <= (others => '0');
	      -- Y00_REG <= (others => '0');
	      -- Y01_REG <= (others => '0');
	      -- Y02_REG <= (others => '0');
	      -- Y03_REG <= (others => '0');
	      X10_REG <= (others => '0');
	      X11_REG <= (others => '0');
	      X12_REG <= (others => '0');
	      X13_REG <= (others => '0');
	      X14_REG <= (others => '0');
	      X15_REG <= (others => '0');
	      X16_REG <= (others => '0');
	      X17_REG <= (others => '0');
	      -- Y10_REG <= (others => '0');
	      -- Y11_REG <= (others => '0');
	      -- Y12_REG <= (others => '0');
	      -- Y13_REG <= (others => '0');
	      X20_REG <= (others => '0');
	      X21_REG <= (others => '0');
	      X22_REG <= (others => '0');
	      X23_REG <= (others => '0');
	      X24_REG <= (others => '0');
	      X25_REG <= (others => '0');
	      X26_REG <= (others => '0');
	      X27_REG <= (others => '0');
	      -- Y20_REG <= (others => '0');
	      -- Y21_REG <= (others => '0');
	      -- Y22_REG <= (others => '0');
	      -- Y23_REG <= (others => '0');
	      X30_REG <= (others => '0');
	      X31_REG <= (others => '0');
	      X32_REG <= (others => '0');
	      X33_REG <= (others => '0');
	      X34_REG <= (others => '0');
	      X35_REG <= (others => '0');
	      X36_REG <= (others => '0');
	      X37_REG <= (others => '0');
	      -- Y30_REG <= (others => '0');
	      -- Y31_REG <= (others => '0');
	      -- Y32_REG <= (others => '0');
	      -- Y33_REG <= (others => '0');
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"000000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                CTRL_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                -- STATUS_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                X00_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                X01_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 4
	                X02_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 5
	                X03_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 6
	                X04_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"000111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 7
	                X05_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 8
	                X06_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 9
	                X07_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 10
	                -- Y00_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 11
	                -- Y01_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 12
	                -- Y02_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 13
	                -- Y03_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 14
	                X10_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 15
	                X11_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 16
	                X12_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 17
	                X13_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 18
	                X14_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 19
	                X15_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 20
	                X16_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 21
	                X17_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 22
	                -- Y10_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"010111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 23
	                -- Y11_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 24
	                -- Y12_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 25
	                -- Y13_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 26
	                X20_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 27
	                X21_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 28
	                X22_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 29
	                X23_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 30
	                X24_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"011111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 31
	                X25_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 32
	                X26_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 33
	                X27_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 34
	                -- Y20_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 35
	                -- Y21_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 36
	                -- Y22_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 37
	                -- Y23_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 38
	                X30_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"100111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 39
	                X31_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 40
	                X32_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 41
	                X33_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 42
	                X34_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 43
	                X35_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 44
	                X36_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 45
	                X37_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 46
	                -- Y30_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"101111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 47
	                -- Y31_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"110000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 48
	                -- Y32_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"110001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 49
	                -- Y33_REG(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when others =>
	            CTRL_REG <= CTRL_REG;
	            -- STATUS_REG <= STATUS_REG;
	            X00_REG <= X00_REG;
	            X01_REG <= X01_REG;
	            X02_REG <= X02_REG;
	            X03_REG <= X03_REG;
	            X04_REG <= X04_REG;
	            X05_REG <= X05_REG;
	            X06_REG <= X06_REG;
	            X07_REG <= X07_REG;
	            -- Y00_REG <= Y00_REG;
	            -- Y01_REG <= Y01_REG;
	            -- Y02_REG <= Y02_REG;
	            -- Y03_REG <= Y03_REG;
	            X10_REG <= X10_REG;
	            X11_REG <= X11_REG;
	            X12_REG <= X12_REG;
	            X13_REG <= X13_REG;
	            X14_REG <= X14_REG;
	            X15_REG <= X15_REG;
	            X16_REG <= X16_REG;
	            X17_REG <= X17_REG;
	            -- Y10_REG <= Y10_REG;
	            -- Y11_REG <= Y11_REG;
	            -- Y12_REG <= Y12_REG;
	            -- Y13_REG <= Y13_REG;
	            X20_REG <= X20_REG;
	            X21_REG <= X21_REG;
	            X22_REG <= X22_REG;
	            X23_REG <= X23_REG;
	            X24_REG <= X24_REG;
	            X25_REG <= X25_REG;
	            X26_REG <= X26_REG;
	            X27_REG <= X27_REG;
	            -- Y20_REG <= Y20_REG;
	            -- Y21_REG <= Y21_REG;
	            -- Y22_REG <= Y22_REG;
	            -- Y23_REG <= Y23_REG;
	            X30_REG <= X30_REG;
	            X31_REG <= X31_REG;
	            X32_REG <= X32_REG;
	            X33_REG <= X33_REG;
	            X34_REG <= X34_REG;
	            X35_REG <= X35_REG;
	            X36_REG <= X36_REG;
	            X37_REG <= X37_REG;
	            -- Y30_REG <= Y30_REG;
	            -- Y31_REG <= Y31_REG;
	            -- Y32_REG <= Y32_REG;
	            -- Y33_REG <= Y33_REG;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (CTRL_REG, STATUS_REG, X00_REG, X01_REG, X02_REG, X03_REG, X04_REG, X05_REG, X06_REG, X07_REG, Y00_REG, Y01_REG, Y02_REG, Y03_REG, X10_REG, X11_REG, X12_REG, X13_REG, X14_REG, X15_REG, X16_REG, X17_REG, Y10_REG, Y11_REG, Y12_REG, Y13_REG, X20_REG, X21_REG, X22_REG, X23_REG, X24_REG, X25_REG, X26_REG, X27_REG, Y20_REG, Y21_REG, Y22_REG, Y23_REG, X30_REG, X31_REG, X32_REG, X33_REG, X34_REG, X35_REG, X36_REG, X37_REG, Y30_REG, Y31_REG, Y32_REG, Y33_REG, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"000000" =>
	        reg_data_out <= CTRL_REG;
	      when b"000001" =>
	        reg_data_out <= STATUS_REG;
	      when b"000010" =>
	        reg_data_out <= X00_REG;
	      when b"000011" =>
	        reg_data_out <= X01_REG;
	      when b"000100" =>
	        reg_data_out <= X02_REG;
	      when b"000101" =>
	        reg_data_out <= X03_REG;
	      when b"000110" =>
	        reg_data_out <= X04_REG;
	      when b"000111" =>
	        reg_data_out <= X05_REG;
	      when b"001000" =>
	        reg_data_out <= X06_REG;
	      when b"001001" =>
	        reg_data_out <= X07_REG;
	      when b"001010" =>
	        reg_data_out <= Y00_REG;
	      when b"001011" =>
	        reg_data_out <= Y01_REG;
	      when b"001100" =>
	        reg_data_out <= Y02_REG;
	      when b"001101" =>
	        reg_data_out <= Y03_REG;
	      when b"001110" =>
	        reg_data_out <= X10_REG;
	      when b"001111" =>
	        reg_data_out <= X11_REG;
	      when b"010000" =>
	        reg_data_out <= X12_REG;
	      when b"010001" =>
	        reg_data_out <= X13_REG;
	      when b"010010" =>
	        reg_data_out <= X14_REG;
	      when b"010011" =>
	        reg_data_out <= X15_REG;
	      when b"010100" =>
	        reg_data_out <= X16_REG;
	      when b"010101" =>
	        reg_data_out <= X17_REG;
	      when b"010110" =>
	        reg_data_out <= Y10_REG;
	      when b"010111" =>
	        reg_data_out <= Y11_REG;
	      when b"011000" =>
	        reg_data_out <= Y12_REG;
	      when b"011001" =>
	        reg_data_out <= Y13_REG;
	      when b"011010" =>
	        reg_data_out <= X20_REG;
	      when b"011011" =>
	        reg_data_out <= X21_REG;
	      when b"011100" =>
	        reg_data_out <= X22_REG;
	      when b"011101" =>
	        reg_data_out <= X23_REG;
	      when b"011110" =>
	        reg_data_out <= X24_REG;
	      when b"011111" =>
	        reg_data_out <= X25_REG;
	      when b"100000" =>
	        reg_data_out <= X26_REG;
	      when b"100001" =>
	        reg_data_out <= X27_REG;
	      when b"100010" =>
	        reg_data_out <= Y20_REG;
	      when b"100011" =>
	        reg_data_out <= Y21_REG;
	      when b"100100" =>
	        reg_data_out <= Y22_REG;
	      when b"100101" =>
	        reg_data_out <= Y23_REG;
	      when b"100110" =>
	        reg_data_out <= X30_REG;
	      when b"100111" =>
	        reg_data_out <= X31_REG;
	      when b"101000" =>
	        reg_data_out <= X32_REG;
	      when b"101001" =>
	        reg_data_out <= X33_REG;
	      when b"101010" =>
	        reg_data_out <= X34_REG;
	      when b"101011" =>
	        reg_data_out <= X35_REG;
	      when b"101100" =>
	        reg_data_out <= X36_REG;
	      when b"101101" =>
	        reg_data_out <= X37_REG;
	      when b"101110" =>
	        reg_data_out <= Y30_REG;
	      when b"101111" =>
	        reg_data_out <= Y31_REG;
	      when b"110000" =>
	        reg_data_out <= Y32_REG;
	      when b"110001" =>
	        reg_data_out <= Y33_REG;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	process(pred_finished0,pred_finished1,pred_finished2,pred_finished3) 
	begin
		pred_finished <= pred_finished0 or pred_finished1 or pred_finished2 or pred_finished3;
	end process;

	-- Add user logic here
		process (S_AXI_ACLK) 
		begin
			if rising_edge(S_AXI_ACLK) then
				if S_AXI_ARESETN = '0' then
					START0 <= '0';
					START1 <= '0';
					START2 <= '0';
					START3 <= '0';
				else
					START0 <= CTRL_REG(0);
					START1 <= CTRL_REG(1);
					START2 <= CTRL_REG(2);
					START3 <= CTRL_REG(3);
					
					STATUS_REG(0) <= pred_finished0;
					STATUS_REG(1) <= busy0;

					STATUS_REG(2) <= pred_finished1;
					STATUS_REG(3) <= busy1;

					STATUS_REG(4) <= pred_finished2;
					STATUS_REG(5) <= busy2;

					STATUS_REG(6) <= pred_finished3;
					STATUS_REG(7) <= busy3;

					if CTRL_REG(0) = '1' then
						 X0 <= (
						 		resize(to_sfixed(X00_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X01_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X02_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X03_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X04_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X05_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X06_REG,16,-15), fixed_t'high, fixed_t'low),
						 		resize(to_sfixed(X07_REG,16,-15), fixed_t'high, fixed_t'low)
						 	);
					end if;

					if CTRL_REG(1) = '1' then
						X1 <= (
								resize(to_sfixed(X10_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X11_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X12_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X13_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X14_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X15_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X16_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X17_REG,16,-15), fixed_t'high, fixed_t'low)
							);
				   	end if;

					if CTRL_REG(2) = '1' then
						X2 <= (
								resize(to_sfixed(X20_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X21_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X22_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X23_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X24_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X25_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X26_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X27_REG,16,-15), fixed_t'high, fixed_t'low)
							);
				   	end if;

					if CTRL_REG(3) = '1' then
						X3 <= (
								resize(to_sfixed(X30_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X31_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X32_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X33_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X34_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X35_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X36_REG,16,-15), fixed_t'high, fixed_t'low),
								resize(to_sfixed(X37_REG,16,-15), fixed_t'high, fixed_t'low)
							);
				   	end if;

					if pred_finished0 = '1' then
						Y00_REG <= to_slv(resize(YHAT0(0), 16, -15));
						Y01_REG <= to_slv(resize(YHAT0(1), 16, -15));
						Y02_REG <= to_slv(resize(YHAT0(2), 16, -15));
						Y03_REG <= to_slv(resize(YHAT0(3), 16, -15));
					end if;

					if pred_finished1 = '1' then
						Y10_REG <= to_slv(resize(YHAT1(0), 16, -15));
						Y11_REG <= to_slv(resize(YHAT1(1), 16, -15));
						Y12_REG <= to_slv(resize(YHAT1(2), 16, -15));
						Y13_REG <= to_slv(resize(YHAT1(3), 16, -15));
					end if;

					if pred_finished2 = '1' then
						Y20_REG <= to_slv(resize(YHAT2(0), 16, -15));
						Y21_REG <= to_slv(resize(YHAT2(1), 16, -15));
						Y22_REG <= to_slv(resize(YHAT2(2), 16, -15));
						Y23_REG <= to_slv(resize(YHAT2(3), 16, -15));
					end if;

					if pred_finished3 = '1' then
						Y30_REG <= to_slv(resize(YHAT3(0), 16, -15));
						Y31_REG <= to_slv(resize(YHAT3(1), 16, -15));
						Y32_REG <= to_slv(resize(YHAT3(2), 16, -15));
						Y33_REG <= to_slv(resize(YHAT3(3), 16, -15));
					end if;
	
				end if;
			end if;
		end process;

		cfd_model_inst0: entity work.CFD_Model
		  generic map (
			L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
			L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
			L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
		  )
		  port map (
			SysCLK   => S_AXI_ACLK,
			RESETN   => S_AXI_ARESETN,
			START    => START0,
			INPUTS   => X0,
			OUTPUT   => YHAT0,
			FINISHED => pred_finished0,
			BUSY     => busy0
		  );

		cfd_model_inst1: entity work.CFD_Model
		  generic map (
			L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
			L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
			L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
		  )
		  port map (
			SysCLK   => S_AXI_ACLK,
			RESETN   => S_AXI_ARESETN,
			START    => START1,
			INPUTS   => X1,
			OUTPUT   => YHAT1,
			FINISHED => pred_finished1,
			BUSY     => busy1
		  );

		cfd_model_inst2: entity work.CFD_Model
		  generic map (
			L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
			L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
			L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
		  )
		  port map (
			SysCLK   => S_AXI_ACLK,
			RESETN   => S_AXI_ARESETN,
			START    => START2,
			INPUTS   => X2,
			OUTPUT   => YHAT2,
			FINISHED => pred_finished2,
			BUSY     => busy2
		  );

		cfd_model_inst3: entity work.CFD_Model
		  generic map (
			L1_WEIGHT_BIAS_MEM_FILE => "dense_WB_Q2_15.mem",
			L2_WEIGHT_BIAS_MEM_FILE => "dense_1_WB_Q2_15.mem",
			L3_WEIGHT_BIAS_MEM_FILE => "dense_2_WB_Q2_15.mem"
		  )
		  port map (
			SysCLK   => S_AXI_ACLK,
			RESETN   => S_AXI_ARESETN,
			START    => START3,
			INPUTS   => X3,
			OUTPUT   => YHAT3,
			FINISHED => pred_finished3,
			BUSY     => busy3
		  );
	-- User logic ends

end RTL;
