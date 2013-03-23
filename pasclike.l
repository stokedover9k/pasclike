%{

#include <iostream>
#include <list>
#include <stdlib.h>
#include <cstring>
#include "pasclike.tab.h"

//------- logging settings --------
#include "loglib.h"

#ifndef SCANNER_LOG_LVL
#define SCANNER_LOG_LVL logDEBUG4
#endif

TLogLevel ScannerLog = SCANNER_LOG_LVL;
//---------------------------------
//------- symbol table ------------
#include "symbol-table.h"
//---------------------------------

#define YY_DECL extern "C" int yylex(void)
extern "C" char * lexemeDup();

using std::cout;
using std::endl;

int currentLineNumber = 1;
int commentCaller;

%}

%option noyywrap

DIGIT         [0-9]
LETTER        [A-Za-z]
UNSIGNED      {DIGIT}+
INTEGER       [+-]?{UNSIGNED}
DECIMAL       [+-]?{UNSIGNED}?\.{UNSIGNED}
EXPONENTIAL   ({DECIMAL}|{INTEGER}\.?)E{INTEGER}

RELOP         >=?|<[>=]?|=

%x IN_COMMENT

%%

  /************* White Space & Line Counts ****/

[ \t]*         { /* ignore whitespace */ }
[\n\r]         { currentLineNumber++;    }

  /************* Numbers **********************/

{INTEGER}      { LOG(ScannerLog) << "INTEGER    " << yytext;  yylval.lexeme = lexemeDup();  return INTEGER;   }
{DECIMAL}      { LOG(ScannerLog) << "DECIMAL    " << yytext;  yylval.lexeme = lexemeDup();  return DECIMAL;   }
{EXPONENTIAL}  { LOG(ScannerLog) << "EXPNUMBER  " << yytext;  yylval.lexeme = lexemeDup();  return EXPNUMBER; }

  /************* Relational Operators *********/

\<=             { LOG(ScannerLog) << "RELOP      " << yytext;  return LE; }
\<              { LOG(ScannerLog) << "RELOP      " << yytext;  return LT; }
\>=             { LOG(ScannerLog) << "RELOP      " << yytext;  return GE; }
\>              { LOG(ScannerLog) << "RELOP      " << yytext;  return GT; }
\<\>            { LOG(ScannerLog) << "RELOP      " << yytext;  return NE; }
=               { LOG(ScannerLog) << "RELOP      " << yytext;  return EQ; }

  /************* Reserved Keywords ************/

and            { LOG(ScannerLog) << "KEYWORD and";          return AND;         }
begin          { LOG(ScannerLog) << "KEYWORD begin";        return BEGIN_TOKEN; }
forward        { LOG(ScannerLog) << "KEYWORD forward";      return FORWARD;     }
div            { LOG(ScannerLog) << "KEYWORD div";          return DIV;         }
do             { LOG(ScannerLog) << "KEYWORD do";           return DO;          }
else           { LOG(ScannerLog) << "KEYWORD else";         return ELSE;        }
end            { LOG(ScannerLog) << "KEYWORD end";          return END_TOKEN;   }
for            { LOG(ScannerLog) << "KEYWORD for";          return FOR;         }
function       { LOG(ScannerLog) << "KEYWORD function";     return FUNCTION;    }
if             { LOG(ScannerLog) << "KEYWORD if";           return IF;          }
array          { LOG(ScannerLog) << "KEYWORD array";        return ARRAY;       }
mod            { LOG(ScannerLog) << "KEYWORD mod";          return MOD;         }
not            { LOG(ScannerLog) << "KEYWORD not";          return NOT;         }
of             { LOG(ScannerLog) << "KEYWORD of";           return OF;          }
or             { LOG(ScannerLog) << "KEYWORD or";           return OR;          }
procedure      { LOG(ScannerLog) << "KEYWORD procedure";    return PROCEDURE;   }
program        { LOG(ScannerLog) << "KEYWORD program";      return PROGRAM;     }
record         { LOG(ScannerLog) << "KEYWORD record";       return RECORD;      }
then           { LOG(ScannerLog) << "KEYWORD then";         return THEN;        }
to             { LOG(ScannerLog) << "KEYWORD to";           return TO;          }
type           { LOG(ScannerLog) << "KEYWORD type";         return TYPE;        }
var            { LOG(ScannerLog) << "KEYWORD var";          return VAR;         }
while          { LOG(ScannerLog) << "KEYWORD while";        return WHILE;       }

  /************* Reserved Symbols *************/

\.\.           { LOG(ScannerLog) << "RANGE";        return RANGE;       }
\.             { LOG(ScannerLog) << "DOT";          return '.';         }
,              { LOG(ScannerLog) << "COMMA";        return ',';         }
:              { LOG(ScannerLog) << "COLON";        return ':';         }
;              { LOG(ScannerLog) << "SEMICOLON";    return ';';         }
:=             { LOG(ScannerLog) << "ASSIGN";       return ASSIGN;      }
\(             { LOG(ScannerLog) << "LPAR";         return '(';         }
\)             { LOG(ScannerLog) << "RPAR";         return ')';         }
\[             { LOG(ScannerLog) << "LBRACKET";     return '[';         }
\]             { LOG(ScannerLog) << "RBRACKET";     return ']';         }
\+             { LOG(ScannerLog) << "PLUS";         return '+';         }
\-             { LOG(ScannerLog) << "MINUS";        return '-';         }
\*             { LOG(ScannerLog) << "MULT";         return '*';         }

  /************* Strings and ID's *************/

\"[^"\n\r]*\"                  { LOG(ScannerLog) << "STRING     " << yytext;
                                 yylval.lexeme = lexemeDup();  
                                 return STRING;                             }
{LETTER}({LETTER}|{DIGIT}|_)*  { LOG(ScannerLog) << "IDENTIFIER " << yytext;
                                 addSymbol( std::string(yytext) );
                                 yylval.lexeme = lexemeDup();
                                 return ID;                                 }

  /************* Comments *********************/

\{                      { commentCaller = YYSTATE;  BEGIN( IN_COMMENT );    }
<IN_COMMENT>[^\n\r\}]*  { /* Discard comment text */                        }
<IN_COMMENT>[\n\r]      { currentLineNumber++;                              }
<IN_COMMENT>\}          { BEGIN( commentCaller );                           }

  /************* Catch Others *****************/

.                       { LOG(ScannerLog) << "ERROR(" << currentLineNumber
                                      << "): Unrecognized Symbol \""
                                      << yytext << '"';   
                          std::stringstream ss;
                          ss << currentLineNumber;
                          yylval.lexeme = strdup(ss.str().c_str());
                          return ERROR_TOKEN;                               }

%%

char *lexemeDup() {
  char *str = (char*) malloc( yyleng + 1 );
  strcpy( str, yytext );
  return str;
}

