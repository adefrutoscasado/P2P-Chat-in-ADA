-- Alejandro de Frutos Casado

with Ada.Text_IO;
with Ada.Calendar;
with Gnat.Calendar.Time_IO;
with Ada.Strings.Unbounded;

package body funciones is

use type chatmessages.Seq_N_T;


function Seq_a_String (Seq_N: chatmessages.Seq_N_T) return String is 
begin
	return chatmessages.Seq_N_T'Image (Seq_N);
end Seq_a_String;

function CalendarTime_a_String (Tiempo: Ada.Calendar.Time) return String is
begin
    return Gnat.Calendar.Time_IO.Image(Tiempo, "%c");
end CalendarTime_a_String;


function Mess_Id_T_a_String (Mess: Mess_Id_T) return String is
begin
	return ((LLU.Image(Mess.EP)) & (", ") & Seq_a_String(Mess.Seq));
end Mess_Id_T_a_String;

function Destinations_T_a_String (Destinations: Destinations_T) return String is
String_de_array: ASU.Unbounded_String:= ASU.To_Unbounded_String("| ");
begin
	for i in 1..10 loop
		if LLU.Image(Destinations(i).EP) /= LLU.Image(Lower_Layer_UDP.Build("0.0.0.0",0))  then
		String_de_array:= ASU.To_Unbounded_String(ASU.To_String(String_de_array) & ASU.To_String(ASU.To_Unbounded_String(LLU.Image(Destinations(i).EP))) & ASU.To_String(ASU.To_Unbounded_String(", ")) & ASU.To_String(ASU.To_Unbounded_String(Natural'Image(Destinations(i).Retries))) & ASU.To_String(ASU.To_Unbounded_String(" | ")));
		end if;
	end loop;
	return ASU.To_String(String_de_array);
end Destinations_T_a_String;


function Value_T_a_String (Value: Value_T) return String is
begin
	return  ASU.To_String(ASU.To_Unbounded_String(ASU.To_String(ASU.To_Unbounded_String(LLU.Image(Value.EP_H_Creat))) & ASU.To_String(ASU.To_Unbounded_String(", ")) & Seq_a_String(Value.Seq_N)));
end;


function ">" (Left, Right: Mess_Id_T) return Boolean is
begin
	if LLU.Image(Left.EP) > LLU.Image(Right.EP) then
		return True;
	else
		if LLU.Image(Left.EP) = LLU.Image(Right.EP) then
			if Seq_a_String(Left.Seq) > Seq_a_String(Right.Seq) then
				return True;
			else 
				return False;
			end if;
		else
			return False;
		end if;
	end if;
end ">";


function "<" (Left, Right: Mess_Id_T) return Boolean is
begin
	if LLU.Image(Left.EP) < LLU.Image(Right.EP) then
		return True;
	else
		if LLU.Image(Left.EP) = LLU.Image(Right.EP) then
			if Seq_a_String(Left.Seq) < Seq_a_String(Right.Seq) then
				return True;
			else 
				return False;
			end if;
		else
			return False;
		end if;
	end if;
end "<";


function "=" (Left, Right: Mess_Id_T) return Boolean is
begin
	if LLU.Image(Left.EP) = LLU.Image(Right.EP) and Seq_a_String(Left.Seq) = Seq_a_String(Right.Seq) then
		return True;
	else
		return False;
	end if;
end "=";

end funciones;