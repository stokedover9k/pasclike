%{

#include <cstdio>
#include <iostream>

using std::cout;
using std::endl;

#include "pasclike.tab.h"

//extern "C" int yylex();
//int yylex();
extern "C" int yylex();
//extern "C" FILE *yyin;

//------- logging settings --------
#include "loglib.h"

#ifndef PARSER_LOG_LVL
#define PARSER_LOG_LVL logDEBUG4
#endif

TLogLevel ParserLog = PARSER_LOG_LVL;
//---------------------------------
//------- output settings ---------
// redirect in main if needed
std::ostream rulesLog(std::cout.rdbuf());
//---------------------------------

int yyerror( const char *p ) { LOG(logERROR) << p; }

%}

%union {
  char *lexeme;
}

%token AND NOT OF OR TO
%token BEGIN_TOKEN FORWARD DO ELSE END_TOKEN FOR IF THEN
%token DIV MOD
%token FUNCTION ARRAY PROCEDURE PROGRAM RECORD TYPE VAR WHILE
%token DOT COMMA COLON SEMICOLON ASSIGN RANGE LPAREN RPAREN LBRACKET RBRACKET
%token PLUS MINUS MULT
%token LE LT GE GT NE EQ

%token <lexeme> INTEGER DECIMAL EXPNUMBER
%token <lexeme> STRING
%token <lexeme> ID

%token <lexeme> ERROR_TOKEN

%%

program : PROGRAM ID SEMICOLON 
          opt_TypeDefs
          opt_VarDecls
          opt_SubprogDecls
          compoundStmt DOT
                                                                          { LOG(ParserLog) << "   Program := program id ; [typeDefs] [varDecls] [subprogDecls] compoundStmt .";
									    rulesLog << "program" << endl;
									  }
        ;
    //============ TYPE DEFINITIONS =====================================
opt_TypeDefs    : typeDefs 
                | /* empty */
                ;
typeDef         : ID EQ type                                              { LOG(ParserLog) << "   typeDef := ID = type ;"; 
                                                                            rulesLog << "type_definition" << endl;
                                                                          }
                ;
typeDefs        : TYPE typeDef SEMICOLON typeDefList                      { LOG(ParserLog) << "   typeDefs := TYPE typeDef ; typeDefList"; 
                                                                            rulesLog << "type_definitions" << endl; }
                ;
typeDefList     : typeDefList typeDef SEMICOLON
                | /* empty */
                ;
    //===================================================================
    //============ VARIABLE DECLARATIONS ================================
opt_VarDecls : varDecls | /* empty */ ;

varDecls     : VAR varDecl SEMICOLON varDeclList                          { LOG(ParserLog) << "   varDecls := VAR varDecl ; varDeclList"; }
             ;
varDeclList  : varDeclList varDecl SEMICOLON                              { rulesLog << "variable_declarations" << endl; }
             | /* empty */
             ;
varDecl      : identifierList COLON type                                  { LOG(ParserLog) << "   varDecl := identifierList : type";
                                                                            rulesLog << "variable_declaration" << endl; }
             ;
    //===================================================================
    //============ SUBPROGRAM DECLARATIONS ==============================
opt_SubprogDecls : subprogDeclList 
                 ;
subprogDeclList  : subprogDeclList procDecl SEMICOLON
                 | subprogDeclList funcDecl SEMICOLON
                 | /* empty */
                 ;
    //===================================================================
procDecl : PROCEDURE ID LPAREN formalParamList RPAREN SEMICOLON block     { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) block"; }
         | PROCEDURE ID LPAREN formalParamList RPAREN SEMICOLON FORWARD   { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) forward"; }
         ;
