------------------------------------------------------------------------------
-- GALAXIAN TOP level implementation for Papilio boards
--
------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity papilio_top is
	port(
		--    FPGA_USE
		CLK_IN    : in  std_logic;

		I_RESET   : in  std_logic;
		-- controls
		PS2CLK1   : inout	std_logic;
		PS2DAT1   : inout	std_logic;

		--    SOUND OUT
		O_AUDIO_L : out std_logic;
		O_AUDIO_R : out std_logic;

		--    VGA (VIDEO) IF
		O_VIDEO_R : out std_logic_vector(3 downto 0);
		O_VIDEO_G : out std_logic_vector(3 downto 0);
		O_VIDEO_B : out std_logic_vector(3 downto 0);
		O_HSYNC   : out std_logic;
		O_VSYNC   : out std_logic
	);
end;

architecture RTL of papilio_top is
	signal W_CLK_24M          : std_logic := '0';
	signal W_CLK_18M          : std_logic := '0';
	signal W_CLK_12M          : std_logic := '0';
	signal W_CLK_6M           : std_logic := '0';

	signal P1_CSJUDLR         : std_logic_vector( 6 downto 0) := (others => '0'); -- player 1 controls
	signal P2_CSJUDLR         : std_logic_vector( 6 downto 0) := (others => '0'); -- player 2 controls

	signal W_H_SYNC           : std_logic := '0';
	signal W_V_SYNC           : std_logic := '0';
	signal W_CMPBLK           : std_logic := '0';
	signal W_SDAT_A           : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_SDAT_B           : std_logic_vector( 7 downto 0) := (others => '0');
	signal W_VID              : std_logic_vector(15 downto 0) := (others => '0');
	signal W_R                : std_logic_vector( 2 downto 0) := (others => '0');
	signal W_G                : std_logic_vector( 2 downto 0) := (others => '0');
	signal W_B                : std_logic_vector( 2 downto 0) := (others => '0');

	signal W_VGA              : std_logic_vector(15 downto 0) := (others => '0');

	signal ps2_codeready      : std_logic := '1';
	signal ps2_scancode       : std_logic_vector( 9 downto 0) := (others => '0');
begin
	inst_clocks : entity work.CLOCKGEN
	port map(
		CLKIN_IN   => CLK_IN,
		RST_IN     => I_RESET,
		O_CLK_24M  => W_CLK_24M,
		O_CLK_18M  => W_CLK_18M,
		O_CLK_12M  => W_CLK_12M,
		O_CLK_06M  => W_CLK_6M
	);

	inst_galaxian : entity work.galaxian
	port map(
		W_CLK_18M  => W_CLK_18M,
		W_CLK_12M  => W_CLK_12M,
		W_CLK_6M   => W_CLK_6M,

		P1_CSJUDLR => P1_CSJUDLR,
		P2_CSJUDLR => P2_CSJUDLR,

		I_RESET    => I_RESET,
		W_R        => W_R,
		W_G        => W_G,
		W_B        => W_B,
		W_H_SYNC   => W_H_SYNC,
		W_V_SYNC   => W_V_SYNC,
		W_SDAT_A   => W_SDAT_A,
		W_SDAT_B   => W_SDAT_B,
		O_CMPBL    => W_CMPBLK
	);

	inst_vga : entity work.VGA_SCANCONV
	port map(
		CLK        => W_CLK_6M,
		CLK_X4     => W_CLK_24M,
		--	input
		I_VIDEO    => W_VID,
		I_HSYNC    => W_H_SYNC,
		I_VSYNC    => W_V_SYNC,
		I_CMPBLK_N => W_CMPBLK,
		--	output
		O_VIDEO    => W_VGA,
		O_HSYNC    => O_HSYNC,
		O_VSYNC    => O_VSYNC,
		O_CMPBLK_N => open
	);

	W_VID <= "0000000" & W_R & W_G & W_B;

	O_VIDEO_R(3 downto 0) <= W_VGA(8 downto 6) & "0";
	O_VIDEO_G(3 downto 0) <= W_VGA(5 downto 3) & "0";
	O_VIDEO_B(3 downto 0) <= W_VGA(2 downto 0) & "0";

	inst_dacl : entity work.dac
	port map(
		clk_i   => W_CLK_24M,
		res_i   => I_RESET,
		dac_i   => W_SDAT_A,
		dac_o   => O_AUDIO_L
	);

	inst_dacr : entity work.dac
	port map(
		clk_i   => W_CLK_24M,
		res_i   => I_RESET,
		dac_i   => W_SDAT_B,
		dac_o   => O_AUDIO_R
	);

	-----------------------------------------------------------------------------
	-- Keyboard - active low buttons
	-----------------------------------------------------------------------------
	inst_kbd : entity work.Keyboard
	port map (
		Reset     => I_RESET,
		Clock     => W_CLK_18M,
		PS2Clock  => PS2CLK1,
		PS2Data   => PS2DAT1,
		CodeReady => ps2_codeready,  --: out STD_LOGIC;
		ScanCode  => ps2_scancode    --: out STD_LOGIC_VECTOR(9 downto 0)
	);

-- ScanCode(9)          : 1 = Extended  0 = Regular
-- ScanCode(8)          : 1 = Break     0 = Make
-- ScanCode(7 downto 0) : Key Code
	process(W_CLK_18M)
	begin
		if rising_edge(W_CLK_18M) then
			if I_RESET = '1' then
				P1_CSJUDLR <= (others=>'0');
				P2_CSJUDLR <= (others=>'0');
			elsif (ps2_codeready = '1') then
				case (ps2_scancode(7 downto 0)) is
					when x"05" =>	P1_CSJUDLR(6) <= not ps2_scancode(8);     -- P1 coin "F1"
					when x"04" =>	P2_CSJUDLR(6) <= not ps2_scancode(8);     -- P2 coin "F3"

					when x"06" =>	P1_CSJUDLR(5) <= not ps2_scancode(8);     -- P1 start "F2"
					when x"0c" =>	P2_CSJUDLR(5) <= not ps2_scancode(8);     -- P2 start "F4"

					when x"43" =>	P1_CSJUDLR(4) <= not ps2_scancode(8);     -- P1 jump "I"
										P2_CSJUDLR(4) <= not ps2_scancode(8);     -- P2 jump "I"

					when x"75" =>	P1_CSJUDLR(3) <= not ps2_scancode(8);     -- P1 up arrow
										P2_CSJUDLR(3) <= not ps2_scancode(8);     -- P2 up arrow

					when x"72" =>	P1_CSJUDLR(2) <= not ps2_scancode(8);     -- P1 down arrow
										P2_CSJUDLR(2) <= not ps2_scancode(8);     -- P2 down arrow

					when x"6b" =>	P1_CSJUDLR(1) <= not ps2_scancode(8);     -- P1 left arrow
										P2_CSJUDLR(1) <= not ps2_scancode(8);     -- P2 left arrow

					when x"74" =>	P1_CSJUDLR(0) <= not ps2_scancode(8);     -- P1 right arrow
										P2_CSJUDLR(0) <= not ps2_scancode(8);     -- P2 right arrow

					when others => null;
				end case;
			end if;
		end if;
	end process;

end RTL;
