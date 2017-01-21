-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Ada.Exceptions;
with chatmessages;
with Lower_Layer_UDP;
with Handlers_peer;
with Ada.Calendar;
with Debug;
with Pantalla;
with ada.Real_Time;

procedure peer_chat is

	package ATIO renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	package CM renames chatmessages;
	
	use type LLU.End_Point_Type;
	use type CM.Message_Type;
	use type Ada.Calendar.Time;
	use type chatmessages.Seq_N_T;
	
	EP_R: LLU.End_Point_Type;
	EP_H: LLU.End_Point_Type;
	Mi_Nombre_maquina: ASU.Unbounded_String;
	Mi_Puerto: Natural;
	Vecino_Puerto_1: Natural;
	Vecino_Host_1: ASU.Unbounded_String;
	Vecino_EP_1: LLU.End_Point_Type;
	Vecino_Puerto_2: Natural;
	Vecino_Host_2: ASU.Unbounded_String;
	Vecino_EP_2: LLU.End_Point_Type;
	Buffer_para_recibir: aliased LLU.Buffer_Type(1024);
	Expired: Boolean;
	Tipo_Mensaje: CM.Message_Type;
	Mi_Nick: ASU.Unbounded_String;
	Success: Boolean:= False;
	Usage_Error: Exception;
	Range_Error: Exception;
	Numero_Seq: chatmessages.Seq_N_T;
	Text: ASU.Unbounded_String;
	Salir_del_chat: Boolean:= False;
	Admitido: Boolean:= False;
	Debug_Activado:Boolean:=True;
	min_delay: Integer;
	max_delay: Integer;
	fault_pct: Integer;
	Max_delay_en_Time_Span: Ada.Real_Time.Time_Span;
	Max_delay_en_Duration: Duration;
	
