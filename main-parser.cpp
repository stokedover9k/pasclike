#include <stdio.h>
#include <iostream>
#include <fstream>
#include "pasclike.tab.h"
#include "loglib.h"
#include "parser-settings.h"

extern int yyparse(void);
extern FILE *yyin;

using std::cout;
using std::endl;

//=================================================
int main( int argc, char* argv[] )
//=================================================
{
  Output2FILE::Stream() = stdout;

  // redirect output: rule logging
  std::ofstream rulesOutFile("rule.out");
  //rulesLog.rdbuf(rulesOutFile.rdbuf());

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

  return 0;
}
