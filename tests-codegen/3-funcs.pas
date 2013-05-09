program vars_test;

var
   a, b, c, d, i, j		: integer;
   nums				: array[1..10] of array[1..9] of integer;
   bob				: record
				     age    : integer;
				     name   : string;
				     grades : array[1..10] of integer
				  end;	    
   correct			: boolean;

function divides(x, y : integer) : boolean;
begin

end; { divides }

procedure gamble(m, n : integer); forward;
		      
begin
   correct := divides(a, b);
   correct := divides( a * b, c + d );

   gamble(c, d);
   gamble(a + b div c - d, nums[c][d]);
end.
