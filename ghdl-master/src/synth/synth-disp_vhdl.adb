--  Disp a netlist in vhdl using the original entity.
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

with Outputs; use Outputs;
with Types; use Types;
with Name_Table;

with Vhdl.Prints;
with Vhdl.Std_Package;
with Vhdl.Ieee.Std_Logic_1164;
with Vhdl.Errors; use Vhdl.Errors;
with Vhdl.Utils; use Vhdl.Utils;

with Elab.Vhdl_Objtypes; use Elab.Vhdl_Objtypes;

with Netlists.Iterators; use Netlists.Iterators;
with Netlists.Disp_Vhdl; use Netlists.Disp_Vhdl;

package body Synth.Disp_Vhdl is
   procedure Disp_Signal (Desc : Port_Desc) is
   begin
      if Desc.W > 1 then
         Wr ("  subtype typ");
         Put_Name (Desc.Name);
         Wr (" is ");
         Put_Type (Desc.W);
         Wr_Line (";");
      end if;
      Wr ("  signal ");
      Put_Name (Desc.Name);
      Wr (": ");
      if Desc.W > 1 then
         Wr ("typ");
         Put_Name (Desc.Name);
      else
         Put_Type (Desc.W);
      end if;
      Wr_Line (";");
   end Disp_Signal;

   procedure Disp_Ports_As_Signals (M : Module)
   is
      Desc : Port_Desc;
   begin
      for I in 1 .. Get_Nbr_Inputs (M) loop
         Disp_Signal (Get_Input_Desc (M, I - 1));
      end loop;
      for I in 1 .. Get_Nbr_Outputs (M) loop
         Desc := Get_Output_Desc (M, I - 1);
         if Desc.Dir /= Port_Inout then
            --  inout ports are not prefixed, so they must not be declared
            --  as signals.
            Disp_Signal (Desc);
         end if;
      end loop;
   end Disp_Ports_As_Signals;

   procedure Disp_Pfx (Off : Uns32; W : Width; Full : Boolean) is
   begin
      if Full then
         return;
      end if;
      Wr (" (");
      if W > 1 then
         Wr_Uns32 (Off + W - 1);
         Wr (" downto ");
      end if;
      Wr_Uns32 (Off);
      Wr (')');
   end Disp_Pfx;

   procedure Disp_In_Lhs
     (Mname : String; Off : Uns32; W : Width; Full : Boolean) is
   begin
      Wr ("  wrap_" & Mname);
      Disp_Pfx (Off, W, Full);
      Wr (" <= ");
   end Disp_In_Lhs;

   function Is_Std_Logic_Array (Btype : Node) return Boolean is
   begin
      return Is_One_Dimensional_Array_Type (Btype)
        and then (Get_Base_Type (Get_Element_Subtype (Btype))
                    = Vhdl.Ieee.Std_Logic_1164.Std_Ulogic_Type);
   end Is_Std_Logic_Array;

   procedure Disp_In_Converter (Mname : String;
                                Pfx : String;
                                Off : Uns32;
                                Ptype : Node;
                                Typ : Type_Acc;
                                Full : Boolean)
   is
      Btype : constant Node := Get_Base_Type (Ptype);
      W : Width;
   begin
      case Get_Kind (Btype) is
         when Iir_Kind_Enumeration_Type_Definition =>
            if Btype = Vhdl.Ieee.Std_Logic_1164.Std_Ulogic_Type then
               --  Nothing to do.
               Disp_In_Lhs (Mname, Off, 1, Full);
               Wr_Line (Pfx & ";");
            else
               --  Any other enum.
               W := Typ.W;
               Disp_In_Lhs (Mname, Off, W, Full);
               if W = 1 then
                  Wr ("'0' when ");
               else
                  Wr ("std_logic_vector(to_unsigned(");
               end if;
               Wr (Name_Table.Image (Get_Identifier
                                        (Get_Type_Declarator (Ptype))));
               Wr ("'pos (" & Pfx & ")");
               if W = 1 then
                  Wr (" = 0 else '1';");
               else
                  Wr ("," & Width'Image (W) & "));");
               end if;
               Wr_Line;
            end if;
         when Iir_Kind_Integer_Type_Definition =>
            --  FIXME: signed or unsigned ?
            W := Typ.W;
            Disp_In_Lhs (Mname, Off, W, Full);
            if W > 1 then
               Wr ("std_logic_vector(");
            end if;
            if Typ.Drange.Is_Signed then
               Wr ("to_signed(");
            else
               Wr ("to_unsigned(");
            end if;
            Wr (Pfx & "," & Width'Image (W) & ")");
            if W > 1 then
               Wr (")");
            elsif W = 1 then
               Wr ("(0)");
            end if;
            Wr_Line (";");
         when Iir_Kind_Array_Type_Definition =>
            if Btype = Vhdl.Ieee.Std_Logic_1164.Std_Logic_Vector_Type then
               --  Nothing to do.
               W := Typ.Abound.Len;
               Disp_In_Lhs (Mname, Off, W, Full);
               Wr (Pfx);
               if W = 1 then
                  --  This is an array of length 1.  A scalar is used in the
                  --  netlist.
                  Wr (" (" & Pfx & "'left)");
               end if;
               Wr_Line (";");
            elsif Is_Std_Logic_Array (Btype) then
               W := Typ.Abound.Len;
               Disp_In_Lhs (Mname, Off, W, Full);
               if W > 1 then
                  if Full then
                     Wr ("typwrap_");
                     Wr (Mname);
                  else
                     Wr ("std_logic_vector");
                  end if;
                  Wr ("(");
               end if;
               Wr (Pfx);
               if W = 1 then
                  --  This is an array of length 1.  A scalar is used in the
                  --  netlist.
                  Wr (" (" & Pfx & "'left)");
               end if;
               if W > 1 then
                  Wr (')');
               end if;
               Wr_Line (";");
            elsif Btype = Vhdl.Std_Package.Bit_Vector_Type_Definition then
               W := Typ.Abound.Len;
               Disp_In_Lhs (Mname, Off, W, Full);
               Wr ("to_stdlogicvector (" & Pfx & ")");
               Wr_Line (";");
            else
               --  Any array.
               declare
                  Bnd : Bound_Type renames Typ.Abound;
                  El_Type : constant Node := Get_Element_Subtype (Ptype);
                  El_W : constant Width := Get_Type_Width (Typ.Arr_El);
                  Idx : Int32;
               begin
                  for I in 0 .. Bnd.Len - 1 loop
                     case Bnd.Dir is
                        when Dir_To =>
                           Idx := Bnd.Left + Int32 (I);
                        when Dir_Downto =>
                           Idx := Bnd.Left - Int32 (I);
                     end case;
                     Disp_In_Converter
                       (Mname,
                        Pfx & " (" & Int32'Image (Idx) & ")",
                        Off + I * El_W, El_Type, Typ.Arr_El, False);
                  end loop;
               end;
            end if;
         when Iir_Kind_Record_Type_Definition =>
            declare
               Els : constant Node_Flist :=
                 Get_Elements_Declaration_List (Ptype);
               Rec_Full : constant Boolean := Full and Typ.W = 1;
            begin
               for I in Flist_First .. Flist_Last (Els) loop
                  declare
                     El : constant Node := Get_Nth_Element (Els, I);
                     Et : Rec_El_Type renames
                       Typ.Rec.E (Iir_Index32 (I + 1));
                  begin
                     Disp_In_Converter
                       (Mname,
                        Pfx & '.' & Name_Table.Image (Get_Identifier (El)),
                        Off + Et.Offs.Net_Off,
                        Get_Type (El), Et.Typ, Rec_Full);
                  end;
               end loop;
            end;
         when others =>
            Error_Kind ("disp_in_converter", Ptype);
      end case;
   end Disp_In_Converter;

   --  Disp conversion for output port (so in the form wrap_i <= i).
   procedure Disp_Input_Port_Converter (Inst : Synth_Instance_Acc;
                                        Port : Node)
   is
      Port_Name : constant String :=
        Name_Table.Image (Get_Identifier (Port));
      Port_Type : constant Node := Get_Type (Port);
      Typ : constant Type_Acc := Get_Subtype_Object (Inst, Port_Type);
   begin
      if Get_Kind (Get_Base_Type (Port_Type)) = Iir_Kind_Record_Type_Definition
      then
         --  Expand
         declare
            Els : constant Node_Flist :=
              Get_Elements_Declaration_List (Port_Type);
         begin
            for I in Flist_First .. Flist_Last (Els) loop
               declare
                  El : constant Node := Get_Nth_Element (Els, I);
                  El_Name : constant String :=
                    Name_Table.Image (Get_Identifier (El));
                  Et : Rec_El_Type renames
                    Typ.Rec.E (Iir_Index32 (I + 1));
               begin
                  Disp_In_Converter
                    (Port_Name & '_' & El_Name, Port_Name & '.' & El_Name,
                     0, Get_Type (El), Et.Typ, True);
               end;
            end loop;
         end;
      else
         Disp_In_Converter (Port_Name, Port_Name, 0, Port_Type, Typ, True);
      end if;
   end Disp_Input_Port_Converter;

   procedure Disp_Out_Rhs
     (Mname : String; Off : Uns32; W : Width; Full : Boolean) is
   begin
      Wr ("wrap_" & Mname);
      Disp_Pfx (Off, W, Full);
   end Disp_Out_Rhs;

   --  PTYPE is the type of the original port, while TYP is the type of
   --  the netlist port.
   procedure Disp_Out_Converter (Mname : String;
                                 Pfx : String;
                                 Off : Uns32;
                                 Ptype : Node;
                                 Typ : Type_Acc;
                                 Full : Boolean)
   is
      Btype : constant Node := Get_Base_Type (Ptype);
      W : Width;
   begin
      case Get_Kind (Btype) is
         when Iir_Kind_Enumeration_Type_Definition =>
            Wr ("  " & Pfx & " <= ");
            if Btype = Vhdl.Ieee.Std_Logic_1164.Std_Ulogic_Type then
               --  Nothing to do.
               Disp_Out_Rhs (Mname, Off, 1, Full);
               Wr_Line (";");
            elsif Btype = Vhdl.Std_Package.Boolean_Type_Definition then
               Disp_Out_Rhs (Mname, Off, 1, Full);
               Wr_Line (" = '1';");
            elsif Btype = Vhdl.Std_Package.Bit_Type_Definition then
               Wr ("to_bit (");
               Disp_Out_Rhs (Mname, Off, 1, Full);
               Wr_Line (");");
            else
               --  Any other enum.
               W := Typ.W;
               Wr (Name_Table.Image (Get_Identifier
                                        (Get_Type_Declarator (Ptype))));
               Wr ("'val (to_integer(unsigned");
               if W = 1 then
                  Wr ("'(0 => ");
               else
                  Wr ('(');
               end if;
               Disp_Out_Rhs (Mname, Off, W, Full);
               Wr_Line (")));");
            end if;
         when Iir_Kind_Integer_Type_Definition =>
            --  FIXME: signed or unsigned ?
            W := Typ.W;
            Wr ("  " & Pfx & " <= to_integer (");
            if Typ.Drange.Is_Signed then
               Wr ("signed");
            else
               Wr ("unsigned");
            end if;
            if W = 1 then
               Wr ("'(0 => ");
            else
               Wr (" (");
            end if;
            Disp_Out_Rhs (Mname, Off, W, Full);
            Wr_Line ("));");
         when Iir_Kind_Array_Type_Definition =>
            if Btype = Vhdl.Ieee.Std_Logic_1164.Std_Logic_Vector_Type then
               --  Nothing to do.
               W := Typ.Abound.Len;
               Wr ("  " & Pfx);
               if W = 1 then
                  Wr (" (" & Pfx & "'left)");
               end if;
               Wr (" <= ");
               Disp_Out_Rhs (Mname, Off, W, Full);
               Wr_Line (";");
            elsif Btype = Vhdl.Std_Package.Bit_Vector_Type_Definition then
               --  Nothing to do.
               W := Typ.Abound.Len;
               Wr ("  " & Pfx & " <= ");
               if W = 1 then
                  --  This is an array of length 1.  A scalar is used in the
                  --  netlist.
                  Wr ("(0 => to_bit (");
               else
                  Wr ("to_bitvector (");
               end if;
               Disp_Out_Rhs (Mname, Off, W, Full);
               if W = 1 then
                  Wr (')');
               end if;
               Wr_Line (");");
            elsif Is_Std_Logic_Array (Btype) then
               --  unsigned, signed or a compatible array.
               W := Typ.Abound.Len;
               Wr ("  " & Pfx);
               if W = 1 then
                  Wr ("(" & Pfx & "'left) <= ");
                  Disp_Out_Rhs (Mname, Off, W, Full);
                  Wr_Line (";");
               else
                  Wr (" <= ");
                  --  First the first non-anonymous parent type of the prefix.
                  --  We could directly use the base type, but:
                  --  * it is less intuitive
                  --  * vhdl2008 base type of 'unsigned' is
                  --    'unresolved_unsigned', which is barely used and not
                  --    defined in vhdl93
                  declare
                     Pfx_Type : Node;
                     Type_Decl : Node;
                  begin
                     Pfx_Type := Ptype;
                     loop
                        Type_Decl := Get_Type_Declarator (Pfx_Type);
                        exit when Type_Decl /= Null_Node;
                        Pfx_Type := Get_Parent_Type (Pfx_Type);
                     end loop;
                     Wr (Name_Table.Image (Get_Identifier (Type_Decl)));
                  end;
                  Wr ("(");
                  Disp_Out_Rhs (Mname, Off, W, Full);
                  Wr_Line (");");
               end if;
            else
               declare
                  Bnd : Bound_Type renames Typ.Abound;
                  El_Type : constant Node := Get_Element_Subtype (Ptype);
                  El_W : constant Width := Get_Type_Width (Typ.Arr_El);
                  Idx : Int32;
               begin
                  for I in 0 .. Bnd.Len - 1 loop
                     case Bnd.Dir is
                        when Dir_To =>
                           Idx := Bnd.Left + Int32 (I);
                        when Dir_Downto =>
                           Idx := Bnd.Left - Int32 (I);
                     end case;
                     Disp_Out_Converter
                       (Mname,
                        Pfx & " (" & Int32'Image (Idx) & ")",
                        Off + I * El_W, El_Type, Typ.Arr_El, False);
                  end loop;
               end;
            end if;
         when Iir_Kind_Record_Type_Definition =>
            declare
               Els : constant Node_Flist :=
                 Get_Elements_Declaration_List (Ptype);
               Rec_Full : constant Boolean := Full and Typ.W = 1;
            begin
               for I in Flist_First .. Flist_Last (Els) loop
                  declare
                     El : constant Node := Get_Nth_Element (Els, I);
                     Et : Rec_El_Type renames
                       Typ.Rec.E (Iir_Index32 (I + 1));
                  begin
                     Disp_Out_Converter
                       (Mname,
                        Pfx & '.' & Name_Table.Image (Get_Identifier (El)),
                        Off + Et.Offs.Net_Off,
                        Get_Type (El), Et.Typ, Rec_Full);
                  end;
               end loop;
            end;
         when others =>
            Error_Kind ("disp_out_converter", Ptype);
      end case;
   end Disp_Out_Converter;

   --  Disp conversion for output port (so in the form o <= wrap_o).
   procedure Disp_Output_Port_Converter (Inst : Synth_Instance_Acc;
                                         Port : Node)
   is
      Port_Name : constant String :=
        Name_Table.Image (Get_Identifier (Port));
      Port_Type : constant Node := Get_Type (Port);
      Typ : constant Type_Acc := Get_Subtype_Object (Inst, Port_Type);
   begin
      if Get_Kind (Get_Base_Type (Port_Type)) = Iir_Kind_Record_Type_Definition
      then
         --  Expand
         declare
            Els : constant Node_Flist :=
              Get_Elements_Declaration_List (Port_Type);
         begin
            for I in Flist_First .. Flist_Last (Els) loop
               declare
                  El : constant Node := Get_Nth_Element (Els, I);
                  El_Name : constant String :=
                    Name_Table.Image (Get_Identifier (El));
                  Et : Rec_El_Type renames
                    Typ.Rec.E (Iir_Index32 (I + 1));
               begin
                  Disp_Out_Converter
                    (Port_Name & '_' & El_Name, Port_Name & '.' & El_Name,
                     0, Get_Type (El), Et.Typ, True);
               end;
            end loop;
         end;
      else
         Disp_Out_Converter (Port_Name, Port_Name, 0, Port_Type, Typ, True);
      end if;
   end Disp_Output_Port_Converter;

   function Has_Floating_Type (Atype : Node) return Boolean is
   begin
      case Get_Kind (Atype) is
         when Iir_Kind_Floating_Subtype_Definition =>
            return True;
         when others =>
            return False;
      end case;
   end Has_Floating_Type;

   procedure Disp_Vhdl_Wrapper
     (Ent : Node; Top : Module; Inst : Synth_Instance_Acc)
   is
      Unit : constant Node := Get_Design_Unit (Ent);
      Main : Module;
      Inter : Node;
   begin
      --  Extract the first user submodule.
      Main := Get_First_Sub_Module (Top);
      while Get_Id (Main) < Id_User_None loop
         Main := Get_Next_Sub_Module (Main);
      end loop;

      --  Ports with a floating point type are not supported.
      Inter := Get_Port_Chain (Ent);
      while Inter /= Null_Node loop
         if Has_Floating_Type (Get_Type (Inter)) then
            Error_Msg_Elab
              (Inter, "cannot output vhdl: %n has a floating point type",
               (1 => +Inter));
            return;
         end if;

         Inter := Get_Chain (Inter);
      end loop;

      --  Disp the original design unit.
      Vhdl.Prints.Disp_Vhdl (Unit);

      --  Disp sub-units (in reverse order).
      declare
         M : Module;
         Num : Natural;
      begin
         --  Count number of modules.
         Num := 0;
         M := Get_Next_Sub_Module (Main);
         while M /= No_Module loop
            if Get_Id (M) >= Id_User_None then
               Num := Num + 1;
            end if;
            M := Get_Next_Sub_Module (M);
         end loop;

         --  Fill array of modules, display.
         declare
            type Module_Array is array (1 .. Num) of Module;
            Modules : Module_Array;
         begin
            Num := 0;
            M := Get_Next_Sub_Module (Main);
            while M /= No_Module loop
               if Get_Id (M) >= Id_User_None then
                  Num := Num + 1;
                  Modules (Num) := M;
               end if;
               M := Get_Next_Sub_Module (M);
            end loop;

            for I in reverse Modules'Range loop
               --  Skip blackboxes.
               if Get_Self_Instance (Modules (I)) /= No_Instance then
                  Netlists.Disp_Vhdl.Disp_Vhdl (Modules (I), False);
               end if;
            end loop;
         end;
      end;
      Wr_Line;

      --  Rename ports.
      declare
         Name_Wrap : Name_Id;
         Pfx_Wrap : Sname;
         Pfx : Sname;
      begin
         Name_Wrap := Name_Table.Get_Identifier ("wrap");
         Pfx_Wrap := New_Sname_User (Name_Wrap, No_Sname);
         for P of Ports_Desc (Main) loop
            --  INOUT ports are handled specially.
            if P.Dir /= Port_Inout then
               Pfx := Get_Sname_Prefix (P.Name);
               if Pfx = No_Sname then
                  --  Normal port, without a prefix.
                  Set_Sname_Prefix (P.Name, Pfx_Wrap);
               elsif Get_Sname_Prefix (Pfx) = No_Sname then
                  --  Prefixed port (for an expanded record).
                  --  Add a prefix but once (prefix is shared).
                  Set_Sname_Prefix (Pfx, Pfx_Wrap);
               end if;
            end if;
         end loop;
      end;

      Wr_Line ("library ieee;");
      Wr_Line ("use ieee.std_logic_1164.all;");
      Wr_Line ("use ieee.numeric_std.all;");
      Wr_Line;
      Wr ("architecture rtl of ");
      Wr (Name_Table.Image (Get_Identifier (Ent)));
      Wr_Line (" is");
      Disp_Ports_As_Signals (Main);
      Disp_Architecture_Declarations (Main);

      Wr_Line ("begin");
      if Inst /= null then
         --  TODO: add assert for the value of the generics.
         null;
      end if;

      declare
         Port : Node;
      begin
         Port := Get_Port_Chain (Ent);
         while Port /= Null_Node loop
            if Get_Mode (Port) = Iir_In_Mode then
               Disp_Input_Port_Converter (Inst, Port);
            end if;
            Port := Get_Chain (Port);
         end loop;

         Port := Get_Port_Chain (Ent);
         while Port /= Null_Node loop
            if Get_Mode (Port) = Iir_Out_Mode then
               Disp_Output_Port_Converter (Inst, Port);
            end if;
            Port := Get_Chain (Port);
         end loop;
      end;

      Disp_Architecture_Statements (Main);
      Wr_Line ("end rtl;");
   end Disp_Vhdl_Wrapper;
end Synth.Disp_Vhdl;