begin
	
	if Ada.Command_Line.Argument_Count < 5 or Ada.Command_Line.Argument_Count = 6 or Ada.Command_Line.Argument_Count = 8 or Ada.Command_Line.Argument_Count > 9 then
	Raise usage_error;
	end if;
	
	min_delay:= Integer'Value (Ada.Command_Line.Argument(3));
	
	max_delay:= Integer'Value (Ada.Command_Line.Argument(4));
	
	--Pasamos max_delay de Integer a Duration
	Max_delay_en_Time_Span:= Ada.Real_Time.seconds(max_delay);
	
	Max_delay_en_Duration:= Ada.Real_Time.To_Duration(Max_delay_en_Time_Span);
	
	
	chatmessages.Plazo_retransmision:= 2 * Max_delay_en_Duration/ 1000;


	fault_pct:= Integer'Value (Ada.Command_Line.Argument(5));
	
	if min_delay < 0 or max_delay < 0 or fault_pct < 0 or fault_pct > 100 then
	Raise range_error;
	end if;
	
	Mi_Nombre_maquina := ASU.To_Unbounded_String (LLU.Get_Host_Name);

	Mi_Puerto:= Natural'Value (Ada.Command_Line.Argument(1));

	Mi_Nick:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));
	
	--Simulacion de perdida de paquetes
	LLU.Set_Faults_Percent (fault_pct);
	--Simulacion de retardos de propagacion
	LLU.Set_random_propagation_delay (min_delay, max_delay);
	
	--Nos atamos a un EP_R cualquiera
	LLU.Bind_Any (EP_R);

	--Construimos el EP_H (con el puerto ingresado en ada comand line)
	EP_H:= LLU.Build(ASU.To_String(ASU.To_Unbounded_String (LLU.To_IP(ASU.To_String(Mi_Nombre_maquina)))), Mi_Puerto);
	

	-- Nos atamos al EP_H
	LLU.Bind (EP_H, Handlers_peer.Peer_Handler'Access);
	-----------------------
	
	--Hay 1 vecino
	if Ada.Command_Line.Argument_Count >= 7 then
	
	Vecino_Host_1:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(6));
	
	Vecino_Puerto_1:= Natural'Value (Ada.Command_Line.Argument(7));
	
	Vecino_EP_1:= LLU.Build (ASU.To_String(ASU.To_Unbounded_String (LLU.To_IP(ASU.To_String(Vecino_Host_1)))),Vecino_Puerto_1); 
	
	--Guardamos el vecino 1
	Handlers_peer.Neighbors.Put (Handlers_peer.Mapa_Vecinos, Vecino_EP_1, Ada.Calendar.Clock, Success);
	
	--Hay 2 vecinos
	if Ada.Command_Line.Argument_Count = 9 then

	Vecino_Host_2:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(8));
	
	Vecino_Puerto_2:= Natural'Value (Ada.Command_Line.Argument(9));
	
	Vecino_EP_2:= LLU.Build (ASU.To_String(ASU.To_Unbounded_String (LLU.To_IP(ASU.To_String(Vecino_Host_2)))),Vecino_Puerto_2); 
	
	--Guardamos el vecino 2
	Handlers_peer.Neighbors.Put (Handlers_peer.Mapa_Vecinos, Vecino_EP_2, Ada.Calendar.Clock, Success);
	
	end if;
	
	end if;
	

	
	--Si tenemos vecinos hacemos protocolo de admision
	if Ada.Command_Line.Argument_Count >= 7 then
	LLU.Reset(Buffer_para_recibir);
	--Enviamos Init inicial
	handlers_peer.Enviar_Init (EP_H, 1, EP_H, EP_R, Mi_Nick, EP_H);
	--Guardamos nuestro propio Init por si nos vuelve a llegar
	handlers_peer.Latest_Msgs.Put (handlers_peer.Mapa_mensajes, EP_H, 1, Success);
	--Esperamos 2 segundos un posible rechazo Reject.
	LLU.Reset(Buffer_para_recibir);
	LLU.Receive (EP_R, Buffer_para_recibir'Access, 2.0, Expired);
		--Si no me llega un Reject en 2 seg, soy admitido.
		if Expired then
			Admitido:= True;
			--Enviamos Confirm tras haber sido admitidos
			handlers_peer.Enviar_Confirm (EP_H, 2, EP_H, EP_H, Mi_Nick);
			--Guardamos nuestro propio Confirm por si nos vuelve a llegar
			handlers_peer.Latest_Msgs.Put (handlers_peer.Mapa_mensajes, EP_H, 2, Success);
		else
			Tipo_Mensaje:= CM.Message_Type'Input (Buffer_para_recibir'Access);
			--Si nos llega un Reject salimos del chat. hemos sido rechazados
			if Tipo_Mensaje = CM.Reject then
			Ada.Text_IO.Put_Line ("Has sido rechazado, elige otro nick");
			--Enviamos logout para que puedan eliminarnos los demas nodos
			handlers_peer.Enviar_Logout (EP_H, 2, EP_H, EP_H, Mi_Nick, False);
			handlers_peer.Latest_Msgs.Put (handlers_peer.Mapa_mensajes, EP_H, 2, Success);
			end if;
		end if;
	else
	Debug.Put_Line ("NO hacemos protocolo de admisión pues no tenemos contactos iniciales...");
	end if;
		
		
		--Si hemos sido admitidos o no tenemos vecinos iniciales empezamos el chat
		if Admitido or Ada.Command_Line.Argument_Count = 5 then
		Ada.Text_IO.Put_Line ("Peer-Chat v2.0");
		Ada.Text_IO.Put_Line ("==============");
		Ada.Text_IO.New_Line;
		Ada.Text_IO.Put_Line ("Entramos en el chat con Nick: " & ASU.To_String(Mi_Nick));
		Ada.Text_IO.Put_Line (".h para help");
		if Ada.Command_Line.Argument_Count = 2 then
		Numero_Seq:= 0;
		else
		Numero_Seq:= 2;
		end if;
		While not Salir_del_chat loop
				Text := ASU.To_Unbounded_String(Ada.Text_IO.Get_Line);
				
				if ASU.To_String(Text) = ".salir" then
				Numero_Seq:= Numero_Seq + 1;
				Chatmessages.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				handlers_peer.Enviar_Logout (EP_H, Numero_Seq, EP_H, EP_H, Mi_Nick, True);
				Salir_del_chat:= TRUE;
				
				elsif ASU.To_String(Text) = ".lm" or ASU.To_String(Text) = ".latest_msgs" then
				pantalla.Poner_Color(pantalla.Rojo);
				handlers_peer.Latest_Msgs.Print_Map (Handlers_peer.Mapa_mensajes);
				pantalla.Poner_Color(pantalla.Cierra);
				
				elsif ASU.To_String(Text) = ".nb" or ASU.To_String(Text) = ".neighbors"  then
				pantalla.Poner_Color(pantalla.Rojo);
				handlers_peer.Neighbors.Print_Map (Handlers_peer.Mapa_vecinos);
				pantalla.Poner_Color(pantalla.Cierra);

				
				elsif ASU.To_String(Text) = ".wai" or ASU.To_String(Text) = ".whoami"  then
				pantalla.Poner_Color(pantalla.Rojo);
				Ada.Text_IO.Put_Line ("Nick: " & ASU.To_String(Mi_Nick));
				Ada.Text_IO.Put_Line ("EP_H: " & LLU.Image(EP_H));
				Ada.Text_IO.Put_Line ("EP_R: " & LLU.Image(EP_R));
				pantalla.Poner_Color(pantalla.Cierra);
				
				elsif ASU.To_String(Text) = ".debug" then
				--Si Debug esta activado lo desactivamos y si esta desactivado lo activamos
				if Debug_Activado then
				Debug.Set_Status(False);
				Debug_Activado:= False;
				pantalla.Poner_Color(pantalla.Rojo);
				Ada.Text_IO.Put_Line ("Desactivada información de debug");
				pantalla.Poner_Color(pantalla.Cierra);
				else
				Debug.Set_Status(True);
				Debug_Activado:= True;
				pantalla.Poner_Color(pantalla.Rojo);
				Ada.Text_IO.Put_Line ("Activada información de debug");
				pantalla.Poner_Color(pantalla.Cierra);
				end if;
				
				elsif ASU.To_String(Text) = ".sb" or ASU.To_String(Text) = ".senderbuffering" then
				pantalla.Poner_Color(pantalla.Rojo);
				handlers_peer.Sender_Buffering.Print_Map(handlers_peer.Mapa_Sender_Buffering);
				pantalla.Poner_Color(pantalla.Cierra);
				
				elsif ASU.To_String(Text) = ".sd" or ASU.To_String(Text) = ".senderdests" then
				pantalla.Poner_Color(pantalla.Rojo);
				handlers_peer.Sender_Dests.Print_Map(handlers_peer.Mapa_Sender_Dests);
				pantalla.Poner_Color(pantalla.Cierra);
				
				elsif ASU.To_String(Text) = ".h" or ASU.To_String(Text) = ".help" then
					pantalla.Poner_Color(pantalla.Rojo);
					Ada.Text_IO.Put_Line ("              Comandos              Efectos");
					Ada.Text_IO.Put_Line ("              =================     =======");
					Ada.Text_IO.Put_Line ("              .nb .neighbors        lista de vecinos");
					Ada.Text_IO.Put_Line ("              .lm .latest_msgs      lista de últimos mensajes recibidos");
					Ada.Text_IO.Put_Line ("              .sb .senderbuffering  Muestra Sender_Buffering");
					Ada.Text_IO.Put_Line ("              .sd .senderdests      Muestra Sender_Dests");
					Ada.Text_IO.Put_Line ("              .debug                toggle para info de debug");
					Ada.Text_IO.Put_Line ("              .wai .whoami          Muestra en pantalla: nick | EP_H | EP_R");
					Ada.Text_IO.Put_Line ("              .h .help              muestra esta información de ayuda");
					Ada.Text_IO.Put_Line ("              .salir                termina el programa");
					pantalla.Poner_Color(pantalla.Cierra);
				else
				Numero_Seq:= Numero_Seq + 1;
				Chatmessages.P_Buffer_Main:= new LLU.Buffer_Type(1024);
				--Guardamos el mensaje Writer
				handlers_peer.Latest_Msgs.Put (handlers_peer.Mapa_mensajes, EP_H, Numero_Seq, Success);
				Debug.Put_Line ("Añadimos a latest_msgs " & " " & LLU.Image(EP_H) & " " & chatmessages.Seq_N_T'Image(Numero_Seq));
				--Enviamos el mensajes Writer al vecindario
				handlers_peer.Enviar_Writer (EP_H, Numero_Seq, EP_H, EP_H, Mi_Nick, Text);

				end if;
		end loop;
		end if;
	
	Ada.Text_IO.Put_Line ("Saliendo de Peer-Chat ...");
	delay 10.0 * chatmessages.Plazo_retransmision;
	LLU.Finalize; --Finalizamos lower layer
	Handlers_peer.Terminar_Timed_Handlers; --Finalizamos Timed_Handlers
	
	exception
   	when Usage_Error =>
        Ada.Text_IO.Put_Line ("Error de uso, introduzca: ./peer_chat <port> <nickname> <min_delay> <max_delay> <fault_pct> ((<neighbor_host> <neighbor_port>) (<neighbor_host> <neighbor_port>))");
	LLU.Finalize;
	Handlers_peer.Terminar_Timed_Handlers;
	
	when Range_Error =>
	Ada.Text_IO.Put_Line ("Error de rango: min_delay(0...inf); max_delay(0...inf); fault_pct(0...100)");
	LLU.Finalize;
	Handlers_peer.Terminar_Timed_Handlers;
	
end peer_chat;
