%{

#include <cstdio>
#include <iostream>

using std::cout;
using std::endl;

#include "pasclike.tab.h"

//extern "C" int yylex();
int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;

int yyerror( const char *p ) { std::cerr << "error: " << p << std::endl; }

%}

%union {
  char *lexeme;
}

%token AND NOT OF OR TO
%token BEGIN_TOKEN FORWARD DO ELSE END_TOKEN FOR IF THEN
%token DIV MOD
%token FUNCTION ARRAY PROCEDURE PROGRAM RECORD TYPE VAR WHILE
%token <lexeme> RELOP
%token DOT COMMA COLON SEMICOLON ASSIGN RANGE LPAREN RPAREN LBRACKET RBRACKET
%token PLUS MINUS MULT DIVIDE

%token <lexeme> INTEGER DECIMAL EXPNUMBER
%token <lexeme> STRING
%token <lexeme> ID

%token <lexeme> ERROR_TOKEN

%%

prog : ;

%%
