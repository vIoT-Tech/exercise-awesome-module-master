entity ent is
end entity;

architecture a of ent is
begin
  main : process is
  begin
    report "s" & to_string(1);
    wait;
  end process;
end architecture;
