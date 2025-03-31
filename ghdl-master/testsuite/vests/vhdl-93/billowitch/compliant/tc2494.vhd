
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
-- $Id: tc2494.vhd,v 1.2 2001-10-26 16:29:48 paw Exp $
-- $Revision: 1.2 $
--
-- ---------------------------------------------------------------------

ENTITY c07s03b03x00p04n02i02494ent IS
END c07s03b03x00p04n02i02494ent;

ARCHITECTURE c07s03b03x00p04n02i02494arch OF c07s03b03x00p04n02i02494ent IS

BEGIN
  TESTING: PROCESS
    function check (x : integer) return integer is
    begin
      return (10 * x);
    end;
    variable q1: integer := 12;
    variable q2: integer ;
  BEGIN
    q2 := check (q1) + 24 - check (2);
    assert NOT( q2 = 124 )
      report "***PASSED TEST: c07s03b03x00p04n02i02494"
      severity NOTE;
    assert ( q2=124 )
      report "***FAILED TEST: c07s03b03x00p04n02i02494 - The actual parameter can be specified explicitly by an association element in the association list."
      severity ERROR;
    wait;
  END PROCESS TESTING;

END c07s03b03x00p04n02i02494arch;
