with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Maps_G is

   procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);


   procedure Get (M       : Map;
                  Key     : in  Key_Type;
                  Value   : out Value_Type;
                  Success : out Boolean) is
      P_Aux : Cell_A;
   begin
      P_Aux := M.P_First;
      Success := False;
      while not Success and P_Aux /= null Loop
         if P_Aux.Key = Key then
            Value := P_Aux.Value;
            Success := True;
         end if;
         P_Aux := P_Aux.Next;
      end loop;
   end Get;


   procedure Put (M     : in out Map;
                  Key   : Key_Type;
                  Value : Value_Type;
		  Success: out Boolean) is
      P_Aux : Cell_A;
      P_Aux_Previo: Cell_A;
      Found : Boolean;
      Contador:Natural:= 1;
   begin

      P_Aux := M.P_First;
      Found := False;
      Success:= False;
	
	-- Miramos si la lista esta llena
	if M.Length = Max_Length then
	Found:= True;
	Ada.Text_IO.Put_Line ("No se admiten mas vecinos!");
	end if;
	
	-- Si ya existe Key, cambiamos su Value
      while not Found and P_Aux /= null and Contador <= Max_Length loop
         if P_Aux.Key = Key then
            P_Aux.Value := Value;
            Found := True;
	    Success:= True;
         end if;
	 P_Aux_Previo := P_Aux;
	 P_Aux := P_Aux.Next;
	 Contador:= Contador + 1;
      end loop;
	
      -- Si no hemos encontrado Key añadimos al principio
      if not Found then
	if M.Length = 0 then
		M.P_First := new Cell'(Key, Value, M.P_First,M.P_Last);
		M.P_Last := M.P_First;
		M.Length := M.Length + 1;
		Success:= True;
	else
		M.P_First := new Cell'(Key, Value, M.P_First, null);
		
		 P_Aux := M.P_First;
		 P_Aux := P_Aux.Next;
		 P_Aux.Prev := M.P_First;
		
		M.Length := M.Length + 1;
		Success:= True;
	end if;
      end if;
      
   end Put;



   procedure Delete (M      : in out Map;
                     Key     : in  Key_Type;
                     Success : out Boolean) is
	P_Previo : Cell_A;     
        P_Aux  : Cell_A;
	P_Siguiente : Cell_A;
   begin
	Success:= False;
	P_Aux:= M.P_First;
	P_Previo:= P_Aux.Prev;
	P_Siguiente:= P_Aux.Next;
	
	if M.Length = 1 and P_Aux.Key = Key then
	M.P_First:= null;
	M.P_Last:= null;
	M.Length:= 0;
	Success:= True;
	end if;
	
	while not Success loop
	if P_Aux.Key = Key then
	
	if P_Aux.Prev = null then
	P_Siguiente.Prev:= null;
	M.P_First:= P_Siguiente;
	M.Length:= M.Length - 1;
	Success:= True;
	end if;
	
	if P_Aux.Next = null then
	P_Previo.Next:= null;
	M.P_Last:= P_Previo;
	M.Length:= M.Length - 1;
	Success:= True;
	end if;
	
	if not Success then
		P_Previo.Next:= P_Siguiente;
		P_Siguiente.Prev:= P_Previo;
	M.Length:= M.Length - 1;
	Success:= True;
	end if;
	
	end if;
		if not Success then --¿necesario?
		P_Aux:= P_Aux.Next;
		P_Previo:= P_Aux.Prev;
		P_Siguiente:= P_Aux.Next;
		end if;  --¿necesario?
	end loop;
	
   end Delete;


---------------------------------------------------------------------
   function Get_Keys (M      : in Map) return Keys_Array_Type is
       P_Aux : Cell_A;
       Contador: Natural:= 1;
	Array_Keys: Keys_Array_Type;
   begin
  
      P_Aux := M.P_First;
      while P_Aux /= null Loop
	Array_keys(Contador):= P_Aux.Key;
         P_Aux := P_Aux.Next;
	 Contador:= Contador + 1;
      end loop;
      
	if Contador <= Max_Length then
	while Contador <= Max_Length Loop
	Array_Keys(Contador):= Null_Key;
	Contador:= Contador + 1;
	end loop;
	end if;
	
	return Array_Keys;
	
   end Get_Keys;
---------------------------------------------------------------------
---------------------------------------------------------------------
   function Get_Values (M      : in Map) return Values_Array_Type is
       P_Aux : Cell_A;
	Contador: Natural:= 1;
	Array_Values: Values_Array_Type;
   begin
      P_Aux := M.P_First;
      while P_Aux /= null Loop
	Array_values(Contador):= P_Aux.Value;
         P_Aux := P_Aux.Next;
	 Contador:= Contador + 1;
      end loop;
      
	if Contador <= Max_Length then
	while Contador <= Max_Length Loop
	Array_Values(Contador):= Null_Value;
	Contador:= Contador + 1;
	end loop;
	end if;
	
	return Array_Values;
	
   end Get_Values;
---------------------------------------------------------------------




   function Map_Length (M : Map) return Natural is
   begin
      return M.Length;
   end Map_Length;

    procedure Print_Map (M : Map) is
      P_Aux : Cell_A;
   begin
      P_Aux := M.P_Last;

      Ada.Text_IO.Put_Line ("Map");
      Ada.Text_IO.Put_Line ("===");

      while P_Aux /= null loop
         Ada.Text_IO.Put_Line (Key_To_String(P_Aux.Key) & " " &
                                 Value_To_String(P_Aux.Value));
         P_Aux := P_Aux.Prev;
      end loop;
   end Print_Map;
   


end Maps_G;
