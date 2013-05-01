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

void init_symtable() 
{
  using namespace symdb;

  Type *bool_type = new Bool_type();
  symtable.put( bool_type );
  symtable.put( new Int_type() );
  symtable.put( new String_type() );
  
  Var *var = new Var("true", bool_type);
  symtable.put( var );
  var = new Var("false", bool_type);
  symtable.put( var );
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
  //---- uncomment one ---------------
  std::ostream symOut(&fb);
  //----------------------------------
  std::cout << "PRINTING TABLE..." << std::endl;
  symOut << symtable << std::flush;
  return 0;
}
