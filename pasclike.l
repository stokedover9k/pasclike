%{

#include <iostream>
#include <stdlib.h>
#include <cstring>
#include "pasclike.tab.h"
#include "loglib.h"

#define YY_DECL extern "C" int yylex(void)
extern "C" char * lexemeDup();
YYSTYPE yylval;

using std::cout;
using std::endl;

TLogLevel logLvl = logDEBUG1;

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
\n             { currentLineNumber++;    }

  /************* Numbers **********************/

{INTEGER}      { LOG(logLvl) << "INTEGER    " << yytext;  yylval.lexeme = lexemeDup();  return INTEGER;   }
{DECIMAL}      { LOG(logLvl) << "DECIMAL    " << yytext;  yylval.lexeme = lexemeDup();  return DECIMAL;   }
{EXPONENTIAL}  { LOG(logLvl) << "EXPNUMBER  " << yytext;  yylval.lexeme = lexemeDup();  return EXPNUMBER; }

  /************* Relational Operators *********/

{RELOP}        { LOG(logLvl) << "RELOP      " << yytext;  yylval.lexeme = lexemeDup();  return RELOP;  }

  /************* Reserved Keywords ************/

and            { LOG(logLvl) << "KEYWORD and";          return AND;         }
begin          { LOG(logLvl) << "KEYWORD begin";        return BEGIN_TOKEN; }
forward        { LOG(logLvl) << "KEYWORD forward";      return FORWARD;     }
div            { LOG(logLvl) << "KEYWORD div";          return DIV;         }
do             { LOG(logLvl) << "KEYWORD do";           return DO;          }
else           { LOG(logLvl) << "KEYWORD else";         return ELSE;        }
end            { LOG(logLvl) << "KEYWORD end";          return END_TOKEN;   }
for            { LOG(logLvl) << "KEYWORD for";          return FOR;         }
function       { LOG(logLvl) << "KEYWORD function";     return FUNCTION;    }
if             { LOG(logLvl) << "KEYWORD if";           return IF;          }
array          { LOG(logLvl) << "KEYWORD array";        return ARRAY;       }
mod            { LOG(logLvl) << "KEYWORD mod";          return MOD;         }
not            { LOG(logLvl) << "KEYWORD not";          return NOT;         }
of             { LOG(logLvl) << "KEYWORD of";           return OF;          }
or             { LOG(logLvl) << "KEYWORD or";           return OR;          }
procedure      { LOG(logLvl) << "KEYWORD procedure";    return PROCEDURE;   }
program        { LOG(logLvl) << "KEYWORD program";      return PROGRAM;     }
record         { LOG(logLvl) << "KEYWORD record";       return RECORD;      }
then           { LOG(logLvl) << "KEYWORD then";         return THEN;        }
to             { LOG(logLvl) << "KEYWORD to";           return TO;          }
type           { LOG(logLvl) << "KEYWORD type";         return TYPE;        }
var            { LOG(logLvl) << "KEYWORD var";          return VAR;         }
while          { LOG(logLvl) << "KEYWORD while";        return WHILE;       }

  /************* Reserved Symbols *************/

\.\.           { LOG(logLvl) << "RANGE";        return RANGE;       }
\.             { LOG(logLvl) << "DOT";          return DOT;         }
,              { LOG(logLvl) << "COMMA";        return COMMA;       }
:              { LOG(logLvl) << "COLON";        return COLON;       }
;              { LOG(logLvl) << "SEMICOLON";    return SEMICOLON;   }
:=             { LOG(logLvl) << "ASSIGN";       return ASSIGN;      }
\(             { LOG(logLvl) << "LPAR";         return LPAREN;      }
\)             { LOG(logLvl) << "RPAR";         return RPAREN;      }
\[             { LOG(logLvl) << "LBRACKET";     return LBRACKET;    }
\]             { LOG(logLvl) << "RBRACKET";     return RBRACKET;    }
\+             { LOG(logLvl) << "PLUS";         return PLUS;        }
\-             { LOG(logLvl) << "MINUS";        return MINUS;       }
\*             { LOG(logLvl) << "MULT";         return MULT;        }
\/             { LOG(logLvl) << "DIVIDE";       return DIVIDE;      }

  /************* Strings and ID's *************/

\"[^"\n\r]*\"                  { LOG(logLvl) << "STRING     " << yytext;
                                 yylval.lexeme = lexemeDup();  
                                 return STRING;                             }
{LETTER}({LETTER}|{DIGIT}|_)*  { LOG(logLvl) << "IDENTIFIER " << yytext;
                                 yylval.lexeme = lexemeDup();  
                                 return ID;                                 }

  /************* Comments *********************/

\{                      { commentCaller = YYSTATE;  BEGIN( IN_COMMENT );    }
<IN_COMMENT>[^\n\}]*    { /* Discard comment text */                        }
<IN_COMMENT>\n          { currentLineNumber++;                              }
<IN_COMMENT>\}          { BEGIN( commentCaller );                           }

  /************* Catch Others *****************/

.                       { LOG(logLvl) << "ERROR(" << currentLineNumber
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

