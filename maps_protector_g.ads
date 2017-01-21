with Maps_G;

generic  
   with package Maps is new Maps_G (<>);
package Maps_Protector_G is

   type Prot_Map is limited private;

   procedure Get (M       : in out Prot_Map;
                  Key     : in     Maps.Key_Type;
                  Value   : out    Maps.Value_Type;
                  Success : out    Boolean);


   procedure Put (M       : in out Prot_Map;
                  Key     : in     Maps.Key_Type;
                  Value   : in     Maps.Value_Type;
		  Success : out    Boolean);

   procedure Delete (M       : in out Prot_Map;
                     Key     : in     Maps.Key_Type;
                     Success : out    Boolean);
   
   subtype Keys_Array_Type is Maps.Keys_Array_Type;
   
   function Get_Keys (M : Prot_Map) return Keys_Array_Type;
   
   subtype Values_Array_Type is Maps.Values_Array_Type;

   function Get_Values (M : Prot_Map) return Values_Array_Type;

   function Map_Length (M : Prot_Map) return Natural;

   procedure Print_Map (M : in out Prot_Map);
	       		  
		  
private

   protected type Prot_Map is
      
      procedure Get (Key     : in  Maps.Key_Type;
		     Value   : out Maps.Value_Type;
		     Success : out Boolean);

      procedure Put (Key     : in  Maps.Key_Type;
		     Value   : in  Maps.Value_Type;
                     Success : out Boolean);

      procedure Delete (Key     : in  Maps.Key_Type;
			Success : out Boolean);
      
      function Get_Keys return Keys_Array_Type;

      function Get_Values return Values_Array_Type;

      function Map_Length return Natural;

      procedure Print_Map;
      
   private
      Map         : Maps.Map;      
   end Prot_Map;
   
end Maps_Protector_G;
