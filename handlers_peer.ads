-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Lower_Layer_UDP;
with funciones;
with Maps_G;
with Maps_Protector_G;
with Ada.Calendar;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with chatmessages;
with Debug;
with Timed_handlers;

with ordered_maps_g;
with Ordered_Maps_Protector_G;

package Handlers_peer is

	package LLU renames Lower_Layer_UDP;

	package ASU renames Ada.Strings.Unbounded;

	use type LLU.End_Point_Type;
	use type chatmessages.Seq_N_T;

	package NP_Neighbors is new Maps_G (Lower_Layer_UDP.End_Point_Type,
												Ada.Calendar.Time,
												Lower_Layer_UDP.Build("0.0.0.0",0),
												Ada.Calendar.Time_Of(1979,1,1,0.0),
												10,
												LLU."=",
												LLU.Image,
												funciones.CalendarTime_a_String);
												
	package NP_Latest_Msgs is new Maps_G (Lower_Layer_UDP.End_Point_Type,
												chatmessages.Seq_N_T,
												Lower_Layer_UDP.Build("0.0.0.0",0),
												0,
												50,
												LLU."=",
												LLU.Image,
												funciones.Seq_a_string);
												
	
	package Neighbors is new Maps_Protector_G (NP_Neighbors);
	package Latest_Msgs is new Maps_Protector_G (NP_Latest_Msgs);


	Mapa_vecinos: Neighbors.Prot_Map;
	Mapa_mensajes: Latest_Msgs.Prot_Map;
	
	
	package NP_Sender_Dests is new ordered_maps_g (funciones.Mess_Id_T,
												funciones.Destinations_T,
												funciones."=",
												funciones."<",
												funciones.">",
												funciones.Mess_Id_T_a_String,
												funciones.Destinations_T_a_String);
												
	package NP_Sender_buffering is new ordered_maps_g (Ada.Calendar.Time,
												funciones.Value_T,
												Ada.Calendar."=",
												Ada.Calendar."<",
												Ada.Calendar.">",
												funciones.CalendarTime_a_String,
												funciones.Value_T_a_String);
												
	
	package Sender_Dests is new Ordered_Maps_Protector_G (NP_Sender_Dests);
	package Sender_Buffering is new Ordered_Maps_Protector_G (NP_Sender_buffering);


	Mapa_Sender_Buffering: Sender_buffering.Prot_Map;
	Mapa_Sender_Dests: Sender_Dests.Prot_Map;
	

	procedure Peer_Handler (From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; Buffer: access LLU.Buffer_Type);

	procedure Enviar_Init (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_R_Creat: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; EP_H_Rsnd: in LLU.End_Point_Type);

	procedure Enviar_Confirm (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String);

	procedure Enviar_Writer (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; Text: in ASU.Unbounded_String);

	procedure Enviar_Logout (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; Confirm_Sent: in Boolean);

	procedure Terminar_Timed_Handlers;
	
end Handlers_peer;
