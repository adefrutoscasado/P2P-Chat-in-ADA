with Ordered_Maps_G;

generic  
   with package Maps is new Ordered_Maps_G (<>);
package Ordered_Maps_Protector_G is

   type Prot_Map is limited private;

   procedure Get (M       : in out Prot_Map;
                  Key     : in     Maps.Key_Type;
                  Value   : out    Maps.Value_Type;
                  Success : out    Boolean);


   procedure Put (M       : in out Prot_Map;
                  Key     : in     Maps.Key_Type;
                  Value   : in     Maps.Value_Type);

   procedure Delete (M       : in out Prot_Map;
                     Key     : in     Maps.Key_Type;
                     Success : out    Boolean);
   
   function Map_Length (M : Prot_Map) return Natural;

   procedure Print_Map (M : in out Prot_Map);
                          
                  
private

   protected type Prot_Map is
      
      procedure Get (Key     : in  Maps.Key_Type;
                     Value   : out Maps.Value_Type;
                     Success : out Boolean);

      procedure Put (Key     : in  Maps.Key_Type;
                     Value   : in  Maps.Value_Type);

      procedure Delete (Key     : in  Maps.Key_Type;
                        Success : out Boolean);
      
      function Map_Length return Natural;

      procedure Print_Map;
      
   private
      Map         : Maps.Map;      
   end Prot_Map;
   
end Ordered_Maps_Protector_G;
