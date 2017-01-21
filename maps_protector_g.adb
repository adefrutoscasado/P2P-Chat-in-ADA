package body Maps_Protector_G is

   protected body Prot_Map is

      procedure Get (Key    : in  Maps.Key_Type;
		     Value  : out Maps.Value_Type;
		     Success : out Boolean) is
      begin
	 Maps.Get(Map, Key, Value, Success);	 
      end Get;


      procedure Put (Key   : Maps.Key_Type;
		     Value : Maps.Value_Type;
                     Success : out Boolean) is
      begin
	 Maps.Put(Map, Key, Value, Success);
      end Put;
      

      procedure Delete (Key     : in  Maps.Key_Type;
			Success : out Boolean) is
      begin
	 Maps.Delete(Map, Key, Success);
      end Delete;
      
      function Get_Keys return Keys_Array_Type is
      begin
	 return Maps.Get_Keys(Map);
      end Get_Keys;

      function Get_Values return Values_Array_Type is
      begin
	 return Maps.Get_Values(Map);
      end Get_Values;

      function Map_Length return Natural is
      begin
	 return Maps.Map_Length(Map);
      end Map_Length;

      procedure Print_Map is
      begin
	 Maps.Print_Map(Map);
      end Print_Map;


   end Prot_Map;


   procedure Get (M       : in out Prot_Map;
                  Key     : in  Maps.Key_Type;
                  Value   : out Maps.Value_Type;
                  Success : out Boolean) is
   begin
      M.Get(Key, Value, Success);
   end Get;


   procedure Put (M     : in out Prot_Map;
                  Key   : Maps.Key_Type;
                  Value : in Maps.Value_Type;
		  Success : out Boolean) is
   begin
      M.Put(Key, Value, Success);
   end Put;
   

   procedure Delete (M      : in out Prot_Map;
                     Key     : in  Maps.Key_Type;
                     Success : out Boolean) is
   begin
      M.Delete(Key, Success);
   end Delete;
   
   function Get_Keys (M : Prot_Map) return Keys_Array_Type is
   begin
      return M.Get_Keys;
   end Get_Keys;

   function Get_Values (M : Prot_Map) return Values_Array_Type is
   begin
      return M.Get_Values;
   end Get_Values;

   function Map_Length (M : Prot_Map) return Natural is
   begin
      return M.Map_Length;
   end Map_Length;

   procedure Print_Map (M : in out Prot_Map) is
   begin
      M.Print_Map;
   end Print_Map;
		  

end Maps_Protector_G;
