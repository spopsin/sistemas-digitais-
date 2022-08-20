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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Neander is
      Port( 
      entrada : in STD_LOGIC_VECTOR (7 downto 0);
      clk: in STD_LOGIC;
      rst: in STD_LOGIC;         
      saida: out STD_LOGIC_VECTOR (7 downto 0));
end Neander;

architecture Behavioral of Neander is
--PC
signal incPC: STD_LOGIC;   
signal reg_PC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--MUX
signal reg_MUX : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--reg_REM
signal reg_REM : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--RDM
signal reg_RDM : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');


--reg_NZ
signal reg_NZ: STD_LOGIC_VECTOR (1 downto 0):= (others=> '0');

--ULA
signal X : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
signal Y : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
signal ULA : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');

--AC
signal reg_AC : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); 

--RI
signal opcode : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
      
--UC
signal cargaPC: STD_LOGIC;
signal cargaREM: STD_LOGIC;
signal cargaAC: STD_LOGIC;
signal cargaRDM: STD_LOGIC;
signal cargaRI: STD_LOGIC;
signal sel: STD_LOGIC_VECTOR (2 downto 0) := (others => '0'); 
signal cargaNZ: std_logic;

type T_STATE is (t0,t1,t2,t3,t4,t5,t6,t7,STD_HLT,mul_msb); 
signal estado, prox_estado : T_STATE;

type inst is (NOP,STA,LDA,ADD,OROP,ANDOP,NOTOP,JMP,JN,JZ,HLT,SHL,MUL);
signal inst : inst;

begin

--PC	
process (clk, rst)
begin 
    if(rst = '1') then
        reg_PC <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaPC = '1') then
            reg_PC <= reg_RDM;
        elsif (incPC = '1') then
            reg_PC <= reg_PC + 1;
        else
				reg_PC <= reg_PC;
		  end if;
    end if;
end process;

--MUX 
process(sel) is
begin
    if (sel = '0') then
        reg_MUX <= reg_PC; 
    else
        reg_MUX <= reg_RDM;
    end if; 
end process;

--reg_REM
process (clk, rst) is
begin 
    if(rst = '1') then
        reg_REM <= (others => '0');
    elsif(clk = '1' and  clk'event) then
			if (cargaREM = '1') then
            reg_REM <= reg_MUX;
			else 
				reg_REM <= reg_REM;
        end if;
    end if;
end process;

--RDM
process (clk, rst) is
begin
    if(rst = '1') then
        reg_RDM <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaRDM = '1') then
            reg_RDM <= reg_AC;
        else
            reg_RDM <= reg_REM;
        end if;
    end if;
end process;

------------------------RESOLVER---------------------------
--ULA
X <= reg_AC;
Y <= reg_RDM;

process(sel, X, Y) is
begin
	case sel is
		when "000" => 
			ULA <= std_logic_vector(unsigned(X) + unsigned(Y));
		when "001" =>
			ULA <= X and Y;
		when "010" =>
			ULA <= "00000000" & (X or Y);
		when "011" =>
			ULA <= not X;
			ULA <= X or Y;
		when "101" =>	
			if(shift_done = '0') then
				ULA <= "00000000" & X(6 downto 0) & '0';
			end if; 
		when "110" =>	
			ULA <= (X  * Y );
		when "100" =>
			ULA <= "00000000" & Y;
			ULA <= not X;
		when others =>
			ULA <= "00000000" & Y;
	end case;
			
    elsif inst = OPNOT then --NOT
        
    elsif inst = OPSUB then --SUB
        ULA <= std_logic_vector(unsigned(X) - unsigned(Y));
    elsif inst = OPXOR then --XOR
        ULA <= X xor Y;    
    else
        ULA <= ULA;
    end if;  
	end if;
    
end process;
-----------------------------------------------------------------

