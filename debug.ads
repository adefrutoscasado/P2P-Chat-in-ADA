with Pantalla;

package Debug is


   -- Activa los mensajes de depuración si Status es True, los desactiva si es False
   procedure Set_Status (Status: Boolean);

   -- Devuelve True si está activa la depuración
   function Get_Status return Boolean;

   -- Muestra por la salida estándar un mensaje de depuración terminado en fin de línea
   -- el mensaje se muestra en Color_Msg, y después se vuelve a color normal
   procedure Put_Line (Msg         : String;
                       Color_Msg   : Pantalla.T_Color := Pantalla.Verde);
   
   
   -- Muestra por la salida estándar un mensaje de depuración sin fin de línea
   -- el mensaje se muestra en Color_Msg, y después se vuelve a color normal
   procedure Put      (Msg         : String;
                       Color_Msg   : Pantalla.T_Color := Pantalla.Verde);


end Debug;
