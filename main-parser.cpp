#include <stdio.h>
#include <iostream>
#include <list>
#include <fstream>
#include "pasclike.tab.h"
#include "loglib.h"
#include "parser-settings.h"
#include "symtable.h"

extern int yyparse(void);
extern FILE *yyin;

using std::cout;
using std::endl;

extern symdb::Sym_table symtable;

extern symdb::Invalid_type *invalid_type;
extern symdb::Int_type *int_type;
extern symdb::String_type *string_type;
extern symdb::Bool_type *bool_type;
extern symdb::Var *bool_true;
extern symdb::Var *bool_false;

symdb::Invalid_type *invalid_type = new symdb::Invalid_type();
symdb::Int_type *int_type = new symdb::Int_type();
symdb::String_type *string_type = new symdb::String_type();
symdb::Bool_type *bool_type = new symdb::Bool_type();
symdb::Var *bool_true = new symdb::Var( "true", bool_type );
symdb::Var *bool_false = new symdb::Var( "false", bool_type );

void init_symtable() 
{
  using namespace symdb;

  symtable.put( bool_type );
  symtable.put( int_type );
  symtable.put( string_type );
  
  symtable.put( bool_true );
  symtable.put( bool_false );
}

//=================================================
int main( int argc, char* argv[] )
//=================================================
{
  Output2FILE::Stream() = fopen( "rules.out", "w" );

  init_symtable();

  // Initialize INPUT:
  // - if an argument is provided, it is expected to be the input file's name.
  if( argc > 1 )
    {
      yyin = fopen( argv[1], "r" );  // Attempt to open the file.
      if( yyin == NULL ) {           // If failed to open file, report error.
	cout << "Error: Parser could not open input file \""
	     << argv[1] << "\"." << endl;
	return 1;
      }
    }
  // - else, read from default location (standard input)
  //   - do nothing.

  do {
    yyparse();
  } while (!feof(yyin));

  // Print Symbol Table
  std::filebuf fb;
  fb.open("symtable.out", std::ios::out);
  std::ostream symOut(&fb);
  symOut << symtable << std::flush;
  return 0;
}
