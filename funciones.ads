-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Lower_Layer_UDP;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with chatmessages;
with Ada.Strings.Unbounded;


package funciones is

package LLU renames Lower_Layer_UDP;
package ASU renames Ada.Strings.Unbounded;
use type chatmessages.Seq_N_T;


type Mess_Id_T is record
	EP: LLU.End_Point_Type;
	Seq: chatmessages.Seq_N_T;
end record;

type Destination_T is record
	EP: LLU.End_Point_Type:= null;
	Retries: Natural:= 0;
end record;

type Destinations_T is array (1..10) of Destination_T;

type Value_T is record
	EP_H_Creat: LLU.End_Point_Type;
	Seq_N: chatmessages.Seq_N_T;
	P_Buffer: chatmessages.Buffer_A_T;
end record;

function Seq_a_String (Seq_N: chatmessages.Seq_N_T) return String;

function CalendarTime_a_String (Tiempo: Ada.Calendar.Time) return String;

function Mess_Id_T_a_String (Mess: Mess_Id_T) return String;

function Destinations_T_a_String (Destinations: Destinations_T) return String;

function Value_T_a_String (Value: Value_T) return String;

function "<" (Left, Right: Mess_Id_T) return Boolean;

function ">" (Left, Right: Mess_Id_T) return Boolean;

function "=" (Left, Right: Mess_Id_T) return Boolean;

end funciones;