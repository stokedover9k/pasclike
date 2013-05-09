program vars_test;

var
   a, b, c, d, i, j : integer;
   nums		    : array[1..10] of array[1..9] of integer;
   bob		    : record
			 age	: integer;
			 name	: string;
			 grades	: array[1..10] of integer
		      end;	

function divides(x, y : integer) : boolean;
begin

end; { divides }

begin
   a := b + c * d;
   a := b * c + d;
   a := -b * c;
   a := i * -j;
end.
