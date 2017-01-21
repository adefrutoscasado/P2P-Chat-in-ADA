-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Command_Line;
with Ada.Calendar;

package ChatMessages is
	
	package LLU renames Lower_Layer_UDP;
	
	type Seq_N_T is mod Integer'Last;
	
	type Buffer_A_T is access LLU.Buffer_Type;
	
	use type Ada.Calendar.Time;
	
	Plazo_retransmision: Duration;
	
	P_Buffer_Main: Buffer_A_T;
	P_Buffer_Handler: Buffer_A_T;
	
	type Message_Type is (Init, Reject, Confirm, Writer, Logout, Ack);

end ChatMessages;
