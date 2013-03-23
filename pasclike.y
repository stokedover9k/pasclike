%{

#include <cstdio>
#include <iostream>
#include <sstream>
#include <list>

using std::cout;
using std::endl;

#include "pasclike.tab.h"

extern "C" int yylex();

//------- logging settings --------
#include "loglib.h"

#ifndef PARSER_LOG_LVL
#define PARSER_LOG_LVL logDEBUG4
#endif

TLogLevel ParserLog = PARSER_LOG_LVL;
//---------------------------------
//------- output settings ---------
#include "parser-settings.h"
//---------------------------------
//------- symbol table ------------
#include "symbol-table.h"
//---------------------------------

int yyerror( const char *p ) { LOG(logERROR) << p; }

 void setIdListToType( attributes const& symbol, char const *type )
 {
   for( std::string const& id : *symbol.syn->strList )
     addSymbol( id, std::string(type) );
 }

 void cleanUpIdList( attributes const& symbol )
 {
   delete symbol.syn->strList;
   delete symbol.syn;
 }

 std::string numToString( int num )
   {
     std::stringstream ss;
     ss << num;
     return std::string( ss.str() );
   }
%}

%code requires {
  #include <list>

  #ifndef __ATTRIB_STRUCTS_DEF__
  #define __ATTRIB_STRUCTS_DEF__
  struct attrib {
    std::list<std::string> *strList;
    int num;
  };
  struct attributes {
    attrib *syn;
    attrib *inh;
  };
  #endif//__ATTRIB_STRUCTS_DEF__
}

%union {
  char const *lexeme;
  struct attributes attr;
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

program 
   : PROGRAM ID SEMICOLON 
     opt_TypeDefs
     opt_VarDecls
     opt_SubprogDecls
     compoundStmt DOT
                                { LOG(ParserLog) << "   Program := program id ; [typeDefs] [varDecls] [subprogDecls] compoundStmt .";
				  rulesLog << "program" << endl;
				}
        ;
    //============ TYPE DEFINITIONS =====================================
opt_TypeDefs
   : typeDefs 
   | /* EMPTY */
   ;
typeDef
   : ID EQ type                                 { LOG(ParserLog) << "   typeDef := ID = type ;";
                                                  addSymbol( std::string($1), std::string($<lexeme>3) );
                                                  rulesLog << "type_definition" << endl; }
   ;
typeDefs
   : TYPE typeDef SEMICOLON typeDefList         { LOG(ParserLog) << "   typeDefs := TYPE typeDef ; typeDefList"; 
                                                  rulesLog << "type_definitions" << endl; }
   ;
typeDefList
   : typeDefList typeDef SEMICOLON              { LOG(ParserLog) << "   typeDefList := typeDefList typeDef ;"; 
                                                  rulesLog << "type_definitions_more" << endl; }
   | /* empty */
   ;
    //===================================================================
    //============ VARIABLE DECLARATIONS ================================
opt_VarDecls 
   : varDecls
   | /* empty */ 
   ;
varDecls
   : VAR varDecl SEMICOLON varDeclList          { LOG(ParserLog) << "   varDecls := VAR varDecl ; varDeclList"; }
   ;
varDeclList
   : varDeclList varDecl SEMICOLON              { rulesLog << "variable_declarations" << endl; }
   | /* empty */
   ;
varDecl
   : identifierList COLON type                  { LOG(ParserLog) << "   varDecl := identifierList : type";
                                                  rulesLog << "variable_declaration" << endl;

						  setIdListToType( $<attr>1, $<lexeme>3 );
						  cleanUpIdList( $<attr>1 );
                                                }
   ;
    //===================================================================
    //============ SUBPROGRAM DECLARATIONS ==============================
opt_SubprogDecls
   : subprogDeclList 
   ;
subprogDeclList
   : subprogDeclList procDecl SEMICOLON
   | subprogDeclList funcDecl SEMICOLON
   | /* empty */
   ;
    //===================================================================
procDecl 
   : PROCEDURE ID LPAREN formalParamList RPAREN SEMICOLON block                     { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) block"; 
                                                                                      addSymbol( std::string($<lexeme>2), numToString( $<attr>4.syn->num ) );
										      delete $<attr>4.syn;
                                                                                    }
   | PROCEDURE ID LPAREN formalParamList RPAREN SEMICOLON FORWARD                   { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) forward";
                                                                                      addSymbol( std::string($<lexeme>2), numToString( $<attr>4.syn->num ) );
										      delete $<attr>4.syn;
                                                                                    }
   ;
funcDecl
   : FUNCTION ID LPAREN formalParamList RPAREN COLON resultType SEMICOLON block     { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; block";
                                                                                      addSymbol( std::string($<lexeme>2), numToString( $<attr>4.syn->num ) );
										      delete $<attr>4.syn;
                                                                                    }
   | FUNCTION ID LPAREN formalParamList RPAREN COLON resultType SEMICOLON FORWARD   { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; forward";
                                                                                      addSymbol( std::string($<lexeme>2), numToString( $<attr>4.syn->num ) );
										      delete $<attr>4.syn;
                                                                                    }
   ;
