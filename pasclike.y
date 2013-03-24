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
//#include "symbol-table.h"
//---------------------------------

int yyerror( const char *p ) { LOG(logERROR) << p; }

 void setIdListToType( id_list_attributes const& id_list, symbol_attributes const& type )
 {
   for( Sym_table::Index_type const& id : *id_list.symbols )
     sym_table.set_type( id, type.id );
 }

 void cleanUpIdList( id_list_attributes const& id_list )
 {
   delete id_list.symbols;
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
  #include "symbol-table.h"

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
  struct symbol_attributes {
    Sym_table::Index_type id;
    attrib *syn;
  };
  struct id_list_attributes {
    std::list<Sym_table::Index_type> *symbols;
  };
  #endif//__ATTRIB_STRUCTS_DEF__
}

%union {
  char const *lexeme;
  struct symbol_attributes symbol;
  struct id_list_attributes id_list;
  struct attributes attr;
}

%token AND NOT OF OR TO
%token BEGIN_TOKEN FORWARD DO ELSE END_TOKEN FOR IF THEN
%token DIV MOD
%token FUNCTION ARRAY PROCEDURE PROGRAM RECORD TYPE VAR WHILE
%token LE LT GE GT NE EQ

%token ASSIGN RANGE 

%token <lexeme> INTEGER DECIMAL EXPNUMBER
%token <lexeme> STRING
%token <symbol> ID

%token <lexeme> ERROR_TOKEN

%type <id_list> formalParamList formalParamListTail identifierList identifierListTail
%type <symbol> type

%%

program 
   : PROGRAM ID ';' 
     opt_TypeDefs
     opt_VarDecls
     opt_SubprogDecls
     compoundStmt '.'
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
   : ID EQ type                        { LOG(ParserLog) << "   typeDef := ID = type ;";
                                         sym_table.set_type( $1.id, $3.id );
					 rulesLog << "type_definition" << endl; }
   ;
typeDefs
   : TYPE typeDef ';' typeDefList      { LOG(ParserLog) << "   typeDefs := TYPE typeDef ; typeDefList"; 
                                         rulesLog << "type_definitions" << endl; }
   ;
typeDefList
   : typeDefList typeDef ';'           { LOG(ParserLog) << "   typeDefList := typeDefList typeDef ;"; 
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
   : VAR varDecl ';' varDeclList       { LOG(ParserLog) << "   varDecls := VAR varDecl ; varDeclList"; }
   ;
varDeclList
   : varDeclList varDecl ';'           { rulesLog << "variable_declarations" << endl; }
   | /* empty */
   ;
varDecl
   : identifierList ':' type           { LOG(ParserLog) << "   varDecl := identifierList : type";
                                         rulesLog << "variable_declaration" << endl;
					 setIdListToType( $1, $3 );
					 cleanUpIdList( $1 ); }
   ;
    //===================================================================
    //============ SUBPROGRAM DECLARATIONS ==============================
opt_SubprogDecls
   : subprogDeclList 
   ;
subprogDeclList
   : subprogDeclList procDecl ';'
   | subprogDeclList funcDecl ';'
   | /* empty */
   ;
procDecl 
   : PROCEDURE ID '(' formalParamList ')' ';' block                    { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) block"; 
									 sym_table.set_routine_type( $2.id, $4.symbols->size() );
									 cleanUpIdList( $4 ); }
   | PROCEDURE ID '(' formalParamList ')' ';' FORWARD                  { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) forward";
									 sym_table.set_routine_type( $2.id, $4.symbols->size() );
									 cleanUpIdList( $4 ); }
   ;
funcDecl
   : FUNCTION ID '(' formalParamList ')' ':' resultType ';' block      { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; block";
									 sym_table.set_routine_type( $2.id, $4.symbols->size() );
									 cleanUpIdList( $4 ); }
   | FUNCTION ID '(' formalParamList ')' ':' resultType ';' FORWARD    { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; forward";
									 sym_table.set_routine_type( $2.id, $4.symbols->size() );
									 cleanUpIdList( $4 ); }
   ;
formalParamList
   : identifierList ':' type formalParamListTail          { LOG(ParserLog) << "   formalParamList := identifierList : type formalParamListTail"; 
                                                            $$.symbols = $4.symbols;         // steal symbol list from tail
							    $$.symbols->insert( $$.symbols->begin(), $1.symbols->begin(), $1.symbols->end() );
							    setIdListToType( $1, $3 );
							    cleanUpIdList( $1 ); }
   | /* empty */                                          { $$.symbols = new std::list<Sym_table::Index_type>(); }
   ;
formalParamListTail
   : formalParamListTail ';' identifierList ':' type      { $$.symbols = $1.symbols;      // steal symbol list from head of tail
                                                            // insert all ids from identifierList into the paramList
                                                            $$.symbols->insert( $$.symbols->end(), $3.symbols->begin(), $3.symbols->end() );  
							    setIdListToType( $3, $5 );
							    cleanUpIdList( $3 ); }
   | /* empty */                                          { $$.symbols = new std::list<Sym_table::Index_type>(); }
   ;
actualParamList
   : expr actualParamListTail                             { LOG(ParserLog) << "   actualParamList := expr actualParamListTail"; }
   | /* empty */ 
   ;
actualParamListTail
   : actualParamListTail ',' expr
   | /* empty */ 
   ;