funcDecl : FUNCTION ID LPAREN formalParamList RPAREN COLON resultType SEMICOLON block
                                                                          { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; block"; }
         | FUNCTION ID LPAREN formalParamList RPAREN COLON resultType SEMICOLON FORWARD
                                                                          { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; forward"; }
         ;
formalParamList     : identifierList COLON type formalParamListTail       { LOG(ParserLog) << "   formalParamList := identifierList : type formalParamListTail"; }
                    | /* empty */
                    ;
formalParamListTail : formalParamListTail SEMICOLON identifierList COLON type
                    | /* empty */
                    ;
actualParamList     : expr actualParamListTail                            { LOG(ParserLog) << "   actualParamList := expr actualParamListTail"; }
                    | /* empty */ 
                    ;
actualParamListTail : actualParamListTail COMMA expr
                    | /* empty */ 
                    ;
block : varDecls compoundStmt                                             { LOG(ParserLog) << "   block := varDecls compoundStmt"; }
      | compoundStmt                                                      { LOG(ParserLog) << "   block := varDecls"; }
      ;
    //============ STATEMENTS ===========================================
stmt                 : closedStmt                                         { LOG(ParserLog) << "   stmt := closedStmt"; }
                     | openStmt                                           { LOG(ParserLog) << "   stmt := openStmt"; }
                     ;
closedStmt           : simpleStmt
                     | closedStructuredStmt
                     ;
openStmt             : openStructuredStmt
                     ;
closedStructuredStmt : compoundStmt                                       { LOG(ParserLog) << "   closeStmt := compoundStmt"; }
                     | loopHeader closedStmt                              { LOG(ParserLog) << "   closeStmt := loopHeader closedStmt"; }
                     | IF expr THEN closedStmt ELSE closedStmt            { LOG(ParserLog) << "   closeStmt := if expr then closedStmt else closedStmt"; }
                     ;
openStructuredStmt   : loopHeader openStmt                                { LOG(ParserLog) << "   openStmt := loopHeader openStmt"; }
                     | IF expr THEN closedStmt ELSE openStmt              { LOG(ParserLog) << "   openStmt := if expr then closedStmt else openStmt"; }
                     | IF expr THEN stmt                                  { LOG(ParserLog) << "   openStmt := if expr then stmt"; }
                     ;
loopHeader           : WHILE expr DO
                     | FOR ID ASSIGN expr TO expr DO
                     ;
simpleStmt           : assignmentStmt                                     { LOG(ParserLog) << "   simpleStmt := assignmentStmt"; }
                     | procedureStmt                                      { LOG(ParserLog) << "   simpleStmt := procedureStmt"; }
                     | /* emtpy */ 
                     ;
assignmentStmt       : variable ASSIGN expr                               { LOG(ParserLog) << "   assignmentStmt := variable := expr"; }
                     ;
procedureStmt        : ID LPAREN actualParamList RPAREN                   { LOG(ParserLog) << "   procedureStmt := id ( actualParamList )"; }
                     ;
compoundStmt         : BEGIN_TOKEN stmtSequence END_TOKEN                 { LOG(ParserLog) << "   compoundStmt := begin stmtSequence end"; }
                     ;
stmtSequence         : stmt stmtSequenceTail                              { LOG(ParserLog) << "   stmtSequence := stmt stmtSequenceTail"; }
stmtSequenceTail     : stmtSequenceTail SEMICOLON stmt
                     | /* empty */
                     ;
    //===================================================================
expr       : simpleExpr relOp simpleExpr                                  { LOG(ParserLog) << "   expr := simpleExpr relOp simpleExpr";  }
           | simpleExpr                                                   { LOG(ParserLog) << "   expr := simpleExpr";  }
           ;
simpleExpr : sign termList                                                { LOG(ParserLog) << "   simpleExpr := sign termList";  }
           |      termList                                                { LOG(ParserLog) << "   simpleExpr := termList";  }
           ;
termList   : termList addOp term
           | term
           ;
term       : factorList                                                   { LOG(ParserLog) << "   term := factorList";  }
           ;
factorList : factorList mulOp factor 
           | factor
           ;
factor     : INTEGER                                                      { LOG(ParserLog) << "   factor := int";  }
           | STRING                                                       { LOG(ParserLog) << "   factor := string";  }
           | variable                                                     { LOG(ParserLog) << "   factor := variable";  }
           | functionReference                                            { LOG(ParserLog) << "   factor := functionReference";  }
           | NOT factor                                                   { LOG(ParserLog) << "   factor := not factor";  }
           | LPAREN expr RPAREN                                           { LOG(ParserLog) << "   factor := ( expr )";  }
           ;
functionReference : ID LPAREN actualParamList RPAREN 
                  ;
addOp  : PLUS                                                             { LOG(ParserLog) << "   addOp := +";    }
       | MINUS                                                            { LOG(ParserLog) << "   addOp := *";    }
       | OR                                                               { LOG(ParserLog) << "   addOp := OR";   }
       ;
mulOp  : MULT                                                             { LOG(ParserLog) << "   mulOp := *";    }
       | DIV                                                              { LOG(ParserLog) << "   mulOp := div";  }
       | MOD                                                              { LOG(ParserLog) << "   mulOp := %";    }
       | AND                                                              { LOG(ParserLog) << "   mulOp := AND";  }
       ;
relOp  : LT                                                               { LOG(ParserLog) << "   relOp := <";    }
       | LE                                                               { LOG(ParserLog) << "   relOp := <=";   }
       | GT                                                               { LOG(ParserLog) << "   relOp := >";    }
       | GE                                                               { LOG(ParserLog) << "   relOp := >=";   }
       | EQ                                                               { LOG(ParserLog) << "   relOp := =";    }
       | NE                                                               { LOG(ParserLog) << "   relOp := <>";   }
       ;
    //===================================================================

fieldList     : identifierList COLON type fieldListTail                   { LOG(ParserLog) << "   filedList := identifierList : type filedListTail";
                                                                            rulesLog << "field_list" << endl; }
              | /* empty */                                               { rulesLog << "field_list(empty)" << endl; }
              ;
fieldListTail : fieldListTail SEMICOLON identifierList COLON type
              | /* empty */
              ;

identifierList     : ID identifierListTail                                { LOG(ParserLog) << "   identifierList := ID identifierListTail"; 
                                                                            rulesLog << "identifier_list" << endl; }
                   ;
identifierListTail : identifierListTail COMMA ID 
                   | /* empty */ 
                   ;

constant           : sign INTEGER                                         { LOG(ParserLog) << "   constant := sign int"; }
                   | INTEGER                                              { LOG(ParserLog) << "   constant := int"; }
                   ;
variable           : ID componentSelection                                { LOG(ParserLog) << "   variable := id componentSelection"; }
                   ;
componentSelection : componentSelection DOT ID                            { LOG(ParserLog) << "   componentSelection := . id componentSelection"; }
                   | componentSelection LBRACKET expr RBRACKET            { LOG(ParserLog) << "   componentSelection := [ expr ] componentSelection"; }
                   | /* empty */ 
                   ;

sign : PLUS | MINUS ;

type : ID                                                                 { LOG(ParserLog) << "   type := ID"; 
                                                                            rulesLog << "type_ID" << endl;    }
     | ARRAY LBRACKET constant RANGE constant RBRACKET OF type            { LOG(ParserLog) << "   type := ARRAY [ constant .. constant ] of type";
                                                                            rulesLog << "type_ARRAY" << endl;    }
     | RECORD fieldList END_TOKEN                                         { LOG(ParserLog) << "   type := RECORD fieldList END";
                                                                            rulesLog << "type_RECORD" << endl;    }
     ;

resultType : ID                                                           { LOG(ParserLog) << "   resultType := id"; }
           ;
%%
