with Ada.Calendar;


--------------------------------------------------------------------------------
--
-- Este paquete implementa timers para la ejecución retardada de subprogramas.
--
-- Se pueden instalar múltiples procedimientos, llamándose a cada uno de ellos
-- a la hora especificada.
--
--------------------------------------------------------------------------------

package Timed_Handlers is

   type Timed_Handler_A is access procedure (Time: in Ada.Calendar.Time);

   ----------------------------------------------------------------------------
   -- Permite instalar un procedimiento manejador, especificado en el
   -- parámetro H, que se ejecutar a la hora especificada por el parámetro T
   --
   procedure Set_Timed_Handler (T : Ada.Calendar.Time; H : Timed_Handler_A);

   ----------------------------------------------------------------------------
   -- Desactiva el subsistema de Timers.
   -- Hay que llamar a Finalize cuando no se van a usar más los timers,
   -- normalmente justo antes de finalizar el programa.
   --
   procedure Finalize;

end Timed_Handlers;
