package body Ordered_Maps_Protector_G is

   protected body Prot_Map is

      procedure Get (Key    : in  Maps.Key_Type;
                     Value  : out Maps.Value_Type;
                     Success : out Boolean) is
      begin
         Maps.Get(Map, Key, Value, Success);     
      end Get;


      procedure Put (Key   : Maps.Key_Type;
                     Value : Maps.Value_Type) is
      begin
         Maps.Put(Map, Key, Value);
      end Put;
      

      procedure Delete (Key     : in  Maps.Key_Type;
                        Success : out Boolean) is
      begin
         Maps.Delete(Map, Key, Success);
      end Delete;
      
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
                  Value : in Maps.Value_Type) is
   begin
      M.Put(Key, Value);
   end Put;
   

   procedure Delete (M      : in out Prot_Map;
                     Key     : in  Maps.Key_Type;
                     Success : out Boolean) is
   begin
      M.Delete(Key, Success);
   end Delete;
   
   function Map_Length (M : Prot_Map) return Natural is
   begin
      return M.Map_Length;
   end Map_Length;

   procedure Print_Map (M : in out Prot_Map) is
   begin
      M.Print_Map;
   end Print_Map;
                  

end Ordered_Maps_Protector_G;
