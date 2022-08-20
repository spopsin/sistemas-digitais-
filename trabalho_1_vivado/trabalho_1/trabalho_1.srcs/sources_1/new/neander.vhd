----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.08.2022 22:25:57
-- Design Name: 
-- Module Name: neander - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity neander is
      Port( 
      entrada : in STD_LOGIC_VECTOR (7 downto 0);
      clk: in STD_LOGIC;
      rst: in STD_LOGIC;
      inc: in STD_LOGIC;            
      cargaPC: in STD_LOGIC;
      cargaREM: in STD_LOGIC;
      cargaAC: in STD_LOGIC;
      cargaRDM: in STD_LOGIC;
      cargaRI: in STD_LOGIC;
      sel: in STD_LOGIC;            
      N: out std_logic;
      Z: out std_logic;
      saida: out STD_LOGIC_VECTOR (7 downto 0));
end neander;

architecture Behavioral of neander is
--PC
signal entradaPC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaPC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--MUX
signal A : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal B : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaMUX : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--reg_MEM
signal entradaREM : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaREM : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--RDM
signal entradaRDM : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaRDM : STD_LOGIC_VECTOR (7 downto 0);

--ULA
signal X : STD_LOGIC_VECTOR (7 downto 0);
signal Y : STD_LOGIC_VECTOR (7 downto 0);
signal ULA : STD_LOGIC_VECTOR (7 downto 0);
signal saidaULA : STD_LOGIC_VECTOR (7 downto 0);

--AC
signal entradaAC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaAC : STD_LOGIC_VECTOR (7 downto 0);
signal regAC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); 

--RI
signal entradaRI : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal saidaRI : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal RI : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
            
begin

--PC
entradaPC <= saidaRDM;
	
process (clk, rst, entradaPC, cargaPC, inc)
begin 
    if(rst = '1') then
        saidaPC <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaPC = '1') then
            saidaPC <= entradaPC;
        elsif (inc = '1') then
            saidaPC <= saidaPC + 1;
        end if;
    end if;
end process;

--MUX 
A <= saidaPC;
B <= saidaRDM;

process(A, B, sel) is
begin
    if (sel = '0') then
        saidaMUX <= A; 
    else
        saidaMUX <= B;
    end if; 
end process;

--reg_MEM
entradaREM <= saidaMUX;

process (clk, rst, entradaREM, cargaREM) is
begin 
    if(rst = '1') then
        saidaREM <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaREM = '1') then
            saidaREM <= entradaREM;
        end if;
    end if;
end process;

--RDM
entradaRDM <= saidaAC;

process (clk, rst, entradaRDM, cargaRDM, entrada) is
begin
    if(rst = '1') then
        saidaRDM <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaRDM = '1') then
            saidaRDM <= entradaRDM;
        else
            saidaRDM <= entrada;
        end if;
    end if;
end process;

--ULA
X <= saidaAC;
Y <= saidaRDM;
RI <= saidaRI;

process(X, Y, RI, ULA, saidaULA) is
begin
    if RI="00000000" then --NOP
        ULA <= ULA;         
    elsif RI="00110000" then--ADD
        ULA <= std_logic_vector(unsigned(X) + unsigned(Y));
    elsif RI="01000000" then --OR
        ULA <= X or Y;
    elsif RI="01010000" then --AND
        ULA <= X and Y;
    elsif RI="01100000" then --NOT
        ULA <= not X;
    elsif RI="01110000" then --SUB
        ULA <= std_logic_vector(unsigned(X) - unsigned(Y));
    elsif RI="10000000" then --XOR
        ULA <= X xor Y;    
    else
        ULA <= ULA;
    end if;
            
    if ULA < 0 then 
        N <= '1'; 
    else 
        N <= '0';
    end if;
    
    if ULA = 0 then 
        Z <= '1'; 
    else 
        Z <= '0';
    end if;   

    saidaULA <= ULA;    
    
end process;

--AC
entradaAC <= saidaULA;

process (clk, rst, cargaAC, entradaAC) is
begin 
    if(rst = '1') then
        saidaAC <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaAC = '1') then
            saidaAC <= entradaAC;
        end if;
    end if;
end process;
saida <= saidaAC;

--RI
entradaRI <= saidaRDM;

process (clk, rst, entradaRI, cargaRI) is
begin 
    if(rst = '1') then
        saidaRI <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaRI = '1') then
            saidaRI <= entradaRI;
        end if;
    end if;
end process;
end Behavioral;
