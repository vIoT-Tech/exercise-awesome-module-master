--  Highler level API to build a netlist - do some optimizations.
--  Copyright (C) 2019 Tristan Gingold
--
--  This file is part of GHDL.
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <gnu.org/licenses>.

with Netlists.Gates; use Netlists.Gates;
with Netlists.Builders; use Netlists.Builders;

package Netlists.Folds is
   --  Build a const from VAL.  Result is either a Const_UB32 or a Const_Bit.
   --  VAL is zero extended, so any width is allowed.
   --  But VAL must fit in the width.
   function Build2_Const_Uns (Ctxt : Context_Acc; Val : Uns64; W : Width)
                             return Net;

   --  Build a const from VAL.  Result is either a Const_SB32 or a Const_Bit.
   --  VAL is sign extended, so any width is allowed, but it must fit in the
   --  width.
   function Build2_Const_Int (Ctxt : Context_Acc; Val : Int64; W : Width)
                             return Net;

   function Build2_Const_Vec (Ctxt : Context_Acc; W : Width; V : Uns32_Arr)
                             return Net;

   --  Concatenate nets of ELS in reverse order.  So if ELS(L .. R), then
   --  ELS(L) will be at offset 0 (so the last input).
   function Build2_Concat (Ctxt : Context_Acc; Els : Net_Array) return Net;

   --  If L or R has a null width, return the other.
   function Build2_Concat2 (Ctxt : Context_Acc; L, R : Net) return Net;

   --  Truncate I to width W.  Merge if the input is an extend.
   function Build2_Trunc (Ctxt : Context_Acc;
                          Id : Module_Id;
                          I : Net;
                          W : Width;
                          Loc : Location_Type)
                         return Net;

   --  Zero extend, noop or truncate I so that its width is W.
   function Build2_Uresize (Ctxt : Context_Acc;
                            I : Net;
                            W : Width;
                            Loc : Location_Type)
                           return Net;

   --  Sign extend, noop or truncate I so that its width is W.
   function Build2_Sresize (Ctxt : Context_Acc;
                            I : Net;
                            W : Width;
                            Loc : Location_Type)
                           return Net;

   --  If IS_SIGNED is true, this is Build2_Sresize, otherwise Build2_Uresize.
   function Build2_Resize (Ctxt : Context_Acc;
                           I : Net;
                           W : Width;
                           Is_Signed : Boolean;
                           Loc : Location_Type)
                          return Net;

   --  Same as Build_Extract, but return I iff extract all the bits.
   function Build2_Extract
     (Ctxt : Context_Acc; I : Net; Off, W : Width) return Net;

   --  Return A -> B  ==  !A || B
   function Build2_Imp (Ctxt : Context_Acc; A, B : Net; Loc : Location_Type)
                       return Net;

   --  Return A & B.
   --  If A is No_Net, simply return B so that it is possible to easily build
   --  chain of conditions.
   function Build2_And (Ctxt : Context_Acc; A, B : Net; Loc : Location_Type)
                        return Net;

   --  Like Build_Compare but handle net of width 0.
   function Build2_Compare (Ctxt : Context_Acc;
                            Id   : Compare_Module_Id;
                            L, R : Net) return Net;

   --  INST is a dyn_insert gate that will be converted to a dyn_insert_en
   --  by using SEL as enable input.
   --  The old dyn_insert gate is removed.
   function Add_Enable_To_Dyn_Insert
     (Ctxt : Context_Acc; Inst : Instance; Sel : Net) return Instance;

   --  Specially handle 'and' to canonicalize clock edge: move them to the
   --  top of trees so that it is easily recognized by infere.
   --  If KEEP is true, R and L shouldn't be modified.
   function Build2_Canon_And (Ctxt : Context_Acc;
                              R, L : Net;
                              Keep : Boolean) return Net;
end Netlists.Folds;
