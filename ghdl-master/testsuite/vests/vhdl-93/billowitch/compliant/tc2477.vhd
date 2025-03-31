
-- Copyright (C) 2001 Bill Billowitch.

-- Some of the work to develop this test suite was done with Air Force
-- support.  The Air Force and Bill Billowitch assume no
-- responsibilities for this software.

-- This file is part of VESTs (Vhdl tESTs).

-- VESTs is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by the
-- Free Software Foundation; either version 2 of the License, or (at
-- your option) any later version. 

-- VESTs is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
-- for more details. 

-- You should have received a copy of the GNU General Public License
-- along with VESTs; if not, write to the Free Software Foundation,
-- Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 

-- ---------------------------------------------------------------------
--
-- $Id: tc2477.vhd,v 1.2 2001-10-26 16:29:48 paw Exp $
-- $Revision: 1.2 $
--
-- ---------------------------------------------------------------------

ENTITY c07s03b02x02p13n04i02477ent IS
END c07s03b02x02p13n04i02477ent;

ARCHITECTURE c07s03b02x02p13n04i02477arch OF c07s03b02x02p13n04i02477ent IS
  type    index_values is (one, two, three);
  type    ucarr is array (index_values range <>) of Boolean;      
  subtype carr  is ucarr (index_values'low to index_values'high);
  function f2 (i : integer) return carr is
  begin
    return (True, True, False);  
  end f2;
BEGIN
  TESTING: PROCESS
    variable k : carr;
  BEGIN
    k := f2(1);
    assert NOT(k=(True,True,False)) 
      report "***PASSED TEST: c07s03b02x02p13n04i02477" 
      severity NOTE;
    assert (k=(True,True,False)) 
      report "***FAILED TEST: c07s03b02x02p13n04i02477 - The leftmost bound is determined by the applicable index constraint."
      severity ERROR;
    wait;
  END PROCESS TESTING;

END c07s03b02x02p13n04i02477arch;
