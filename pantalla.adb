-----------------------------------------------------------------------------
--
--                             P a n t a l l a
--
--                                  Body v1.0
--
--  Contiene procedimientos para controlar terminales ANSI.
--  Autor: Daniel Alcantara de la Hoz
------------------------------------------------------------------------------

with Text_IO;
package body Pantalla is

   package Int_IO is new Text_IO.Integer_IO (Num => Integer);

   ------------
   -- Borrar --
   ------------

   procedure Borrar is
   begin
      Text_IO.Put (Item => Ascii.Esc);
      Text_IO.Put (Item => "[2J");
      Poner_Atributo (Normal);
      Mover_Cursor (1, 1);
   end Borrar;

   ------------------
   -- Mover_Cursor --
   ------------------

   procedure Mover_Cursor (Fila : in T_Fila; Columna : T_Columna) is
   begin
      Text_IO.Put (Item => Ascii.Esc);
      Text_IO.Put ("[");
      Int_IO.Put (Item => Fila, Width => 1);
      Text_IO.Put (Item => ';');
      Int_IO.Put (Item => Columna, Width => 1);
      Text_IO.Put (Item => 'f');
   end Mover_Cursor;

   --------------------
   -- Poner_Atributo --
   --------------------

   procedure Poner_Atributo (Atributo : T_Atributo) is
   begin
      Text_IO.Put (Ascii.Esc);
      case Atributo is
         when Normal   => Text_IO.Put ("[0m");
         when Inverso  => Text_IO.Put ("[7m");
         when Parpadeo => Text_IO.Put ("[5m");
      end case;
   end Poner_Atributo;

   -----------------
   -- Poner_Color --
   -----------------

   procedure Poner_Color (Color : T_Color) is
      Escape1 : constant Character := Character'Val (27);
   begin
      case Color is
         when Rojo =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;31m");
         when Verde =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;32m");
         when Amarillo =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;33m");
         when Azul =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;34m");
         when Magenta =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;35m");
         when Azul_Claro =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;36m");
         when Blanco =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;37m");
         when Normal =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;38m");
         when Gris_Oscuro =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;30m");
         when Cierra =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[0m");
      end case;
   end Poner_Color;

   -----------------------
   -- Poner_Color_Fondo --
   -----------------------

   procedure Poner_Color_Fondo (Color_Fondo : T_Color_Fondo) is
      Escape1 : constant Character := Character'Val (27);
   begin
      case Color_Fondo is
         when Rojo =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;41m");
         when Verde =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;42m");
         when Naranja =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;43m");
         when Azul =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;44m");
         when Magenta =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;45m");
         when Azul_Claro =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;46m");
         when Gris =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;47m");
         when Normal =>
            Text_IO.Put (Escape1);
            Text_IO.Put ("[01;49m");
      end case;
   end Poner_Color_Fondo;

end Pantalla;