formalParamList
   : identifierList COLON type formalParamListTail        { LOG(ParserLog) << "   formalParamList := identifierList : type formalParamListTail"; 
                                                            $<attr>$.syn = $<attr>4.syn;  // steal number attribut from tail
							    $<attr>$.syn->num += $<attr>1.syn->strList->size();
							    setIdListToType( $<attr>1, $<lexeme>3 );
							    cleanUpIdList( $<attr>1 );
                                                          }
   | /* empty */                                          { $<attr>$.syn = new attrib;   $<attr>$.syn->num = 0; }
   ;
formalParamListTail
   : formalParamListTail SEMICOLON identifierList COLON type     { $<attr>$.syn = $<attr>1.syn;  // steal number attribute from head of tail
                                                                   $<attr>$.syn->num += $<attr>3.syn->strList->size();
								   setIdListToType( $<attr>3, $<lexeme>5 );
								   cleanUpIdList( $<attr>3 ); 
                                                                 }
   | /* empty */                                                 { $<attr>$.syn = new attrib;   $<attr>$.syn->num = 0; }
   ;
actualParamList
   : expr actualParamListTail                                                       { LOG(ParserLog) << "   actualParamList := expr actualParamListTail"; }
   | /* empty */ 
   ;
actualParamListTail
   : actualParamListTail COMMA expr
   | /* empty */ 
   ;
block
   : varDecls compoundStmt                                                          { LOG(ParserLog) << "   block := varDecls compoundStmt"; }
   | compoundStmt                                                                   { LOG(ParserLog) << "   block := varDecls"; }
   ;
    //============ STATEMENTS ===========================================
stmt
   : closedStmt                                         { LOG(ParserLog) << "   stmt := closedStmt"; }
   | openStmt                                           { LOG(ParserLog) << "   stmt := openStmt"; }
   ;
closedStmt
   : simpleStmt
   | closedStructuredStmt
   ;
openStmt
   : openStructuredStmt
   ;
closedStructuredStmt
   : compoundStmt                                       { LOG(ParserLog) << "   closeStmt := compoundStmt"; }
   | loopHeader closedStmt                              { LOG(ParserLog) << "   closeStmt := loopHeader closedStmt"; }
   | IF expr THEN closedStmt ELSE closedStmt            { LOG(ParserLog) << "   closeStmt := if expr then closedStmt else closedStmt"; }
   ;
openStructuredStmt
   : loopHeader openStmt                                { LOG(ParserLog) << "   openStmt := loopHeader openStmt"; }
   | IF expr THEN closedStmt ELSE openStmt              { LOG(ParserLog) << "   openStmt := if expr then closedStmt else openStmt"; }
   | IF expr THEN stmt                                  { LOG(ParserLog) << "   openStmt := if expr then stmt"; }
   ;
loopHeader
   : WHILE expr DO
   | FOR ID ASSIGN expr TO expr DO
   ;
simpleStmt
   : assignmentStmt                                     { LOG(ParserLog) << "   simpleStmt := assignmentStmt"; }
   | procedureStmt                                      { LOG(ParserLog) << "   simpleStmt := procedureStmt"; }
   | /* emtpy */ 
   ;
assignmentStmt
   : variable ASSIGN expr                               { LOG(ParserLog) << "   assignmentStmt := variable := expr"; }
   ;
procedureStmt
   : ID LPAREN actualParamList RPAREN                   { LOG(ParserLog) << "   procedureStmt := id ( actualParamList )"; }
   ;
compoundStmt
   : BEGIN_TOKEN stmtSequence END_TOKEN                 { LOG(ParserLog) << "   compoundStmt := begin stmtSequence end"; }
   ;
stmtSequence
   : stmt stmtSequenceTail                              { LOG(ParserLog) << "   stmtSequence := stmt stmtSequenceTail"; }
   ;
stmtSequenceTail
   : stmtSequenceTail SEMICOLON stmt
   | /* empty */
   ;
    //===================================================================
expr
   : simpleExpr relOp simpleExpr                                  { LOG(ParserLog) << "   expr := simpleExpr relOp simpleExpr";  }
   | simpleExpr                                                   { LOG(ParserLog) << "   expr := simpleExpr";  }
   ;
simpleExpr
   : sign termList                                                { LOG(ParserLog) << "   simpleExpr := sign termList";  }
   |      termList                                                { LOG(ParserLog) << "   simpleExpr := termList";  }
   ;
termList
   : termList addOp term
   | term
   ;
term
   : factorList                                                   { LOG(ParserLog) << "   term := factorList";  }
   ;
factorList
   : factorList mulOp factor 
   | factor
   ;
