with Ada.Text_IO;
with Timer_Tree;

package body Timed_Handlers is



   protected P is
      entry Get (T: out Ada.Calendar.Time; H : out Timed_Handler_A);
      procedure Put (T:Ada.Calendar.Time; H : Timed_Handler_A);
      procedure Delete (T:Ada.Calendar.Time);
      entry Finalize;
      procedure Do_Finalize;
   private
      New_Timer : Boolean := False;
      Must_finalize : Boolean := False;
   end P;

   protected body P is
      entry Get (T: out Ada.Calendar.Time;
                 H : out Timed_Handler_A)  when New_Timer is
         Success : Boolean := False;
      begin
         T := Timer_Tree.Min;
         Timer_Tree.Get (T, H, Success);
         New_Timer := False;
      end Get;

      procedure Delete (T:Ada.Calendar.Time) is
      begin
         Timer_Tree.Delete (T);
         if not Timer_Tree.Is_Empty then
            New_Timer := True;
         end if;
      end Delete;

      procedure Put (T:Ada.Calendar.Time; H : Timed_Handler_A) is
      begin
         Timer_Tree.Put (T,H);
         New_Timer := True;
      end Put;

      entry Finalize when Must_Finalize is
      begin
         null;
      end Finalize;

      procedure Do_Finalize is
      begin
         Must_finalize := True;
      end Do_Finalize;

   end P;


   task type Timed_Handlers_Task_T;

   task body Timed_Handlers_Task_T is
      The_Time : Ada.Calendar.Time;
      The_Handler : Timed_Handler_A;
      Programmed : Boolean;
      Finalize : Boolean;

      use type Ada.Calendar.Time;


      T : Ada.Calendar.Time;
      H : Timed_Handler_A;

   begin

      finalize := False;
      Programmed := False;
      -- Wait until we're reprogrammed or killed
      select
         P.Get (The_Time, The_Handler);
         Programmed := True;
      then Abort
         P.finalize;
      end select;

      while not Finalize loop
         while Programmed loop
            select
               P.Get (t, h);
               -- We are programmed, so we're waiting in the other arm of
               -- this select, thus only change the timeout if it's smaller
               -- ignore it otherwise
               if T < The_Time then
                  Programmed := True;
                  The_Time := T;
                  The_Handler := H;
               end if;
            or
               delay The_Time - Ada.Calendar.Clock;
               The_Handler.all (The_Time);
               P.Delete (The_Time);
               Programmed := False;
            end select;
         end loop;


         select
            P.Finalize;
            Finalize := True;
         or delay 0.0;
         end select;

         -- We are not programmed,
         -- Wait until we're reprogrammed or killed
         select
            P.Get (The_Time, The_Handler);
            Programmed := True;
         then abort
            P.Finalize;
            Finalize := True;
         end select;
      end loop;

   end Timed_Handlers_Task_T;


   Timed_Handler_Task : Timed_Handlers_Task_T;


   procedure Set_Timed_Handler (T : Ada.Calendar.Time; H : Timed_Handler_A) is
   begin
      P.Put (T, H);
   end Set_Timed_Handler;

   procedure Finalize is begin
      P.Do_Finalize;
   end Finalize;


end Timed_Handlers;

