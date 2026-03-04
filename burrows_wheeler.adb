-- ***************************************************************************
--                 Burrows-Wheeler Transform
--
--           Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************
with Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

procedure Burrows_Wheeler_Sentinel is

   Sentinel : constant Character := '$';

   package String_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Unbounded_String);
   use String_Vectors;

   ------------------------------------------------------------
   -- Rotate a string by K positions
   ------------------------------------------------------------
   function Rotate (S : String; K : Natural) return String is
      Result : String (S'Range);
      Len    : constant Natural := S'Length;
   begin
      for I in S'Range loop
         Result (I) :=
           S (((I - S'First + K) mod Len) + S'First);
      end loop;
      return Result;
   end Rotate;

   ------------------------------------------------------------
   -- Lexicographic comparison
   ------------------------------------------------------------
   function Less_Than (L, R : Unbounded_String) return Boolean is
   begin
      return To_String (L) < To_String (R);
   end Less_Than;

   ------------------------------------------------------------
   -- Simple bubble sort (clarity over speed)
   ------------------------------------------------------------
   procedure Sort (V : in out Vector) is
      Swapped : Boolean;
      Temp    : Unbounded_String;
   begin
      loop
         Swapped := False;
         for I in 0 .. Integer (V.Length) - 2 loop
            if not Less_Than (V (I), V (I + 1)) then
               Temp := V (I);
               V.Replace_Element (I, V (I + 1));
               V.Replace_Element (I + 1, Temp);
               Swapped := True;
            end if;
         end loop;
         exit when not Swapped;
      end loop;
   end Sort;

   ------------------------------------------------------------
   -- Sentinel-based BWT Transform
   ------------------------------------------------------------
   function BWT_Transform (Input : String) return String is
      S          : constant String := Input & Sentinel;
      N          : constant Natural := S'Length;
      Rotations  : Vector;
      Result     : String (1 .. N);
   begin
      -- Generate all rotations
      for I in 0 .. N - 1 loop
         Rotations.Append (To_Unbounded_String (Rotate (S, I)));
      end loop;

      -- Sort rotations
      Sort (Rotations);

      -- Take last column
      for I in 0 .. N - 1 loop
         declare
            R : constant String := To_String (Rotations (I));
         begin
            Result (I + 1) := R (R'Last);
         end;
      end loop;

      return Result;
   end BWT_Transform;

   ------------------------------------------------------------
   -- Sentinel-based Inverse BWT
   ------------------------------------------------------------
   function BWT_Inverse (Encoded : String) return String is
      N : constant Natural := Encoded'Length;

      type Char_Array is array (Natural range <>) of Character;
      type Index_Array is array (Natural range <>) of Natural;

      Last  : Char_Array (0 .. N - 1);
      First : Char_Array (0 .. N - 1);
      Next  : Index_Array (0 .. N - 1);

      Result : Unbounded_String := To_Unbounded_String ("");
      Curr   : Natural;
   begin
      -- Fill last column
      for I in Encoded'Range loop
         Last (I - Encoded'First) := Encoded (I);
      end loop;

      -- First column = sorted last column
      First := Last;
      for I in 0 .. N - 2 loop
         for J in I + 1 .. N - 1 loop
            if First (I) > First (J) then
               declare
                  T : constant Character := First (I);
               begin
                  First (I) := First (J);
                  First (J) := T;
               end;
            end if;
         end loop;
      end loop;

      -- Build LF-mapping
      for I in 0 .. N - 1 loop
         declare
            C : constant Character := First (I);
            Count_First : Natural := 0;
            Count_Last  : Natural := 0;
         begin
            for J in 0 .. I - 1 loop
               if First (J) = C then
                  Count_First := Count_First + 1;
               end if;
            end loop;

            for J in 0 .. N - 1 loop
               if Last (J) = C then
                  if Count_Last = Count_First then
                     Next (I) := J;
                     exit;
                  end if;
                  Count_Last := Count_Last + 1;
               end if;
            end loop;
         end;
      end loop;

      -- Start from row containing sentinel
      for I in 0 .. N - 1 loop
         if First (I) = Sentinel then
            Curr := I;
            exit;
         end if;
      end loop;

      -- Reconstruct until sentinel encountered
      loop
         Curr := Next (Curr);
         exit when First (Curr) = Sentinel;
         Append (Result, First (Curr));
      end loop;

      return To_String (Result);
   end BWT_Inverse;

   ------------------------------------------------------------
   -- Test
   ------------------------------------------------------------
   procedure Test (S : String) is
      Encoded : constant String := BWT_Transform (S);
      Decoded : constant String := BWT_Inverse (Encoded);
   begin
      Ada.Text_IO.Put_Line ("Original: " & S);
      Ada.Text_IO.Put_Line ("Encoded:  " & Encoded);
      Ada.Text_IO.Put_Line ("Decoded:  " & Decoded);

      if Decoded = S then
         Ada.Text_IO.Put_Line ("Result:   ✓ PASS");
      else
         Ada.Text_IO.Put_Line ("Result:   ✗ FAIL");
      end if;

      Ada.Text_IO.Put_Line ("--------------------------------");
   end Test;

begin
   Test ("BANANA");
   Test ("HELLO");
   Test ("RACECAR");
   Test ("AABBCC");
   Test ("THE QUICK BROWN FOX");
end Burrows_Wheeler_Sentinel;
