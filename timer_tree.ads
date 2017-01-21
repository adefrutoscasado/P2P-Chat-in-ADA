with Timed_Handlers;

With Ada.Calendar;

With Ada.Strings.Unbounded;



package Timer_Tree is
   package ASU renames Ada.Strings.Unbounded;


   procedure Get (Key     : in  Ada.Calendar.Time;
                  Value   : out Timed_Handlers.Timed_Handler_A;
                  Success : out Boolean);


   procedure Put (Key   : Ada.Calendar.Time;
                  Value : Timed_Handlers.Timed_Handler_A);

   procedure Delete (Key : Ada.Calendar.Time);


   function Min return Ada.Calendar.Time;

   function Is_Empty return Boolean;

   function Tree_Size return Natural;

   procedure Print_Tree;


end Timer_Tree;
