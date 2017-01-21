-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with chatmessages;
with Lower_Layer_UDP;
with Ada.Command_Line;
with Debug;
with Pantalla;
with Timed_handlers;
with Ada.Unchecked_Deallocation;


package body Handlers_peer is

	package ATIO renames Ada.Text_IO;
	package CM renames chatmessages;
	
	use type ASU.Unbounded_String;
	use type CM.Message_Type;
	use type Ada.Calendar.Time;
	
	
	procedure Free is new Ada.Unchecked_Deallocation (LLU.Buffer_Type, chatmessages.Buffer_A_T);
	
	
	procedure Comprobar_existencia_mensaje (EP: in LLU.End_Point_Type; Seq_Num: in chatmessages.Seq_N_T; Mensaje_ya_visto: out Boolean; Mensaje_inmediatamente_consecutivo: out Boolean; Mensaje_del_futuro: out Boolean) is
	Keys_Array: Latest_Msgs.Keys_Array_Type;
	Values_Array: Latest_Msgs.Values_Array_Type;
	Contador: Integer:= 1;
	Found:Boolean:= False;
	begin
	Mensaje_ya_visto:= False;
	Mensaje_inmediatamente_consecutivo:= False;
	Mensaje_del_futuro:= False;
	
	Keys_Array := Latest_Msgs.Get_Keys(Mapa_mensajes);
	Values_Array := Latest_Msgs.Get_Values(Mapa_mensajes);
	
	While Keys_array(Contador) /= Lower_Layer_UDP.Build("0.0.0.0",0) and contador <= 10 loop
	
	if Keys_array(Contador) = EP then
	
		if Values_Array(Contador) >= Seq_Num then
		Mensaje_ya_visto:= True;
		Found:= True;
		end if;
	
		if (Values_Array(Contador) + 1) = Seq_Num then
		Mensaje_inmediatamente_consecutivo:= True;
		Found:= True;
		end if;
	
		if (Values_Array(Contador) + 1) < Seq_Num then
		Mensaje_del_futuro:= True;
		Found:= True;
		end if;
	
	end if;
	
	Contador:= Contador + 1;
	end loop;
	
	--Si no lo encuentra significa que es el primer mensaje. Hay que procesarlo!
	if not Found then
	Mensaje_inmediatamente_consecutivo:= True;
	end if;
	
	end Comprobar_existencia_mensaje;
	
	
	procedure Comprobar_vecindad (EP_Creat: in LLU.End_Point_Type; EP_Rsnd: in LLU.End_Point_Type; Es_Vecino: out Boolean) is
	Success: Boolean;
	begin
	Success:= False;
	Es_vecino:= False;
	if EP_Creat = EP_Rsnd then
	Es_vecino:= True;
	end if;	
	end Comprobar_vecindad;
	
	
	procedure Enviar_con_retransmisiones (Hora: in Ada.Calendar.Time) is
	Success: Boolean;
	Value: funciones.Value_T;
	Mess: funciones.Mess_Id_T;
	Array_destinos: funciones.Destinations_T;
	Array_destinos_aux:funciones.Destinations_T;
	Quedan_vecinos_sin_recibir: Boolean:= False;
	Key_aux: Ada.Calendar.Time;
	begin
		
	Sender_Buffering.Get(Mapa_Sender_Buffering, Hora, Value, Success);
	
	--Eliminamos la referencia del mensaje de Sender_Buffering
	Sender_Buffering.Delete(Mapa_Sender_Buffering, Hora, Success);
	
	Mess.EP:= Value.EP_H_Creat;
	Mess.Seq:= Value.Seq_N;
	Sender_Dests.Get(Mapa_Sender_Dests, Mess, Array_destinos, Success);
	Array_destinos_aux:= Array_destinos;
		
	for i in 1..10 loop
	if Array_destinos(i).EP /= Lower_Layer_UDP.Build("0.0.0.0",0) and Array_destinos(i).Retries <= 10 and not LLU.Is_Null(Array_destinos(i).EP) then

	Debug.Put_Line (" Send to: " & LLU.Image(Array_destinos(i).EP));
	LLU.Send (Array_destinos(i).EP, Value.P_Buffer);
	--Sumamos uno a Retries
	Array_destinos_aux(i).Retries:= Array_destinos_aux(i).Retries + 1;
	--Si se ha llegado aqui en algun momento (quedan vecinos que no han recibido nuestro mensaje) habra que reenviarlo, usamos un Boolean para informarlo
	Quedan_vecinos_sin_recibir:= True;
	end if;
	end loop;
	
	--Guardamos los Retries
	Sender_Dests.Put(Mapa_Sender_Dests, Mess, Array_destinos_aux);
	
	--Si no ha habido ninguna retransmision (O HAN LLEGADO A 10 RETRIES) significa que el mensaje ha sido recibido ya por todos (O NO SE DESEA QUE SE REENVIE MAS)
	if not Quedan_vecinos_sin_recibir then
		--Liberamos la memoria apuntada por Value.P_Buffer
		Free(Value.P_Buffer);
		--Eliminamos la referencia de Sender_Dests
		Sender_Dests.Delete(Mapa_Sender_Dests, Mess, Success);
	
	else
		--Han quedado vecinos sin asintir el mensaje, hay que llamar de nuevo a Enviar_con_retransmisiones
		Key_aux:= Ada.Calendar.Clock + chatmessages.Plazo_retransmision;
		--Almacenamos la referencia en Sender_Buffering de nuevo con la nueva hora a la que va a ser llamado
		Sender_Buffering.Put (Mapa_Sender_Buffering, Key_aux, Value);
		--LLamamos a Enviar_con_retransmisiones con Timed_Handlers
		Timed_Handlers.Set_Timed_Handler (Key_aux, Enviar_con_retransmisiones'Access);
	end if;

	end Enviar_con_retransmisiones;
	
	
	procedure Almacenar_mensaje (EP_H_Creat: in LLU.End_Point_Type; Seq: in chatmessages.Seq_N_T; Array_EPs_a_enviar: in Neighbors.Keys_Array_Type; Hora: in Ada.Calendar.Time; Buffer: chatmessages.Buffer_A_T) is
	Key_Sender_Dests: funciones.Mess_Id_T;
	Value_Sender_Dests: funciones.Destinations_T;
	Key_Sender_Buffering: Ada.Calendar.Time;
	Value_Sender_Buffering: funciones.Value_T;
	begin
	--Creamos Key_Sender_Dests
		Key_Sender_Dests.EP:= EP_H_Creat;
		Key_Sender_Dests.Seq:= Seq;
	--Creamos Value_Sender_dests
		for i in 1..10 loop
		--No añadimos al array de destinos la EP_H de la que hemos recibido el mensaje (Añadimos un null en su lugar)
		if Array_EPs_a_enviar(i) /= EP_H_Creat then
		Value_Sender_dests(i).Ep:= Array_EPs_a_enviar(i);
		Value_Sender_dests(i).Retries:= 0;
		else
		Value_Sender_dests(i).Ep:= Lower_Layer_UDP.Build("0.0.0.0",0);
		Value_Sender_dests(i).Retries:= 0;
		end if;
		end loop;
	--Creamos Key_Sender_Buffering
		Key_Sender_Buffering:= Hora;
	--Creamos Value_Sender_Buffering
		Value_Sender_Buffering.EP_H_Creat:= EP_H_Creat;
		Value_Sender_Buffering.Seq_N:= Seq;
		Value_Sender_Buffering.P_Buffer:= Buffer;
	--Almacenamos ambos
		Sender_Dests.Put (Mapa_Sender_Dests, Key_Sender_Dests, Value_Sender_Dests);
		Sender_Buffering.Put (Mapa_Sender_Buffering, Key_Sender_Buffering, Value_Sender_Buffering);
	end;
	

	procedure Gestionar_Ack (EP_H_Acker: in LLU.End_Point_Type; EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T) is
	Key_Sender_Dests: funciones.Mess_Id_T;
	Value_Sender_Dests: funciones.Destinations_T;
	Array_destinos: funciones.Destinations_T;
	Success: Boolean;
	Destinations_Modificado: Boolean:= False;
	Contador: Integer:= 1;
	begin
		--Ada.Text_IO.Put_Line ("Voy a gestionar ack con Ep_H_Creat=" & LLU.Image(EP_H_CREAT) & " y Seq=" & funciones.Seq_a_String(Seq_N));
		Key_Sender_Dests.EP:= EP_H_Creat;
		Key_Sender_Dests.Seq:= Seq_N;
		Sender_Dests.Get(Mapa_Sender_Dests, Key_Sender_Dests, Array_destinos, Success);
	if Success then
		for i in 1..10 loop
			if Array_destinos(i).EP = EP_H_Acker then
			Array_destinos(i).EP:= Lower_Layer_UDP.Build("0.0.0.0",0);
			Array_destinos(i).Retries:= 0;
			Destinations_Modificado:= True;
			end if;
		end loop;
	Sender_Dests.Put(Mapa_Sender_Dests, Key_Sender_Dests, Array_destinos);
	end if;
	
	end Gestionar_Ack;
	
	
	procedure Enviar_Ack (Mi_EP_H: in LLU.End_Point_Type; EP_H_Creat: in LLU.End_Point_Type; Seq: in chatmessages.Seq_N_T; EP_H_Rsnd: in LLU.End_Point_Type) is
	begin
	Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
	
	Debug.Put ("    FLOOD Ack ", Pantalla.Amarillo);
	Debug.Put_Line (" Send to: " & LLU.Image(EP_H_Rsnd) &  " asentimos: " & LLU.Image(EP_H_Creat) & " con Seq=" & funciones.Seq_a_String(Seq));
	
	CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Ack);
	LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
	LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_H_Creat);
	chatmessages.Seq_N_T'Output (chatmessages.P_Buffer_Handler,Seq);
	
	--Al enviar a un EP nulo nos devuelve un error al ejecutar. Protegemos el programa para no enviar a null.
	if not LLU.Is_null(EP_H_Rsnd) then
	LLU.Send (EP_H_Rsnd, Chatmessages.P_Buffer_Handler);
	end if;
	
	end;	
	
	
	procedure Enviar_Init (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_R_Creat: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; EP_H_Rsnd: in LLU.End_Point_Type) is 
	Keys_Array: Neighbors.Keys_Array_Type;
	Contador: Integer:= 1;
	FLOOD_Escrito: Boolean:= False;
	Hora: Ada.Calendar.Time;
	begin
	
	Keys_Array := Neighbors.Get_Keys(Mapa_vecinos);
	
	--No enviamos a quien nos envia el mensaje
	for i in 1..10 loop
	if Keys_Array(i) = EP_H_Rsnd then
	Keys_Array(i):= Lower_Layer_UDP.Build("0.0.0.0",0);
	end if;
	end loop;
	
	Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);

		CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Init);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_H_Creat);
		chatmessages.Seq_N_T'Output (chatmessages.P_Buffer_Handler,Seq_N);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_R_Creat);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Nick);
		
		Hora:= Ada.Calendar.Clock;
		Almacenar_mensaje (EP_H_Creat, Seq_N, Keys_Array, Hora, Chatmessages.P_Buffer_Handler);
		
		--Si no hay a quien mandar el mensaje no imprimimios FLOOD Init
		while Keys_Array(Contador) /= Lower_Layer_UDP.Build("0.0.0.0",0) loop
		if EP_H_Rsnd /= Keys_Array(Contador) then
		if not FLOOD_Escrito then
		Debug.Put ("    FLOOD Init ", Pantalla.Amarillo);
		FLOOD_Escrito:= True;
		end if;
		end if;
		Contador:= Contador + 1;
		end loop;
		
		Enviar_con_retransmisiones (Hora);
		
	end Enviar_Init;
	
	
	procedure Enviar_Confirm (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String) is 
	Keys_Array: Neighbors.Keys_Array_Type;
	Contador: Integer:= 1;
	FLOOD_Escrito: Boolean:= False;
	Hora: Ada.Calendar.Time;
	begin
	
	Keys_Array := Neighbors.Get_Keys(Mapa_vecinos);
	
	Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);

		CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Confirm);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_H_Creat);
		chatmessages.Seq_N_T'Output (chatmessages.P_Buffer_Handler,Seq_N);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Nick);
		
		Hora:= Ada.Calendar.Clock;
		Almacenar_mensaje (EP_H_Creat, Seq_N, Keys_Array, Hora, Chatmessages.P_Buffer_Handler);
		
		--Si no hay a quien mandar el mensaje no imprimimios FLOOD Confirm
		while Keys_Array(Contador) /= Lower_Layer_UDP.Build("0.0.0.0",0) loop
		if EP_H_Rsnd /= Keys_Array(Contador) then
		if not FLOOD_Escrito then
		Debug.Put ("    FLOOD Confirm ", Pantalla.Amarillo);
		FLOOD_Escrito:= True;
		end if;
		end if;
		Contador:= Contador + 1;
		end loop;
	
		Enviar_con_retransmisiones (Hora);
	
	end Enviar_Confirm;
	
	
	procedure Enviar_Writer (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; Text: in ASU.Unbounded_String) is 
	Keys_Array: Neighbors.Keys_Array_Type;
	Contador: Integer:= 1;
	FLOOD_Escrito: Boolean:= False;
	Hora: Ada.Calendar.Time;
	begin

	Keys_Array := Neighbors.Get_Keys(Mapa_vecinos);
	
	--No enviamos a quien nos envia el mensaje
	for i in 1..10 loop
	if Keys_Array(i) = EP_H_Rsnd then
	Keys_Array(i):= Lower_Layer_UDP.Build("0.0.0.0",0);
	end if;
	end loop;
	
	Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
		
		CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Writer);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_H_Creat);
		chatmessages.Seq_N_T'Output (chatmessages.P_Buffer_Handler,Seq_N);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Nick);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Text);
		
		Hora:= Ada.Calendar.Clock;
		Almacenar_mensaje (EP_H_Creat, Seq_N, Keys_Array, Hora, Chatmessages.P_Buffer_Handler);
		
		--Si no hay a quien mandar el mensaje no imprimimios FLOOD Writer
		while Keys_Array(Contador) /= Lower_Layer_UDP.Build("0.0.0.0",0) loop
		if EP_H_Rsnd /= Keys_Array(Contador) then
		if not FLOOD_Escrito then
		Debug.Put ("    FLOOD Writer ", Pantalla.Amarillo);
		FLOOD_Escrito:= True;
		end if;
		end if;
		Contador:= Contador + 1;
		end loop;
		
		Enviar_con_retransmisiones (Hora);
		
	end Enviar_Writer;
	
	
	procedure Enviar_Logout (EP_H_Creat: in LLU.End_Point_Type; Seq_N: in chatmessages.Seq_N_T; Mi_EP_H: in LLU.End_Point_Type; EP_H_Rsnd: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String; Confirm_Sent: in Boolean) is 
	Keys_Array: Neighbors.Keys_Array_Type;
	Contador: Integer:= 1;
	FLOOD_Escrito: Boolean:= False;
	Hora: Ada.Calendar.Time;
	begin
	Keys_Array := Neighbors.Get_Keys(Mapa_vecinos);
	
	--No enviamos a quien nos envia el mensaje
	for i in 1..10 loop
	if Keys_Array(i) = EP_H_Rsnd then
	Keys_Array(i):= Lower_Layer_UDP.Build("0.0.0.0",0);
	end if;
	end loop;
	
	Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
	
		CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Logout);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,EP_H_Creat);
		chatmessages.Seq_N_T'Output (chatmessages.P_Buffer_Handler,Seq_N);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Nick);
		Boolean'Output (chatmessages.P_Buffer_Handler,Confirm_Sent);
		
		Hora:= Ada.Calendar.Clock;
		Almacenar_mensaje (EP_H_Creat, Seq_N, Keys_Array, Hora, Chatmessages.P_Buffer_Handler);
		
		--Si no hay a quien mandar el mensaje no imprimimios FLOOD Logout
		while Keys_Array(Contador) /= Lower_Layer_UDP.Build("0.0.0.0",0) loop
		if EP_H_Rsnd /= Keys_Array(Contador) then
		if not FLOOD_Escrito then
		Debug.Put ("    FLOOD Logout ", Pantalla.Amarillo);
		FLOOD_Escrito:= True;
		end if;
		end if;
		Contador:= Contador + 1;
		end loop;
		
		Enviar_con_retransmisiones (Hora);
		
	end Enviar_Logout;
	
	
	procedure Enviar_Reject (EP_R_Creat: in LLU.End_Point_Type; Mi_EP_H: in LLU.End_Point_Type; Nick: in ASU.Unbounded_String) is
	begin
	
		Chatmessages.P_Buffer_Handler:= new LLU.Buffer_Type(1024);
	
		Debug.Put ("    FLOOD Reject ", Pantalla.Amarillo);
	
		CM.Message_Type'Output (chatmessages.P_Buffer_Handler,CM.Reject);
		LLU.End_Point_Type'Output (chatmessages.P_Buffer_Handler,Mi_EP_H);
		ASU.Unbounded_String'Output (chatmessages.P_Buffer_Handler,Nick);
		
		Debug.Put_Line (" Send to: " & LLU.Image(EP_R_Creat));
		LLU.Send (EP_R_Creat, Chatmessages.P_Buffer_Handler);
		
	end;
	
	
	procedure Eliminar_usuario (EP_H_Creat: in LLU.End_Point_Type; Confirm_Sent: in Boolean) is
	Keys_Array_Vecinos: Neighbors.Keys_Array_Type;
	Keys_Array_Mensajes: Latest_Msgs.Keys_Array_Type;
	Seq_Number_para_get: chatmessages.Seq_N_T;
	AdaCalendarTime_para_get: Ada.Calendar.Time;
	Success: Boolean;
	begin
	Keys_Array_Vecinos := Neighbors.Get_Keys(Mapa_vecinos);
	Keys_Array_Mensajes := Latest_Msgs.Get_Keys(Mapa_mensajes);
	
	------------------ELIMINAR VECINO----------------------------
	Success:= False;
		--Comprobamos si tenemos el vecino
	Neighbors.Get (Mapa_Vecinos, EP_H_Creat, AdaCalendarTime_para_get, Success);
		--Si es vecino lo eliminamos
	if Success then
		Neighbors.Delete (Mapa_Vecinos, EP_H_Creat, Success);
	end if;
	
	------------------ELIMINAR MENSAJES----------------------------	
	Success:= False;
		--Comprobamos si hay mensajes del usuario
	Latest_Msgs.Get (Mapa_Mensajes, EP_H_Creat, Seq_Number_para_get, Success);
		--Vamos a eliminar el historial de mensajes del usuario
	if Success then
		Latest_Msgs.Delete (Mapa_Mensajes, EP_H_Creat, Success);
	end if;
	end Eliminar_usuario;
	
	
	procedure Terminar_Timed_Handlers is
	begin
		Timed_Handlers.Finalize;
	end;
	
	
	procedure Peer_Handler (From: in LLU.End_Point_Type;To: in LLU.End_Point_Type; Buffer: access LLU.Buffer_Type) is
	
	EP_H_Creat: LLU.End_Point_Type; 
	EP_H_Rsnd: LLU.End_Point_Type; 
	EP_R_Creat: LLU.End_Point_Type;
	EP_H_ACKer: LLU.End_Point_Type;
	Seq_N: chatmessages.Seq_N_T;
	Seq_Number_para_get: chatmessages.Seq_N_T;
	Tipo_Mensaje: CM.Message_Type;
	Nick: ASU.Unbounded_String;
	Text: ASU.Unbounded_String;
	Confirm_Sent: Boolean;
	Mensaje_ya_visto:Boolean;
	Mensaje_inmediatamente_consecutivo:Boolean;
	Mensaje_del_futuro:Boolean;
	Success: Boolean;
	Keys_Array_Mensajes: Latest_Msgs.Keys_Array_Type;
	Found: Boolean:= False;
	
   begin
   
	
   	Tipo_Mensaje := CM.Message_Type'Input (Buffer);
	EP_H_Creat:= LLU.End_Point_Type'Input (Buffer);
	--Si es un Ack extraemos otro End_Point mas. 
	--Tambien renombramos EP_H_Acker con el EP de EP_H_Creat ya que en los ACK el EP_H_Acker va en la segunad posicion del buffer, y el EP_H_Creat en tercera
	if Tipo_Mensaje = CM.Ack then
		
		--Debug.Put_Line ("Empiezo a procesar ACK");
	
	EP_H_Acker:= EP_H_Creat;
	EP_H_Creat:= LLU.End_Point_Type'Input (Buffer);
	Seq_N:= chatmessages.Seq_N_T'Input (Buffer);

		Debug.Put ("RCV Ack ", Pantalla.Amarillo);
		Debug.Put_Line ("de " & LLU.Image(EP_H_Acker) & " asiente: " & LLU.Image(EP_H_Creat) & " con Seq=" & funciones.Seq_a_String(Seq_N));
		
		Gestionar_Ack (EP_H_Acker, EP_H_Creat, Seq_N);
		
		--Debug.Put_Line ("Termino de procesar ACK");
		
	else
	Seq_N:= chatmessages.Seq_N_T'Input (Buffer);
		Comprobar_existencia_mensaje (EP_H_Creat, Seq_N, Mensaje_ya_visto, Mensaje_inmediatamente_consecutivo, Mensaje_del_futuro);
	end if;
	
	
	
		if Tipo_Mensaje /= CM.Logout and Tipo_Mensaje /= CM.Ack and Mensaje_inmediatamente_consecutivo and not Mensaje_ya_visto then
		--Si no es un logout lo guardamos. Cuando recibimos un logout eliminamos el historial de mensajes del usuario, asi que si nos reenvian el mismo logout lo considerariamos como nuevo
		Latest_Msgs.Put (Mapa_mensajes, EP_H_Creat, Seq_N, Success);
		Debug.Put_Line ("AÃ±adimos a latest_msgs " & " " & LLU.Image(EP_H_Creat) & " " & chatmessages.Seq_N_T'Image(Seq_N));

		end if;
	
	
	
   	if Tipo_Mensaje = CM.Init then
		
		--Debug.Put_Line ("Empiezo a procesar Init");

			EP_H_Rsnd:= LLU.End_Point_Type'Input (Buffer);
			EP_R_Creat:= LLU.End_Point_Type'Input (Buffer);
			Nick:= ASU.Unbounded_String'Input (Buffer);
		

		if Mensaje_inmediatamente_consecutivo then
		Debug.Put ("RCV Init ", Pantalla.Amarillo);

		Debug.Put_Line (LLU.Image(EP_H_Creat) & " " & LLU.Image(EP_H_Rsnd) & " " & ASU.To_String(Nick));
		
		--Si el nick de inicio de sesion del usuario entrante es igual que el nuestro le mandamos A ÉL un reject
		if  Nick = ASU.To_Unbounded_String(Ada.Command_Line.Argument(2)) then
		Enviar_Reject (EP_R_Creat, To, Nick);
		else
		--Sino reenviamos el Init a los demas nodos
		Enviar_Init (EP_H_Creat, Seq_N, To, EP_R_Creat,Nick, EP_H_Rsnd); --Se supone que To es el EP_Handler que estoy usando
		end if;
		end if;
		
		Enviar_Ack(To, EP_H_Creat, Seq_N, EP_H_Rsnd);
		
		--Debug.Put_Line ("Termino de procesar Init");
		
	end if;
	
	if Tipo_Mensaje = CM.Confirm then
		
		--Debug.Put_Line ("Empiezo a procesar Confirm");
		
		Debug.Put ("RCV Confirm ", Pantalla.Amarillo);
		
			EP_H_Rsnd:= LLU.End_Point_Type'Input (Buffer);
			Nick:= ASU.Unbounded_String'Input (Buffer);
		
		Debug.Put_Line (LLU.Image(EP_H_Creat) & " " & LLU.Image(EP_H_Rsnd) & " " & ASU.To_String(Nick));
		
		if Mensaje_inmediatamente_consecutivo then
		Ada.Text_IO.Put_Line (ASU.To_String(Nick) & " ha entrado en el chat");
		
		--Si la EP del creador coincide con la EP de quien me reenvia el mensaje, significa que es mi vecino. Tengo que agregarle
		if EP_H_Creat = EP_H_Rsnd then
		Neighbors.Put (Mapa_vecinos, EP_H_Creat, Ada.Calendar.Clock, Success);
		Debug.Put_Line ("AÃ±adimos a neighbors " & LLU.Image(EP_H_Creat));
		end if;
		
		--Reenviamos confirm para que los demas nodos puedan mostrar su inicio de sesion
		Enviar_Confirm (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick);
		
		end if;
		
		if Mensaje_del_futuro then
		Enviar_Confirm (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick);
		else
		Enviar_Ack(To, EP_H_Creat, Seq_N, EP_H_Rsnd);
		end if;
		
		--Debug.Put_Line ("Termino de procesar Confirm");

	end if;
	
	if Tipo_Mensaje = CM.Writer then
		
		--Debug.Put_Line ("Empiezo a procesar Writer");

		Debug.Put ("RCV Writer ", Pantalla.Amarillo);
		
			EP_H_Rsnd:= LLU.End_Point_Type'Input (Buffer);
			Nick:= ASU.Unbounded_String'Input (Buffer);
			Text:= ASU.Unbounded_String'Input (Buffer);
		
		Debug.Put_Line (LLU.Image(EP_H_Creat) & " " & LLU.Image(EP_H_Rsnd) & " " & ASU.To_String(Nick) & " " & ASU.To_String(Text));
		
		if Mensaje_inmediatamente_consecutivo then
		Ada.Text_IO.Put_Line (ASU.To_String(Nick) & " dice: " & ASU.To_String(Text));
		
		--Reenviamos el Writer
		Enviar_Writer (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick, Text);
		end if;


		if Mensaje_del_futuro then
		Enviar_Writer (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick, Text);
		else
		Enviar_Ack(To, EP_H_Creat, Seq_N, EP_H_Rsnd);
		end if;
		
		--Debug.Put_Line ("Termino de procesar Writer");
		
	end if;
	
	
	if Tipo_Mensaje = CM.Logout then
		
		--Debug.Put_Line ("Empiezo a procesar Logout");
		
		if Mensaje_inmediatamente_consecutivo then
		Debug.Put ("RCV Logout ", Pantalla.Amarillo);
		
			EP_H_Rsnd:= LLU.End_Point_Type'Input (Buffer);
			Nick:= ASU.Unbounded_String'Input (Buffer);
			Confirm_Sent:= Boolean'Input (Buffer);
		
		Debug.Put_Line (LLU.Image(EP_H_Creat) & " " & LLU.Image(EP_H_Rsnd) & " " & ASU.To_String(Nick) & " " & Boolean'Image(Confirm_Sent));
		
		-- Buscamos si tenemos el EP_H_Creat en latest msgs, para no provocar una inundacion de logouts infinita
		Latest_Msgs.Get (Mapa_Mensajes, EP_H_Creat, Seq_Number_para_get, Success);
	
		
		if Success then
		--Si habiamos anunciado previamente que habia entrado (recibimos Confirm_Sent TRUE) debemos anunciar ahora que ha salido
		if Confirm_sent then
		Ada.Text_IO.Put_Line (ASU.To_String(Nick) & " ha salido del chat");
		end if;
		
		--Reenviamos el logout
		Enviar_Logout (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick, Confirm_Sent);
		--Eliminamos el usuario
		Eliminar_usuario (EP_H_Creat, Confirm_Sent);
		
		Debug.Put_Line ("Eliminamos de neighbors " & LLU.Image(EP_H_Creat));
		
		end if;
		
		
		if Mensaje_del_futuro then
		Enviar_Logout (EP_H_Creat, Seq_N, To, EP_H_Rsnd, Nick, Confirm_Sent);
		else
		Enviar_Ack(To, EP_H_Creat, Seq_N, EP_H_Rsnd);
		end if;
		
		--Debug.Put_Line ("Termino de procesar Logout");
		
		end if;
		end if;
	
	
	
	end Peer_Handler;
  
  
  end Handlers_peer;