--reg_NZ
process (clk, rst) is
begin 
		if(rst = '1') then
			reg_NZ <= (others => '0');
		elsif(clk = '1' and  clk'event) then
			if (cargaNZ = '1') then
				if ULA < 0 then 
					reg_NZ(1) <= '1';
				else
					reg_NZ(1) <= '0';
				end if;
    
				if ULA = 0 then
					reg_NZ(0) <= '1'; 
				else
					reg_NZ(0) <= '0';
				end if;
			else
				reg_NZ <= reg_NZ;
        end if;
		end if;
end process;

--AC
process (clk, rst) is
begin 
    if(rst = '1') then
        reg_AC <= (others => '0');
    elsif(clk = '1' and  clk'event) then
        if (cargaAC = '1') then
            reg_AC <= ULA;
        end if;
    end if;
end process;

-- RI(opcode)
process (clk, rst) is
begin 
    if(rst = '1') then
        opcode <= (others => '0');
    elsif(clk = '1' and  clk'event) then
			if (cargaRI = '1') then
            opcode <= reg_RDM;
			else
				opcode <= opcode;
        end if;
    end if;
end process;

-- Decodificador
process (opcode) begin  
case  opcode(7 downto 4) is
	
			when "0000" => inst <= NOP;
			when "0001" => inst <= STA;
			when "0010" => inst <= LDA;
			when "0011" => inst <= ADD;
			when "0100" => inst <= OPOR;
			when "0101" => inst <= OPAND;
			when "0110" => inst <= OPNOT;
			when "0111" => inst <= SUB; -- <---
			when "1000" => inst <= JMP;
			when "1001" => inst <= JN;
			when "1010" => inst <= JZ; 
			when "1011" => inst <= SHL;
			when "1100" => inst <= MUL;
			when "1101" => inst <= OPXOR; -- <---
			when others => inst <= HLT;
		 
end case;
end process;

--UC
process(rst, clk) is
begin
		if(rst = '1') then
			estado <= t0;
		elsif(clk = '1' and  clk'event) then
			estado <= prox_estado;
    end if;
end process;

Process(cargaAC,cargaNZ,sel,cargaPC,incPC,write_enable,cargaREM,estado,inst)

Begin
case estado is
when t0 =>
	cargaPC <= (others => '0'); -- Zera o que veio do t4
	cargaREM     <= '1';
	cargaAC <= (others => '0'); -- Zera o que veio do t3 e t7 
	cargaRDM <= (others => '0');
	cargaRI <= (others => '0');
	sel <= (others => '0');
	carganz <= (others => '0');   -- Zera o que veio do t3 e t7  
	incPC <= (others => '0');   -- Zera o que veio do t3
	--write_enable <= "0";   -- Zera o que veio do t7
	--loadREM <= '0';
	prox_estado <= t1;

when t1 =>
	cargaREM <= '0';       -- Zera o que veio do t0
	mem_in <= reg_REM;	-- Read
	incPC <= '1';
	prox_estado <= t2;

when t2 =>
	incPC <= '0';   -- Zera o que veio do t2
	cargaRI <= '1';
	prox_estado <= t3;

when t3 => 
	incPC <= '0'; 
	cargaRI <= '0' ;        -- Zera o que veio do t2
	if (inst= STA or inst=LDA or inst=MUL or inst=ADD or inst=OROP or inst=ANDOP or inst=JMP) then
		sel <= '0';
		cargaREM <= '1';
		prox_estado <= t4;
	elsif (inst=OPNOT) then
		sel <= "011";
		cargaAC <= '1';
		cargaNZ <= '1';
		prox_estado <= t0;
	elsif (inst=SHL) then
		shift_done <= '0';
		sel <= "101";
		cargaAC <= '1';
		cargaNZ <= '1';
		prox_estado <= t4;
	elsif (inst=JN and reg_NZ(1)='0') then
		incPC <= '1';
		prox_estado <= t0;
	elsif (inst=JN and reg_NZ(1)='1') then
		sel <= '0';
		cargaREM <= '1';
		prox_estado <= t4;
	elsif (inst=JZ and reg_NZ(0)='1') then
		sel <= '0';
		cargaREM <= '1';
		prox_estado <= t4;
	elsif (inst=JZ and reg_NZ(0)='0') then
		incPC <= '1';
		prox_estado <= t0;
	elsif (inst=NOP) then
		prox_estado <= t0;
	elsif (inst=HLT) then
		incPC <= '0';
		prox_estado <= hlt_state;
	else
		prox_estado <= t4;
	end if;
	
when t4 => 
		sel <= '0';  
		incPC <= '0';
		cargaAC  <= '0';         -- Zera o que veio do t3
		cargaNZ  <= '0';        -- Zera o que veio do t3
		cargaREM <= '0';        -- Zera o que veio do t3
		if(inst= STA or inst=LDA or inst=MUL or inst=ADD or inst=OROP or inst=ANDOP) then
			mem_in<= reg_REM;-- Read;
			incPC <= '1';
			prox_estado <= t5;
		elsif(inst=JMP) then
			mem_in<= reg_REM;-- Read
			prox_estado <= t5;
		elsif(inst=JN and reg_NZ(1)='1') then
			mem_in<= reg_REM;-- Read
			prox_estado <= t5;
		elsif(inst=JZ and reg_NZ(0)='1') then
			mem_in<= reg_REM;-- Read
			prox_estado <= t5;
		else 
			prox_estado <= t5;
			shift_done <= '1'; -- Para garantir que não irá recair duas vezes no shift na instrução seguinte ao shift
		end if;
		
when t5 =>
	incPC <= '0' ; 		   -- Zera o que veio do t4
		if(inst= STA or inst=LDA or inst=MUL or inst=ADD or inst=OROP or inst=ANDOP) then
			sel <= '1';
			cargaREM <= '1';
			prox_estado <= t6;
		elsif(inst=JMP ) then
			cargaPC <= '1';
			prox_estado <= t0;
		elsif(inst=JN and reg_NZ(1)='1') then
			cargaPC <= '1';
			prox_estado <= t0;
		elsif(inst=JZ and reg_NZ(0)='1') then
			cargaPC <= '1';
			prox_estado <= t0;
		else
			prox_estado <= t6;
		end if;
when t6 =>
	incPC <= '0'; 
	sel <= (others => '0');       -- Zera o que veio do t5
	cargaREM <= '0';  -- Zera o que veio do t5
	cargaPC <= '0';   -- Zera o que veio do t5
		-- Foi tirado o RDM, dai nao tem inst=STA nesse estado
		if(inst=LDA or inst=MUL or inst=ADD or inst=OROP or inst=ANDOP) then
			mem_in<= reg_REM;	-- Read
			prox_estado <= t7;
		else
			prox_estado <= t7;
		end if;
when t7 =>
		incPC <= '0'; 
		if(inst=STA) then
			mem_in<=AC_out;-- Colocar no memoria_in o dado antes de gravar
			write_enable <= "1";
			prox_estado <= t0;
		elsif(inst=LDA) then
			sel <= "100";
			cargaAC <= '1';
			cargaNZ <= '1';
			prox_estado <= t0;
		elsif(inst=MUL) then
			sel <= "110";
			cargaAC <= '1';
			cargaNZ <= '1';
			prox_estado <= mul_msb;
		elsif(inst=ADD) then
			sel <= "000";
			cargaAC <= '1';
			cargaNZ <= '1';
			prox_estado <= t0;
		elsif(inst=OROP) then
			sel <= "010";
			cargaAC <= '1';
			cargaNZ <= '1';
			prox_estado <= t0;
		elsif(inst=ANDOP) then
			sel <= "001";
			cargaAC <= '1';
			cargaNZ <= '1';
			prox_estado <= t0;
		else
			prox_estado <= t0;
		end if;
when mul_msb =>		--Grava o valor alto da multiplicacao no endereco 100 da memoria
		mem_in<=ula_out_reg(15 downto 8);
		loadREM <= '1';
		write_enable <= "1";
		prox_estado <= t0;	
		
when hlt_state =>		
	incPC <= '0'; 
		prox_estado <= hlt_state;
		
end case;
End process; 
S <= reg_AC;
Y <= reg_RDM;


end Behavioral;
