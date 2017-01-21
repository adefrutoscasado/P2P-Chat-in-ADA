with Ada.Text_IO;

package body Debug is

   Do_Debug : Boolean := True;
   
   procedure Set_Status (Status: Boolean) is
   begin
      Do_Debug := Status;
   end Set_Status;
   
   
   function Get_Status return Boolean is
   begin
      return Do_Debug;
   end Get_Status;
   
   
   procedure Put_Line (Msg         : String;
		       Color_Msg   : Pantalla.T_Color := Pantalla.Verde) is
   begin
      if Do_Debug then
	 Pantalla.Poner_Color(Color_Msg);
	 Ada.Text_IO.Put_Line(Msg);
	 Pantalla.Poner_Color(Pantalla.Cierra);	 
      end if;
   end Put_Line;


   procedure Put (Msg         : String;
		  Color_Msg   : Pantalla.T_Color := Pantalla.Verde) is
   begin
      if Do_Debug then
	 Pantalla.Poner_Color(Color_Msg);
	 Ada.Text_IO.Put(Msg);
	 Pantalla.Poner_Color(Pantalla.Cierra);	 
      end if;
   end Put;

end Debug;
