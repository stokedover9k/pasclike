program vars_test;

var
   a, b, c, d, i, j : integer;
   nums		    : array[1..10] of array[1..9] of integer;
   is_true	    : boolean;
   is_false	    : boolean;
   result	    : boolean;

begin
   if ( c > i ) then
      result := is_true;

   if ( is_true ) then begin
      result := is_true;
      result := is_true;
   end else
      result := is_false;

   if ( a + c * c = d ) then
      if ( is_false ) then begin
	 result := is_false;
      end else
	 result := is_true;
   result := is_true;
   
end.
