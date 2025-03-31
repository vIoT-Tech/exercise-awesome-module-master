library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library olo;
    use olo.olo_base_pkg_math.all;
    use olo.olo_base_pkg_array.all;

entity AwesomeModule is
port (
    clk                     : in  std_logic;
    rst                     : in  std_logic;
    
    irq                     : out std_logic;

    s_axi_ctrl_arvalid      : in  std_logic;
    s_axi_ctrl_arready      : out std_logic;
    s_axi_ctrl_araddr       : in  std_logic_vector (  7 downto 0 );

    s_axi_ctrl_rvalid       : out std_logic;
    s_axi_ctrl_rready       : in  std_logic;
    s_axi_ctrl_rdata        : out std_logic_vector ( 31 downto 0 );
    s_axi_ctrl_rresp        : out std_logic_vector (  1 downto 0 );

    s_axi_ctrl_awvalid      : in  std_logic;
    s_axi_ctrl_awready      : out std_logic;
    s_axi_ctrl_awaddr       : in  std_logic_vector (  7 downto 0 );

    s_axi_ctrl_wvalid       : in  std_logic;
    s_axi_ctrl_wready       : out std_logic;
    s_axi_ctrl_wdata        : in  std_logic_vector ( 31 downto 0 );
    s_axi_ctrl_wstrb        : in  std_logic_vector (  3 downto 0 );
    
    s_axi_ctrl_bvalid       : out std_logic;
    s_axi_ctrl_bready       : in  std_logic;
    s_axi_ctrl_bresp        : out std_logic_vector (  1 downto 0 );

    m_axi_data_awvalid      : out std_logic;
    m_axi_data_awready      : in  std_logic;
    m_axi_data_awid         : out std_logic_vector (  3 downto 0 ) := (others => '0');
    m_axi_data_awaddr       : out std_logic_vector ( 63 downto 0 );
    m_axi_data_awlen        : out std_logic_vector (  7 downto 0 );
    m_axi_data_awsize       : out std_logic_vector (  2 downto 0 );
    m_axi_data_awburst      : out std_logic_vector (  1 downto 0 );
    m_axi_data_awlock       : out std_logic;
    m_axi_data_awcache      : out std_logic_vector (  3 downto 0 );
    m_axi_data_awprot       : out std_logic_vector (  2 downto 0 );

    m_axi_data_wvalid       : out std_logic;
    m_axi_data_wready       : in  std_logic;
    m_axi_data_wid          : out std_logic_vector (  3 downto 0 ) := (others => '0');
    m_axi_data_wdata        : out std_logic_vector ( 31 downto 0 );
    m_axi_data_wstrb        : out std_logic_vector (  3 downto 0 );
    m_axi_data_wlast        : out std_logic;

    m_axi_data_bvalid       : in  std_logic;
    m_axi_data_bready       : out std_logic;
    m_axi_data_bid          : in  std_logic_vector (  3 downto 0 );
    m_axi_data_bresp        : in  std_logic_vector (  1 downto 0 )
);
end entity AwesomeModule;

