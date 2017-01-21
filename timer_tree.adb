with Ada.Unchecked_Deallocation;
with Ada.Text_IO;
with Ada.Strings.Unbounded.Text_IO;

package body Timer_Tree is
   package ASUIO renames Ada.Strings.Unbounded.Text_IO;

   use type Asu.Unbounded_String;
   use type Ada.Calendar.Time;

   type Tree;
   type Tree_A is access Tree;
   type Tree is record
      Key   : Ada.Calendar.Time;
      Value : Timed_Handlers.Timed_Handler_A;
      Left  : Tree_A;
      Right : Tree_A;
   end record;
   P_Root : Tree_A;


   procedure Get (P_Tree  : Tree_A;
                  Key     : in  Ada.Calendar.Time;
                  Value   : out Timed_Handlers.Timed_Handler_A;
                  Success : out Boolean) is
   begin
      Value := null;

      if P_Tree = null then
         Success := False;
      elsif P_Tree.Key = Key then
         Value := P_Tree.Value;
         Success := True;
      elsif Key > P_Tree.Key then
         Get (P_Tree.Right, Key, Value, Success);
      else
         Get (P_Tree.Left, Key, Value, Success);
      end if;
   end Get;


   procedure Get (Key     : in  Ada.Calendar.Time;
                  Value   : out Timed_Handlers.Timed_Handler_A;
                  Success : out Boolean) is
   begin
      Get (P_Root, Key, Value, Success);
   end Get;


   function Put (P_Tree : in Tree_A;
                 Key    : Ada.Calendar.Time;
                 Value  : Timed_Handlers.Timed_Handler_A)
                return Tree_A is
   begin

      if P_Tree = null then
         return new Tree'(Key, Value, null, null);
      end if;

      if Key = P_Tree.Key then
         P_Tree.Value := Value;
      elsif Key < P_Tree.Key then
         P_Tree.Left := Put (P_Tree.Left, Key, Value);
      elsif Key > P_Tree.Key then
         P_Tree.Right := Put (P_Tree.Right, Key, Value);
      end if;

      return P_Tree;
   end Put;


   procedure Put (Key   : Ada.Calendar.Time;
                  Value : Timed_Handlers.Timed_Handler_A) is
   begin
      P_Root := Put (P_Root, Key, Value);
   end Put;


   function Min (P_Tree : Tree_A) return Tree_A is
   begin
      if P_Tree = null then
        return null;
      end if;

      if P_Tree.Left = null then
         return P_Tree;
      else
         return Min (P_Tree.Left);
      end if;

   end Min;


   function Is_Empty return Boolean is
   begin
      return P_Root = null;
   end Is_Empty;

   function Min return Ada.Calendar.Time is
   begin
      return Min (P_Root).key;
   end;

   procedure Free is new Ada.Unchecked_Deallocation (Tree, Tree_A);

   function Delete_Min (P_Tree : Tree_A)  return Tree_A  is
      P_Aux: Tree_A;
      P : Tree_A;
   begin

      P_Aux := P_Tree;

      if P_Aux = null then
         return null;
      end if;

      if P_Aux.Left = null then
         P := P_Aux.Right;
         Free (P_Aux); -- Hay que liberar memoria si no hay GC
         return P;
      else
         P_Aux.Left := Delete_Min (P_Aux.Left);
         return P_Aux;
      end if;

   end Delete_Min;



   function Delete (P_Tree : Tree_A;
                    Key : Ada.Calendar.Time) return Tree_A is
      Min : Tree_A;
      P_Aux : Tree_A;
      P_Free : Tree_A;
   begin

      if P_Tree = null then
         return null;
      end if;

      if Key < P_Tree.Key and then P_Tree.Left /= null Then
         P_Tree.left := Delete (P_Tree.Left, Key);
         return P_Tree;
      end if;

      if Key > P_Tree.Key and then P_Tree.Right /= null then
         P_Tree.Right :=  Delete (P_Tree.Right, Key);
         return P_Tree;
      end if;


      if P_Tree.Key = Key then
         if P_Tree.Left = null then
            P_Aux := P_Tree.Right;
            P_Free := P_Tree; -- Si no hay GC, liberar P_Free
            Free(P_Free);
            return P_Aux;
         elsif P_Tree.Right = null then
            P_Aux := P_Tree.Left;
            P_Free := P_Tree; -- Si no hay GC, liberar P_Free
            Free (P_Free);
            return P_Aux;
         else
            Min := Timer_Tree.Min (P_Tree.Right);
            if Min /= null then
               P_Tree.Key := Min.key;
               P_Tree.Value := Min.Value;
            end if;
            P_Tree.Right := Delete_Min (P_Tree.Right);
            return P_Tree;
         end if;
      end if;

      return P_Tree;

   end Delete;


   procedure Delete (Key : Ada.Calendar.Time) is
   begin
      if P_Root /= null then
         P_Root := Delete (P_Root, Key);
      end if;
   end Delete;


   function Tree_Size (P_Tree : Tree_A) return Natural is
   begin
      if P_Tree /= null then
         return 1 + Tree_Size (P_Tree.Left) + Tree_Size (P_Tree.Right);
      else
         return 0;
      end if;
   end Tree_Size;



   function Tree_Size return Natural is
   begin
      return Tree_Size (P_Root);
   end Tree_Size;


   procedure Print_Tree (P_Tree : Tree_A) is
   begin
      if P_Tree /= null then
         if P_Tree.Left /= null then
            Print_Tree (P_Tree.Left);
         end if;

         Ada.Text_io.Put_Line (Ada.Calendar.Seconds(P_Tree.Key)'Img);


         if P_Tree.Right /= null then
            Print_Tree (P_Tree.Right);
         end if;
      end if;
   end Print_Tree;

   procedure Print_Tree is
   begin
      Ada.Text_Io.Put_Line ("The Symbol Table");
      Ada.Text_Io.Put_Line ("================");

      Print_Tree (P_Root);
   end Print_Tree;



end Timer_Tree;
