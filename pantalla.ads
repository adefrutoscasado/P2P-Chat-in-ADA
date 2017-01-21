-----------------------------------------------------------------------------
--
--                             P a n t a l l a
--
--                                  Spec v 1.0
--
--  Contiene procedimientos para controlar terminales ANSI.
--  Autor: Daniel Alcantara de la Hoz
------------------------------------------------------------------------------

package Pantalla is

   subtype T_Fila    is Positive range 1 .. 80;
   subtype T_Columna is Positive range 1 .. 200;

   type T_Color is (Verde, Rojo, Amarillo, Azul, Magenta, Azul_Claro,
                    Blanco, Normal, Gris_Oscuro, Cierra);
   type T_Color_Fondo is (Rojo, Verde, Azul, Naranja, Magenta, Azul_Claro,
                    Gris, Normal);
   type T_Atributo is (Normal, Inverso, Parpadeo);

   -----------------------------------
   -- Cambio de atributos y colores --
   -----------------------------------

   procedure Poner_Atributo    (Atributo    : in T_Atributo);
   procedure Poner_Color       (Color       : in T_Color);
   procedure Poner_Color_Fondo (Color_Fondo : in T_Color_Fondo);

   --------------------------
   -- Movimiento de cursor --
   --------------------------

   procedure Borrar;
   procedure Mover_Cursor (Fila : in T_Fila; Columna : T_Columna);

   Posicion_Incorrecta : exception;

end Pantalla;