block
   : varDecls compoundStmt                                { LOG(ParserLog) << "   block := varDecls compoundStmt"; }
   | compoundStmt                                         { LOG(ParserLog) << "   block := varDecls"; }
   ;
    //===================================================================
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
   : ID '(' actualParamList ')'                         { LOG(ParserLog) << "   procedureStmt := id ( actualParamList )"; }
   ;
compoundStmt
   : BEGIN_TOKEN stmtSequence END_TOKEN                 { LOG(ParserLog) << "   compoundStmt := begin stmtSequence end"; }
   ;
stmtSequence
   : stmt stmtSequenceTail                              { LOG(ParserLog) << "   stmtSequence := stmt stmtSequenceTail"; }
   ;
stmtSequenceTail
   : stmtSequenceTail ';' stmt
   | /* empty */
   ;
    //===================================================================
expr
   : simpleExpr relOp simpleExpr      { LOG(ParserLog) << "   expr := simpleExpr relOp simpleExpr";  }
   | simpleExpr                       { LOG(ParserLog) << "   expr := simpleExpr";  }
   ;
simpleExpr
   : sign termList                    { LOG(ParserLog) << "   simpleExpr := sign termList";  }
   |      termList                    { LOG(ParserLog) << "   simpleExpr := termList";  }
   ;
termList
   : termList addOp term
   | term
   ;
term
   : factorList                       { LOG(ParserLog) << "   term := factorList";  }
   ;
factorList
   : factorList mulOp factor 
   | factor
   ;
factor
   : INTEGER                          { LOG(ParserLog) << "   factor := int";  }
   | STRING                           { LOG(ParserLog) << "   factor := string";  }
   | variable                         { LOG(ParserLog) << "   factor := variable";  }
   | functionReference                { LOG(ParserLog) << "   factor := functionReference";  }
   | NOT factor                       { LOG(ParserLog) << "   factor := not factor";  }
   | '(' expr ')'                     { LOG(ParserLog) << "   factor := ( expr )";  }
   ;
functionReference
   : ID '(' actualParamList ')' 
   ;
addOp
   : '+'                              { LOG(ParserLog) << "   addOp := +";    }
   | '-'                              { LOG(ParserLog) << "   addOp := *";    }
   | OR                               { LOG(ParserLog) << "   addOp := OR";   }
   ;
mulOp
   : '*'                              { LOG(ParserLog) << "   mulOp := *";    }
   | DIV                              { LOG(ParserLog) << "   mulOp := div";  }
   | MOD                              { LOG(ParserLog) << "   mulOp := %";    }
   | AND                              { LOG(ParserLog) << "   mulOp := AND";  }
   ;
relOp
   : LT                               { LOG(ParserLog) << "   relOp := <";    }
   | LE                               { LOG(ParserLog) << "   relOp := <=";   }
   | GT                               { LOG(ParserLog) << "   relOp := >";    }
   | GE                               { LOG(ParserLog) << "   relOp := >=";   }
   | EQ                               { LOG(ParserLog) << "   relOp := =";    }
   | NE                               { LOG(ParserLog) << "   relOp := <>";   }
   ;
    //===================================================================

fieldList
   : identifierList ':' type fieldListTail            { LOG(ParserLog) << "   filedList := identifierList : type filedListTail";
                                                        rulesLog << "field_list" << endl; 
							setIdListToType( $1, $3 );
							cleanUpIdList( $1 ); }
   | /* empty */                                      { rulesLog << "field_list(empty)" << endl; }
   ;
fieldListTail
   : fieldListTail ';' identifierList ':' type        { setIdListToType( $3, $5 );
							cleanUpIdList( $3 ); }
   | /* empty */
   ;

    // NOTE: identifierList must be cleaned up after it's used.  
    // Call cleanUpIdList( $n ); which is equivalent to "delete $<id_list>n.symbols;"
identifierList
   : ID identifierListTail                            { LOG(ParserLog) << "   identifierList := ID identifierListTail"; 
                                                        rulesLog << "identifier_list" << endl; 
							$$.symbols = $2.symbols;                                 // reuse existing list of ids
							$$.symbols->push_front( $1.id ); }
   ;
identifierListTail
    : identifierListTail ',' ID                       { $$.symbols = $1.symbols;                                 // reuse existing list of ids
						        $$.symbols->push_front( $3.id ); }                       // add new id to the list
    | /* empty */                                     { $$.symbols = new std::list<Sym_table::Index_type>(); }   // create new (empty) list of ids
    ;
constant
   : sign INTEGER                                     { LOG(ParserLog) << "   constant := sign int"; }
   | INTEGER                                          { LOG(ParserLog) << "   constant := int"; }
   ;
variable
   : ID componentSelection                            { LOG(ParserLog) << "   variable := id componentSelection"; }
   ;
componentSelection
   : componentSelection '.' ID                        { LOG(ParserLog) << "   componentSelection := . id componentSelection"; }
   | componentSelection '[' expr ']'                  { LOG(ParserLog) << "   componentSelection := [ expr ] componentSelection"; }
   | /* empty */ 
   ;
sign : '+' | '-' ;

type
   : ID                                               { LOG(ParserLog) << "   type := ID"; 
							$$.id = $1.id; }
   | ARRAY '[' constant RANGE constant ']' OF type    { LOG(ParserLog) << "   type := ARRAY [ constant .. constant ] of type";
							$$.id = sym_table.put("array"); }
   | RECORD fieldList END_TOKEN                       { LOG(ParserLog) << "   type := RECORD fieldList END";
							$$.id = sym_table.put("record"); }
   ;

resultType
   : ID                                               { LOG(ParserLog) << "   resultType := id"; }
   ;
%%