factor
   : INTEGER                                                      { LOG(ParserLog) << "   factor := int";  }
   | STRING                                                       { LOG(ParserLog) << "   factor := string";  }
   | variable                                                     { LOG(ParserLog) << "   factor := variable";  }
   | functionReference                                            { LOG(ParserLog) << "   factor := functionReference";  }
   | NOT factor                                                   { LOG(ParserLog) << "   factor := not factor";  }
   | LPAREN expr RPAREN                                           { LOG(ParserLog) << "   factor := ( expr )";  }
   ;
functionReference
   : ID LPAREN actualParamList RPAREN 
   ;
addOp
   : PLUS                                                             { LOG(ParserLog) << "   addOp := +";    }
   | MINUS                                                            { LOG(ParserLog) << "   addOp := *";    }
   | OR                                                               { LOG(ParserLog) << "   addOp := OR";   }
   ;
mulOp
   : MULT                                                             { LOG(ParserLog) << "   mulOp := *";    }
   | DIV                                                              { LOG(ParserLog) << "   mulOp := div";  }
   | MOD                                                              { LOG(ParserLog) << "   mulOp := %";    }
   | AND                                                              { LOG(ParserLog) << "   mulOp := AND";  }
   ;
relOp
   : LT                                                               { LOG(ParserLog) << "   relOp := <";    }
   | LE                                                               { LOG(ParserLog) << "   relOp := <=";   }
   | GT                                                               { LOG(ParserLog) << "   relOp := >";    }
   | GE                                                               { LOG(ParserLog) << "   relOp := >=";   }
   | EQ                                                               { LOG(ParserLog) << "   relOp := =";    }
   | NE                                                               { LOG(ParserLog) << "   relOp := <>";   }
   ;
    //===================================================================

fieldList
   : identifierList COLON type fieldListTail              { LOG(ParserLog) << "   filedList := identifierList : type filedListTail";
                                                            rulesLog << "field_list" << endl; 
							    setIdListToType( $<attr>1, $<lexeme>3 );
							    cleanUpIdList( $<attr>1 );
                                                          }
   | /* empty */                                          { rulesLog << "field_list(empty)" << endl; }
   ;
fieldListTail
   : fieldListTail SEMICOLON identifierList COLON type    { setIdListToType( $<attr>3, $<lexeme>5 );
							    cleanUpIdList( $<attr>3 );
                                                          }
   | /* empty */
   ;

    // NOTE: identifierList must be cleaned up after it's used.  
    // Call cleanUpIdList( $<attr>n ); which is equivalent to "delete $<attr>n.syn->strList;  delete $<attr>n.syn;"
identifierList
   : ID identifierListTail                                { LOG(ParserLog) << "   identifierList := ID identifierListTail"; 
                                                            rulesLog << "identifier_list" << endl; 
							    $<attr>$.syn = $<attr>2.syn;  // reuse existing YYSTYPE from list tail
							    $<attr>$.syn->strList->push_front( std::string($<lexeme>1) );
                                                          }
   ;
identifierListTail
    : identifierListTail COMMA ID                         { $<attr>$.syn = $<attr>1.syn;                                   // reuse existing YYSTYPE from $1
							    $<attr>$.syn->strList->push_front( std::string($<lexeme>3) );  // add new id to the list
                                                          }
    | /* empty */                                         { $<attr>$.syn = new attrib;
                                                            $<attr>$.syn->strList = new std::list<std::string>();
                                                          }
    ;
constant
   : sign INTEGER                                         { LOG(ParserLog) << "   constant := sign int"; }
   | INTEGER                                              { LOG(ParserLog) << "   constant := int"; }
   ;
variable
   : ID componentSelection                                { LOG(ParserLog) << "   variable := id componentSelection"; }
   ;
componentSelection
   : componentSelection DOT ID                            { LOG(ParserLog) << "   componentSelection := . id componentSelection"; }
   | componentSelection LBRACKET expr RBRACKET            { LOG(ParserLog) << "   componentSelection := [ expr ] componentSelection"; }
   | /* empty */ 
   ;
sign : PLUS | MINUS ;

type
   : ID                                                       { LOG(ParserLog) << "   type := ID"; 
                                                                rulesLog << "type_ID" << endl;
								$<lexeme>$ = $1;
                                                              }
   | ARRAY LBRACKET constant RANGE constant RBRACKET OF type  { LOG(ParserLog) << "   type := ARRAY [ constant .. constant ] of type";
                                                                rulesLog << "type_ARRAY" << endl;
								$<lexeme>$ = "array";
                                                              }
   | RECORD fieldList END_TOKEN                               { LOG(ParserLog) << "   type := RECORD fieldList END";
                                                                rulesLog << "type_RECORD" << endl;
								$<lexeme>$ = "record";
                                                              }
   ;

resultType
   : ID                                                       { LOG(ParserLog) << "   resultType := id"; }
   ;
%%