architecture struct of AwesomeModule is

    constant PRBS_POLYNOMIAL        : std_logic_vector ( 31 downto 0 ) := (31 => '1', 28 => '1', others => '0');
    constant PRBS_INIT              : PRBS_POLYNOMIAL'subtype := PRBS_POLYNOMIAL;

    constant REG_IS                 : natural := 16#00#;
    constant REG_IE                 : natural := 16#04#;
    constant REG_GIE                : natural := 16#08#;
    constant REG_CTRL               : natural := 16#0C#;
    constant REG_BUF_ADDR_L         : natural := 16#10#;
    constant REG_BUF_ADDR_H         : natural := 16#14#;
    constant REG_BUF_SIZE           : natural := 16#18#;

    constant N_REG                  : natural := REG_BUF_SIZE/4 + 1;

    constant IRQ_DONE               : natural := 0;
    constant IRQ_ERROR              : natural := 1;

    constant CTRL_START             : natural := 0;
    constant CTRL_RESET             : natural := 31;

    signal soft_reset               : std_logic;
    signal logic_reset              : std_logic;

    signal prbs_m_axis_tdata        : std_logic_vector ( m_axi_data_wdata'range );
    signal prbs_m_axis_tvalid       : std_logic;
    signal prbs_m_axis_tready       : std_logic;

    signal ctrl_buffer_addr         : std_logic_vector ( m_axi_data_awaddr'range );
    signal ctrl_buffer_size_bytes   : std_logic_vector ( 23 downto 0 );
    signal ctrl_buffer_size_beats   : std_logic_vector ( ctrl_buffer_size_bytes'high downto log2(m_axi_data_wdata'length / 8) );
    signal ctrl_buffer_valid        : std_logic;
    signal ctrl_buffer_ready        : std_logic;

    signal ctrl_wr_done             : std_logic;
    signal ctrl_wr_error            : std_logic;

    signal reg_rd                   : std_logic;
    signal reg_wr                   : std_logic;
    signal reg_addr                 : unsigned ( s_axi_ctrl_araddr'range );
    signal reg_wdata                : std_logic_vector ( 31 downto 0 );
    signal reg_rdata                : std_logic_vector ( 31 downto 0 );
    signal reg_rvalid               : std_logic := '0';

    signal regs                     : StlvArray32_t ( 0 to N_REG - 1 ) := (others => (others => '0'));

begin

    p_ctrl : process ( clk )
    begin
        if rising_edge(clk) then
            soft_reset <= '0';
            reg_rvalid <= '0';
            reg_rdata <= (others => '-');

            if rst = '1' then
                ctrl_buffer_valid <= '0';
                regs <= (others => (others => '0'));

            else
                reg_rdata <= regs(to_integer(reg_addr)/4);
                reg_rvalid <= reg_rd;

                if ctrl_buffer_ready = '1' then
                    ctrl_buffer_valid <= '0';
                end if;

                if reg_wr = '1' then
                    case to_integer(reg_addr) is
                    when REG_IS =>
                        regs(REG_IS/4) <= regs(REG_IS/4) and not reg_wdata;

                    when REG_IE | REG_GIE | REG_BUF_ADDR_L | REG_BUF_ADDR_H | REG_BUF_SIZE  =>
                        regs(to_integer(reg_addr)/4) <= reg_wdata;
                        
                    when REG_CTRL =>
                        if reg_wdata(CTRL_START) = '1' then
                            ctrl_buffer_valid <= '1';
                        end if;

                        if reg_wdata(CTRL_RESET) = '1' then
                            soft_reset <= '1';
                        end if;

                    when others =>
                        -- no op
                    end case;
                end if;

                regs(REG_IS/4)(IRQ_DONE) <= '1' when ctrl_wr_done = '1';
                regs(REG_IS/4)(IRQ_ERROR) <= '1' when ctrl_wr_error = '1';

            end if;
        end if;
    end process p_ctrl;

    irq <= or(regs(REG_IS/4) and regs(REG_IE/4)) and regs(REG_GIE/4)(0);

    regs(REG_CTRL/4)(CTRL_START) <= ctrl_buffer_valid;
    ctrl_buffer_size_bytes <= regs(REG_BUF_SIZE/4)(ctrl_buffer_size_bytes'range);
    ctrl_buffer_addr <= regs(REG_BUF_ADDR_H/4) & regs(REG_BUF_ADDR_L/4);

    logic_reset <= rst or soft_reset;

    i_prbs_gen : entity olo.olo_base_prbs
    generic map (
        LfsrWidth_g     => PRBS_POLYNOMIAL'length,
        Polynomial_g    => PRBS_POLYNOMIAL,
        Seed_g          => PRBS_INIT,
        BitsPerSymbol_g => prbs_m_axis_tdata'length
    )
    port map (
        -- Control Ports
        Clk              => clk,
        Rst              => logic_reset,
        -- Output
        Out_Data         => prbs_m_axis_tdata,
        Out_Ready        => prbs_m_axis_tready,
        Out_Valid        => prbs_m_axis_tvalid
    );

    ctrl_buffer_size_beats <= ctrl_buffer_size_bytes(ctrl_buffer_size_beats'range);

    i_axi_master : entity olo.olo_axi_master_simple
    generic map (
        -- AXI Configuration
        AxiAddrWidth_g              => m_axi_data_awaddr'length,
        AxiDataWidth_g              => m_axi_data_wdata'length,
        -- User Configuration
        UserTransactionSizeBits_g   => ctrl_buffer_size_beats'length,
        DataFifoDepth_g             => 512,
        ImplRead_g                  => false,
        ImplWrite_g                 => true
    )
    port map (
        -- Control Signals
        Clk             => clk,
        Rst             => logic_reset,
        -- User Command Interface
        CmdWr_Addr      => ctrl_buffer_addr,
        CmdWr_Size      => ctrl_buffer_size_beats,
        CmdWr_LowLat    => '0',
        CmdWr_Valid     => ctrl_buffer_valid,
        CmdWr_Ready     => ctrl_buffer_ready,
        -- Write Data
        Wr_Data         => prbs_m_axis_tdata,
        Wr_Be           => (others => '1'),
        Wr_Valid        => prbs_m_axis_tvalid,
        Wr_Ready        => prbs_m_axis_tready,
        -- Response
        Wr_Done         => ctrl_wr_done,
        Wr_Error        => ctrl_wr_error,
        -- AXI Address Write Channel
        M_Axi_AwAddr    => m_axi_data_awaddr,
        M_Axi_AwLen     => m_axi_data_awlen,
        M_Axi_AwSize    => m_axi_data_awsize,
        M_Axi_AwBurst   => m_axi_data_awburst,
        M_Axi_AwLock    => m_axi_data_awlock,
        M_Axi_AwCache   => m_axi_data_awcache,
        M_Axi_AwProt    => m_axi_data_awprot,
        M_Axi_AwValid   => m_axi_data_awvalid,
        M_Axi_AwReady   => m_axi_data_awready,
        -- AXI Write Data Channel
        M_Axi_WData     => m_axi_data_wdata,
        M_Axi_WStrb     => m_axi_data_wstrb,
        M_Axi_WLast     => m_axi_data_wlast,
        M_Axi_WValid    => m_axi_data_wvalid,
        M_Axi_WReady    => m_axi_data_wready,
        -- AXI Write Response Channel
        M_Axi_BResp     => m_axi_data_bresp,
        M_Axi_BValid    => m_axi_data_bvalid,
        M_Axi_BReady    => m_axi_data_bready
    );

    i_axil_slave : entity olo.olo_axi_lite_slave
    generic map (
        AxiAddrWidth_g      => s_axi_ctrl_araddr'length,
        AxiDataWidth_g      => s_axi_ctrl_rdata'length
    )
    port map (
        -- Control Sgignals
        Clk               => clk,
        Rst               => rst,
        -- AXI-Lite Interface
        -- AR channel
        S_AxiLite_ArAddr  => s_axi_ctrl_araddr,
        S_AxiLite_ArValid => s_axi_ctrl_arvalid,
        S_AxiLite_ArReady => s_axi_ctrl_arready,
        -- AW channel
        S_AxiLite_AwAddr  => s_axi_ctrl_awaddr,
        S_AxiLite_AwValid => s_axi_ctrl_awvalid,
        S_AxiLite_AwReady => s_axi_ctrl_awready,
        -- W channel
        S_AxiLite_WData   => s_axi_ctrl_wdata,
        S_AxiLite_WStrb   => s_axi_ctrl_wstrb,
        S_AxiLite_WValid  => s_axi_ctrl_wvalid,
        S_AxiLite_WReady  => s_axi_ctrl_wready,
        -- B channel
        S_AxiLite_BResp   => s_axi_ctrl_bresp,
        S_AxiLite_BValid  => s_axi_ctrl_bvalid,
        S_AxiLite_BReady  => s_axi_ctrl_bready,
        -- R channel
        S_AxiLite_RData   => s_axi_ctrl_rdata,
        S_AxiLite_RResp   => s_axi_ctrl_rresp,
        S_AxiLite_RValid  => s_axi_ctrl_rvalid,
        S_AxiLite_RReady  => s_axi_ctrl_rready,
        -- Register Interface
        unsigned(Rb_Addr) => reg_addr,
        Rb_Wr             => reg_wr,
        Rb_ByteEna        => open, -- sorry...
        Rb_WrData         => reg_wdata,
        Rb_Rd             => reg_rd,
        Rb_RdData         => reg_rdata,
        Rb_RdValid        => reg_rvalid
    );

end architecture struct;

