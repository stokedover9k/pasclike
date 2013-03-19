#include <stdio.h>
#include <iostream>
#include "pasclike.tab.h"

using std::cout;
using std::endl;

YYSTYPE yylval;

extern "C" {
  extern int yylex();
  extern FILE* yyin;
  extern char* yytext;
}

void reportToken( int token )
{
  switch( token )
    {
    case INTEGER:     cout << "INTEGER "    << yylval.lexeme;  break;
    case DECIMAL:     cout << "DECIMAL "    << yylval.lexeme;  break;
    case EXPNUMBER:   cout << "EXPNUMBER "  << yylval.lexeme;  break;

    case LE:          cout << "RELOP <=";  break;
    case LT:          cout << "RELOP <" ;  break;
    case GE:          cout << "RELOP >=";  break;
    case GT:          cout << "RELOP >" ;  break;
    case NE:          cout << "RELOP <>";  break;
    case EQ:          cout << "RELOP =" ;  break;

    case STRING:      cout << "STRING "     << yylval.lexeme;  break;
    case ID:          cout << "IDENTIFIER " << yylval.lexeme;  break;

    case ERROR_TOKEN: cout << "ERROR(" << yylval.lexeme
			   << "): Unrecognized Symbol \"" << yytext
			   << '"';                             break;

    case RANGE:      cout << "RANGE"    ;  break;
    case DOT:        cout << "DOT"      ;  break;
    case COMMA:      cout << "COMMA"    ;  break;
    case COLON:      cout << "COLON"    ;  break;
    case SEMICOLON:  cout << "SEMICOLON";  break;
    case ASSIGN:     cout << "ASSIGN"   ;  break;
    case LPAREN:     cout << "LPAR"     ;  break;
    case RPAREN:     cout << "RPAR"     ;  break;
    case LBRACKET:   cout << "LBRACKET" ;  break;
    case RBRACKET:   cout << "RBRACKET" ;  break;
    case PLUS:       cout << "PLUS"     ;  break;
    case MINUS:      cout << "MINUS"    ;  break;
    case MULT:       cout << "MULT"     ;  break;

    default:
      cout << "KEYWORD ";
      switch( token )
	{
	case AND:          cout << "and"      ;  break;
	case BEGIN_TOKEN:  cout << "begin"    ;  break;
	case FORWARD:      cout << "forward"  ;  break;
	case DIV:          cout << "div"      ;  break;
	case DO:           cout << "do"       ;  break;
	case ELSE:         cout << "else"     ;  break;
	case END_TOKEN:    cout << "end"      ;  break;
	case FOR:          cout << "for"      ;  break;
	case FUNCTION:     cout << "function" ;  break;
	case IF:           cout << "if"       ;  break;
	case ARRAY:        cout << "array"    ;  break;
	case MOD:          cout << "mod"      ;  break;
	case NOT:          cout << "not"      ;  break;
	case OF:           cout << "of"       ;  break;
	case OR:           cout << "or"       ;  break;
	case PROCEDURE:    cout << "procedure";  break;
	case PROGRAM:      cout << "program"  ;  break;
	case RECORD:       cout << "record"   ;  break;
	case THEN:         cout << "then"     ;  break;
	case TO:           cout << "to"       ;  break;
	case TYPE:         cout << "type"     ;  break;
	case VAR:          cout << "var"      ;  break;
	case WHILE:        cout << "while"    ;  break;
	default:  throw "Unexpected token";  break;
	}
      break;
    }

  cout << endl;

  delete yylval.lexeme;
  yylval.lexeme = 0;
}

//=================================================
int main( int argc, char* argv[] )
//=================================================
{
  // Initialize INPUT:
  // - if an argument is provided, it is expected to be the input file's name.
  if( argc > 1 ) 
    {
      yyin = fopen( argv[1], "r" );  // Attempt to open the file.
      if( yyin == NULL ) {           // If failed to open file, report error.
	cout << "Error: could not open input file \"" 
	     << argv[1] << "\"." << endl;
	return 1;
      }
    }
  // - else, read from default location (standard input).
  //   - do nothing.
    
  int token;
  while( token = yylex() )
    reportToken( token );

  return 0;
}
