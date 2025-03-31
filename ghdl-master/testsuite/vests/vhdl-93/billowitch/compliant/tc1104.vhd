
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
-- $Id: tc1104.vhd,v 1.2 2001-10-26 16:29:39 paw Exp $
-- $Revision: 1.2 $
--
-- ---------------------------------------------------------------------

ENTITY c06s05b00x00p03n01i01104ent IS
END c06s05b00x00p03n01i01104ent;

ARCHITECTURE c06s05b00x00p03n01i01104arch OF c06s05b00x00p03n01i01104ent IS

BEGIN
  TESTING: PROCESS
    type FIVE    is range 1 to 5;
    type ABASE    is array (FIVE range <>) of BOOLEAN;
    subtype A1    is ABASE(FIVE);
    type R1 is record
                 RE1: A1;
               end record;
    type R2 is record
                 RE2: R1;
               end record;
    variable V1: A1;
    variable V2: R1 ; -- := (RE1=>(others=>TRUE));
    variable V3: R2 ; -- := (RE2=>(RE1=>(others=>TRUE)));
  BEGIN
    V1(2 to 4) := V3.RE2.RE1(2 to 4);  -- No_failure_here
    assert NOT(V1(2 to 4)=(false,false,false)) 
      report "***PASSED TEST: c06s05b00x00p03n01i01104" 
      severity NOTE;
    assert (V1(2 to 4)=(false,false,false)) 
      report "***FAILED TEST: c06s05b00x00p03n01i01104 - Prefix of a slice can be a selected name." 
      severity ERROR;
    wait;
  END PROCESS TESTING;

END c06s05b00x00p03n01i01104arch;
