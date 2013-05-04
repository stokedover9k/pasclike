{ test if/while/for/}
program test4;

var 
    a : integer;

begin
    if  (a < 0) then a := 1 else a := 2; 
    if  (a < 0) then begin a := 1; a:=2; end else a := 2; 
    while ( a > 0 )   do begin end;
    for a := 0 to 10  do begin end;  
end

.
