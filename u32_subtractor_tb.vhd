----------------------------------------------------------------------------------
-- Author: Onica Alexandru Valentin
-- 
-- Module Name: u32_subtractor_tb - Behavioral
-- Project Name: SSDS mini-assignment
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity u32_subtractor_tb is
end u32_subtractor_tb;

architecture Behavioral of u32_subtractor_tb is

component design_1_wrapper is
  port (
  B : in STD_LOGIC_VECTOR ( 31 downto 0 );
  A : in STD_LOGIC_VECTOR ( 31 downto 0 );
  S : out STD_LOGIC_VECTOR ( 32 downto 0 );
  clk_100MHz : in STD_LOGIC;
  SCLR : in STD_LOGIC;
  CE : in STD_LOGIC
);
end component;
constant latency : natural:= 3 ; --To change in case of different latency configuration
signal clk,rst,CE: std_logic;
signal A,B: std_logic_vector(31 downto 0);
signal S,S_exp: std_logic_vector(32 downto 0);
type inarr is array (0 to latency-1) of std_logic_vector(31 downto 0); --In order to print out which inputs generated wrong output
signal a_v,b_v: inarr;

begin
    SubComp: design_1_wrapper port map (A => A,B => B,S => S,SCLR=>rst,clk_100MHz => clk,CE=>CE);
                                        
    clkproc: process
    begin
        clk <= '0';
        wait for 5ns;
        clk <= '1';
        wait for 5ns;
    end process clkproc;
    
    read_in_proc: process
        FILE fd_in: text;
        variable inline: line;    
        variable ain,bin: std_logic_vector(31 downto 0);
    begin
        A <= (others=>'0');
        B <= (others=>'1');
        CE<='1';
        rst<='1';
        wait until clk'event and clk='1';
        wait until clk'event and clk='0';
        rst<='0';
        file_open(fd_in,"vector.txt",read_mode);
        for i in 0 to 10 loop
            wait until clk'event and clk='0';
        end loop;
        
        while not endfile(fd_in) loop
            readline(fd_in,inline);
            read(inline,ain);
            read(inline,bin);
            A<=ain;
            B<=bin;
            wait until clk'event and clk='0';
        end loop;
        file_close(fd_in);
        
        for i in 0 to latency-1 loop 
            wait until clk'event and clk='0';
        end loop;
        CE<='0';
        wait;
    end process read_in_proc;
    
    read_out_proc: process
        FILE fd_out: text;
        variable inline: line;    
        variable s_v: std_logic_vector(32 downto 0);
    begin
        file_open(fd_out,"expected.txt",read_mode);
        for i in 0 to 11+latency loop
            wait until clk'event and clk='1';
        end loop;
        
        while not endfile(fd_out) loop
            readline(fd_out,inline);
            read(inline,s_v);
            wait until clk'event and clk='1';
            S_exp<=s_v;
            wait until clk'event and clk='0';
            --assert (S=s_v) report "Result different from expected one" severity error; --Use to minimize running time and memory usage
            
            assert (S=s_v) report "output of " & to_hstring(a_v(0))   --Use to show which inputs are generating the wrong outputs,
                                    & "h minus " & to_hstring(b_v(0))   --works with a_v and b_v vectors.                           
                                    & "h equals " & to_hstring(S)
                                    & "h , DIFFERENT from expected " 
                                    & to_hstring(s_v) & "h "
                                    severity error;  
                                                    
        end loop;
        file_close(fd_out);
        wait;
    end process read_out_proc;
    
    savein: process
    begin
        wait until clk'event and clk='0';
        for i in 0 to latency-2 loop
            a_v(i)<=transport a_v(i+1) after 5ns;
            b_v(i)<=transport b_v(i+1) after 5ns;
        end loop;
        a_v(latency-1)<= transport A after 5ns;
        b_v(latency-1)<= transport B after 5ns;
    end process savein;
    
end Behavioral;