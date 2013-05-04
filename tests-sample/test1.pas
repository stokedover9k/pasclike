{
	Test - 1
	Error Free
}
	
program lexer_test;

type
  int = integer;

var
  i : integer;
  b : boolean;
  f : float;

function foo(x : integer) : i; forward;

procedure bar(x : int); forward;

begin
  int := 0;
  i := int;
  i := integer;
  integer := 0;
  false := b;
  true := b and false;
  bar(int);
  bar(integer)
end.

