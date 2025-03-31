package pkg1 is
  generic (type t; c : t);
  generic map (t => natural, c => 5);

  function f return t;
end pkg1;

package body pkg1 is
  function f return t is
  begin
    return c;
  end f;
end pkg1;

entity tb is
end tb;

architecture behav of tb is
begin
  assert work.pkg1.f = 5;
end behav;
