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
#include "symtable.h"

 symdb::Sym_table symtable;
 symdb::Invalid_type *invalid_type = new symdb::Invalid_type();
 cgen::Tmp_gen tmp_gen;
 std::ostream& codeout(std::cout);
//---------------------------------

int yyerror( const char *p ) { ERRLOG << p; }

// This is meant to be a private method. Use the drivers following this definition;
// Adds new Vars to a list pointed to by add_to before the add_position.
// If add_to != NULL && add_position == NULL, add_position is set add_to->end().
// If add_to == NULL, vars are not added to a list.
 bool _makeVarsOfType( std::list<std::string> const *ids, symdb::Type *type,
		       bool add_to_list = false,
		       std::list<symdb::Var*> *add_to = NULL,
		       std::list<symdb::Var*>::iterator add_position = std::list<symdb::Var*>::iterator() ) {
   bool success = true;
   for( std::list<std::string>::const_iterator id( ids->begin() ); id != ids->end(); id++ ) {
     symdb::Var *v = new symdb::Var( *id, type );
     symtable.put( v );
     if( ! symtable.put_success() ) {
       ERRLOG << "cannot enter variable into symbol table: " << id->c_str();
       success = false; 
       delete v;
       v = NULL; }
     if( add_to_list ) {
       add_to->insert( add_position, v ); } }
   return success;
 }

 bool makeVarsOfType( std::list<std::string> const *ids, symdb::Type *type ) {
   return _makeVarsOfType( ids, type, false ); }

 bool makeVarsOfType( std::list<std::string> const *ids, symdb::Type *type, 
		      std::list<symdb::Var*> *add_to ) {
   if( add_to == NULL )    return _makeVarsOfType( ids, type, false );
   else                    return _makeVarsOfType( ids, type, true, add_to, add_to->end() ); }		      

 bool makeVarsOfType( std::list<std::string> const *ids, symdb::Type *type, 
		      std::list<symdb::Var*> *add_to,
		      std::list<symdb::Var*>::iterator add_position ) {
   if( add_to == NULL )    return _makeVarsOfType( ids, type, false );
   else                    return _makeVarsOfType( ids, type, true, add_to, std::move(add_position) ); }

 symdb::Type * type_equivalence( symdb::Type *t1, symdb::Type *t2 ) {
   t1 = t1->get_type();
   t2 = t2->get_type();
   if( ! t1->is_valid() ) return t1;
   if( ! t2->is_valid() ) return t2;
   if( t1 == t2 )
     return t1;
   if( t1->get_type_tag() != t2->get_type_tag() )
     return NULL;
   if( t1->is_array() ) {
     symdb::Array_type *a1 = dynamic_cast<symdb::Array_type*>(t1);
     symdb::Array_type *a2 = dynamic_cast<symdb::Array_type*>(t2);
     return ( a1->range != a2->range ? NULL : NULL == type_equivalence(a1->base_type, a2->base_type) ? NULL : a1 );
   }
   else if( t1->is_record() ) {  // does not rely on default
     symdb::Record_type *r1 = dynamic_cast<symdb::Record_type*>(t1);
     symdb::Record_type *r2 = dynamic_cast<symdb::Record_type*>(t2);
     for( int n = 0; n < 2; n++ ) { // do twice: r1,r2 and r2,r1
       for( symdb::Sym_scope::Sym_map::const_iterator i( r1->scope->begin() );
	    i != r1->scope->end();  i++ ) {
	 symdb::Sym_entry const *entry1 = &i->second;
	 if( entry1->tag != symdb::VAR_TAG )  
	   continue;

	 symdb::Sym_entry *entry2 = r2->scope->get_sym( i->second.sym );
	 if( entry2 == NULL )
	   return NULL;
	 if( entry2->tag != symdb::VAR_TAG )
	   return NULL;

	 if( entry1->offset != entry2->offset )
	   return NULL;

	 symdb::Type *et1 = dynamic_cast<symdb::Var*>(entry1->sym)->type;
	 symdb::Type *et2 = dynamic_cast<symdb::Var*>(entry2->sym)->type;
	 if( type_equivalence( et1, et2 ) == NULL )
	   return NULL;
       }
       symdb::Record_type *tmp = r1;  r1 = r2;  r2 = tmp;
     }
     return t1->get_type();
   }
   return t1->get_type();
 }

 // t1 = NULL for unary (preceding) operators
 // t2 = NULL for unary (following) operators
 // If one of the types is Invalid_type, returns Invalid_type.
 // If operator is undefined for the given type(s), returns NULL.
 // If operator is defined for the given type(s), returns the result of the operator.
 symdb::Type * result_of_op( symdb::Type *t1, Op_tag op, symdb::Type *t2 = NULL )
 {
   static symdb::Type *invalid = new symdb::Invalid_type();
   static symdb::Type *bool_type = new symdb::Bool_type();
   if( t1 == NULL && t2 == NULL )  return invalid;
   if( t1 != NULL ) { 
     if( ! t1->is_valid() )    return invalid;

     if( t2 != NULL ) { //======= t1 op t2 ======
       if( ! t2->is_valid() )  return invalid;

       if( t1->is_int() && t2->is_int() ) {   // int op int

	 if( type_equivalence( t1, t2 ) ) {   // a' == a'   or    a' != a'
	   if( op == EQ_OP || op == NE_OP )
	     return bool_type;
	 }

	 switch( op ) {
	 case PLUS_OP:
	 case MINUS_OP:
	 case TIMES_OP:
	 case INT_DIV_OP:
	 case MOD_OP:       return t1->get_type();
	 case LT_OP:
	 case LE_OP:
	 case GT_OP:
	 case GE_OP:        return bool_type;
	 default:           return NULL;
	 }
       }
       if( t1->is_bool() && t2->is_bool() ) {  // bool op bool
	 switch( op ) {
	 case OR_OP:
	 case AND_OP:       return t1->get_type();
	 default:           return NULL;
	 }
       }
     } 
     else {  //====== t1 op =======

     }
   }
   else {  //====== op t2 =====
     if( ! t2->is_valid() )  return invalid;

     if( t2->is_bool() ) {  // op bool
       switch( op ) {
       case NOT_OP:   return t2->get_type();
       default:       return NULL;
       }
     }
     else if( t2->is_int() ) {  // op int
       switch( op ) {
       case MINUS_OP:
       case PLUS_OP:  return t2->get_type();
       default:       return NULL;
       }
     }
   }
 }

 char const *op_to_string( Op_tag op ) {
   switch(op) {
   case LT_OP:       return "<";
   case LE_OP:       return "<=";
   case GT_OP:       return ">";
   case GE_OP:       return ">=";
   case EQ_OP:       return "=";
   case NE_OP:       return "<>";
   case PLUS_OP:     return "+";
   case MINUS_OP:    return "-";
   case TIMES_OP:    return "*";
   case INT_DIV_OP:  return "div";
   case MOD_OP:      return "mod";
   case AND_OP:      return "AND";
   case OR_OP:       return "OR";
   case NOT_OP:      return "NOT";
   default:          return "N/A";
   }
 }

 std::string numToString( int num )
   {
     std::stringstream ss;
     ss << num;
     return std::string( ss.str() );
   }

 cgen::Addr * create_addr( symdb::Type * t )   { return new cgen::Addr( tmp_gen.gen_tmp(), t ); }
 cgen::Addr * create_addr( symdb::Var  * v )   { return new cgen::Addr( v ); }

 cgen::Addr * resolve_addr( cgen::Addr * a ) {
   cgen::Op::Opcode op;
   cgen::Addr *addr;
   cgen::Addr *resolution;

   switch( a->get_resolution_type() )
     {
     case cgen::Addr::NONE:
       return a;
     case cgen::Addr::INDEX:
       op = cgen::Op::COPY_INDEXED;
       addr = new cgen::Addr( tmp_gen.gen_tmp(), a->get_type() );
       resolution = a->get_index();
       break;
     case cgen::Addr::FIELD:
       op = cgen::Op::COPY_COMPONENT;
       addr = new cgen::Addr( tmp_gen.gen_tmp(), a->get_type() );
       resolution = a->get_field();
       break;
     default:
       throw std::invalid_argument("Unknown type of address resolution.");
     }

   cgen::Instr instr(cgen::Op::COPY, a, NULL, addr);
   codeout << instr;
   return instr.res;
 }

 %}

%code requires {
  #include <list>
  #include "symtable.h"
  #include "inter-code-gen.h"

  extern symdb::Sym_table symtable;

  #ifndef __ATTRIB_STRUCTS_DEF__
  #define __ATTRIB_STRUCTS_DEF__
  enum Op_tag { LT_OP, LE_OP, GT_OP, GE_OP, EQ_OP, NE_OP,
		/* + */ PLUS_OP, /* - */ MINUS_OP,
		/* * */ TIMES_OP, /* div */ INT_DIV_OP, /* mod */ MOD_OP,
		/* and */ AND_OP, /* or */ OR_OP, /* not */ NOT_OP
  };
  #endif//__ATTRIB_STRUCTS_DEF__
}

%union {
  cgen::Addr *addr;
  char const *lexeme;
  symdb::Type *type;
  symdb::Var *var;
  std::list<std::string> *ids;
  std::list<symdb::Var*> *vars;
  std::list<symdb::Sym*> *syms;
  std::list<symdb::Type*> *types;
  symdb::Func *func;
  symdb::Proc *proc;
  symdb::Lit *lit;
  bool success;
  Op_tag op;
}

%token AND NOT OF OR TO
%token BEGIN_TOKEN FORWARD DO ELSE END_TOKEN FOR IF THEN
%token DIV MOD
%token FUNCTION ARRAY PROCEDURE PROGRAM RECORD TYPE VAR WHILE
%token LE LT GE GT NE EQ

%token ASSIGN RANGE 

%token <lexeme> ID
%token <lit> INTEGER DECIMAL EXPNUMBER STRING
%token <lexeme> ERROR_TOKEN



%type <vars> formalParamList formalParamListTail
%type <vars> fieldList fieldListTail

%type <ids> identifierList identifierListTail

%type <addr> variable componentSelection

%type <type> type resultType 
%type <type> factor factorList term termList expr simpleExpr
%type <types> actualParamList actualParamListTail

%type <func> funcDecl funcSignature functionReference
%type <proc> procDecl procSignature
%type <lit> constant
%type <op> relOp addOp mulOp sign

%%

program 
   : PROGRAM ID ';' 
     opt_TypeDefs
     opt_VarDecls
     opt_SubprogDecls
     compoundStmt '.'
                        { LOG(ParserLog) << "   Program := program id ; [typeDefs] [varDecls] [subprogDecls] compoundStmt .";
			}
        ;
    //============ TYPE DEFINITIONS =====================================
opt_TypeDefs
   : typeDefs 
   | /* EMPTY */
   ;
typeDef
   : ID EQ type                        { LOG(ParserLog) << "   typeDef := ID = type ;";
                                         symdb::Named_type *t = new symdb::Named_type($1);
					 t->refers_to = $3->get_type();
					 symtable.put( t );
					 if( ! symtable.put_success() ) {
					   ERRLOG << "failed to add type name: " << $1;
					   delete t; } }
   ;
typeDefs
   : TYPE typeDef ';' typeDefList      { LOG(ParserLog) << "   typeDefs := TYPE typeDef ; typeDefList"; }
   ;
typeDefList
   : typeDefList typeDef ';'           { LOG(ParserLog) << "   typeDefList := typeDefList typeDef ;"; }
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
   : varDeclList varDecl ';'
   | /* empty */
   ;
varDecl
   : identifierList ':' type           { LOG(ParserLog) << "   varDecl := identifierList : type";
                                         makeVarsOfType( $1, $3 );
					 delete $1;
                                       }
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
   : procSignature block       { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) block"; 
                                 symdb::Sym_scope *scope = symtable.pop_scope();
				 $$ = $1;
                               }
   | procSignature FORWARD     { LOG(ParserLog) << "   procDecl := Procedure id ( formalParams ) forward";
                                 symdb::Sym_scope *scope = symtable.pop_scope();
				 $$ = $1;
                               }
   ;
procSignature
   : PROCEDURE                        { /* success marker*/ } 
     ID                               { $<proc>1 = new symdb::Proc( $3 );  //set $1 to hold the procedure symbol
                                        symtable.put( $<proc>1 );   // put procedure into the scope where it's defined
					$<success>2 = symtable.put_success();
                                        $<proc>1->scope = symtable.push_scope( new symdb::Sym_scope() );
					symtable.put( $<proc>1 );   // put procedure into its body's scope (for recursion)
					// TODO: during table output, DO NOT push procedure's scope if currently in it
					if( ! $<success>2 ) {
					  ERRLOG << "could not add procedure: " << $3; }
                                      }
     '(' formalParamList ')' ';'      { $<proc>1->formals = std::move(*$6); 
                                        $$ = $<success>2 ? $<proc>1 : NULL; }
   ;
funcDecl
   : funcSignature block      { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; block";
                                symdb::Sym_scope *scope = symtable.pop_scope();
				$$ = $1;
                              }
   | funcSignature FORWARD    { LOG(ParserLog) << "   procDecl := Function id ( formalParams ) : resultType ; forward";
                                symdb::Sym_scope *scope = symtable.pop_scope();
				$$ = $1;
                              }
   ;
funcSignature 
   : FUNCTION                         { /* success marker*/ }
     ID                               { $<func>1 = new symdb::Func( $3 );  //set $1 to hold the function symbol
                                        symtable.put( $<func>1 );  // put the function into the scope where it's defined
					$<success>2 = symtable.put_success();
                                        $<func>1->scope = symtable.push_scope( new symdb::Sym_scope() );
					symtable.put( $<func>1 );  // put the function into the its body's scope
					// TODO: during table output, DO NOT push function's scope if currently in it
					if( ! $<success>2 ) {
					  ERRLOG << "could not add function to symbol table: " << $3; }
                                      }
     '(' formalParamList ')'          { $<func>1->formals = std::move(*$6); }
     ':' resultType ';'               { if( ! $10->is_valid() ) {
                                          $<success>2 = false;
					  ERRLOG << "function invalid because of invalid return type: " << $3; }
                                        $<func>1->return_type = $10;
                                        $$ = $<success>2 ? $<func>1 : NULL; }
   ;


formalParamList
   : identifierList ':' type          { $<vars>$ = new std::list<symdb::Var*>();
					if( ! makeVarsOfType( $1, $3, $<vars>$, $<vars>$->end() ) )
					  ERRLOG << "formal parameter list invalid because of invalid id list";
					delete $1;
                                      }
   formalParamListTail                { LOG(ParserLog) << "   formalParamList := identifierList : type formalParamListTail"; 
					$$ = $5;
					$$->insert( $$->begin(), $<vars>4->begin(), $<vars>4->end() );
					delete $<vars>4;
                                      }
   | /* empty */                      { $$ = new std::list<symdb::Var*>(); }
   ;
formalParamListTail
   : formalParamListTail ';' identifierList ':' type      { $$ = $1;            // steal symbol list from head of tail
							    if( ! makeVarsOfType( $3, $5, $1, $1->end() ) )
							      ERRLOG << "formal parameter list invalid because of invalid id list";
							    delete $3;
                                                          }
   | /* empty */                                          { $$ = new std::list<symdb::Var*>(); }
   ;
actualParamList
   : expr actualParamListTail               { LOG(ParserLog) << "   actualParamList := expr actualParamListTail"; 
                                              $$ = $2;
					      $$->push_front( $1 );
                                            }
   | /* empty */                            { $$ = new std::list<symdb::Type*>(); }
   ;
actualParamListTail
   : actualParamListTail ',' expr           { $$ = $1;
                                              $$->push_back( $3 );
                                            }
   | /* empty */                            { $$ = new std::list<symdb::Type*>(); }
   ;
block
   : varDecls compoundStmt                                { LOG(ParserLog) << "   block := varDecls compoundStmt"; }
   | compoundStmt                                         { LOG(ParserLog) << "   block := varDecls"; }
   ;

fieldList
   : identifierList ':' type    { // error marker
                                  $<vars>$ = new std::list<symdb::Var*>();
				  if( ! makeVarsOfType( $1, $3, $<vars>$, $<vars>$->end() ) )
				    ERRLOG << "field list invalid because of invalid id list";
				  delete $1;
                                }
     fieldListTail              { LOG(ParserLog) << "   filedList := identifierList : type filedListTail";
                                  $$ = $5;
				  $$->insert( $$->begin(), $<vars>4->begin(), $<vars>4->end() );
				  delete $<vars>4;
                                }
   | /* empty */                { $$ = new std::list<symdb::Var*>(); }
   ;
fieldListTail
   : fieldListTail ';' identifierList ':' type        { $$ = $1;
                                                        if( ! makeVarsOfType( $3, $5, $$, $$->end() ) )
							  ERRLOG << "field list invalid because of invalid id list";
							delete $3;
                                                      }
   | /* empty */                                      { $$ = new std::list<symdb::Var*>(); }
   ;

identifierList
   : ID identifierListTail                            { LOG(ParserLog) << "   identifierList := ID identifierListTail"; 
							$$ = $2;                                 // reuse existing list of ids
							$$->push_front( $1 ); 
                                                      }
   ;
identifierListTail
    : identifierListTail ',' ID                       { $$ = $1;                                 // reuse existing list of ids
                                                        $$->push_front( $3 );                       // add new id to the list
                                                      }
    | /* empty */                                     { $$ = new std::list<std::string>(); }   // create new (empty) list of ids
    ;
constant
   : sign INTEGER                                     { LOG(ParserLog) << "   constant := sign int"; 
                                                        $$ = $2; 
							$$->literal = "+" + $$->literal; }
   | INTEGER                                          { LOG(ParserLog) << "   constant := int";
                                                        $$ = $1; }
   ;
variable
   : ID                   { LOG(ParserLog) << "   variable := id componentSelection"; 
                            symdb::Var var($1, invalid_type);
			    symdb::Sym_entry *entry = symtable.find( &var );
			    if( entry == NULL ) { 
			      $<addr>$ = create_addr( invalid_type );     // TODO: also issue "load invalid var" instrcution
			      ERRLOG << "undeclared variable: " << $1; }
			    else if( entry->tag != symdb::VAR_TAG ) {
			      $<addr>$ = create_addr( invalid_type );     // TODO: also issue "load invalid var" instrcution
			      ERRLOG << "id does not name a variable: " << $1; }
			    else  //$<type>$ = dynamic_cast<symdb::Var*>(entry->sym)->type;
			      $<addr>$ = create_addr( dynamic_cast<symdb::Var*>(entry->sym) );
                          }
     componentSelection   { $$ = $3; }
   ;
componentSelection
   : componentSelection '.' ID                { LOG(ParserLog) << "   componentSelection := . id componentSelection"; 
                                                // TODO: +
                                                if( ! $1->get_type()->is_valid() )
						  $$ = $1;  // do nothing - error was already reported
						else if( $1->get_type()->is_record() ) {
						  symdb::Record_type *r = dynamic_cast<symdb::Record_type*>(dynamic_cast<symdb::Type*>($1->get_type())->get_type());
						  symdb::Var var( $3, invalid_type );
						  symdb::Sym_entry *entry = r->scope->get_sym( &var );
						  if( entry == NULL ) {
						    $$ = create_addr( invalid_type );         // TODO: also issue "load invalid var" instrcution
						    ERRLOG << "no such field in type " << *r << ": " << $3; }
						  else if( entry->tag != symdb::VAR_TAG ) {
						    $$ = create_addr( invalid_type );         // TODO: also issue "load invalid var" instrcution
						    ERRLOG << $3 << " is not a field in type " << $1->get_type(); }
						  else {
						    symdb::Var *field = dynamic_cast<symdb::Var*>(entry->sym);
						    cgen::Addr *resolved_base = resolve_addr( $1 );
						    resolved_base->set_field( new cgen::Addr(field) );
						    $$ = resolved_base;
						  }
						}
						else {
						  $$ = create_addr( invalid_type );          // TODO: also issue "load invalid var" instrcution
						  ERRLOG << "cannot select " << $3 << " in " << $1->get_type(); }
                                              }
   | componentSelection '[' expr ']'          { LOG(ParserLog) << "   componentSelection := componentSelection [ expr ]"; 
                                                if( ! $1->get_type()->is_valid() )
						  $$ = $1;  // do nothing - error was laredy reported
						else if( $1->get_type()->is_array() ) {
						  symdb::Type *new_type = dynamic_cast<symdb::Array_type*>($1->get_type())->base_type;
						  cgen::Addr  *expr_addr = create_addr( new symdb::Int_type() );   // TODO: get address from expr
						  
						  cgen::Addr *resolved_base   = resolve_addr( $1 );         // already resolved or returns a new resolved address
						  cgen::Addr *resolved_index  = resolve_addr( expr_addr );
						  $$ = resolved_base;
						  $$->set_index( resolved_index );
						}
						else {
						  $$ = create_addr( invalid_type );          // TODO: also issue "load invalid var" instrcution
						  ERRLOG << "cannot index type: " << $1->get_type(); }
						// check expr type
                                                if( ! $3->is_int() ) {
						  ERRLOG << "index expression must evaluate to int: found " << *$3;
						}
                                              }
   | /* empty */                              { $$ = $<addr>0; }
   ;
sign : '+'         { $$ = PLUS_OP; }
     | '-'         { $$ = MINUS_OP; }
     ;

type
   : ID                                               { LOG(ParserLog) << "   type := ID"; 
                                                        symdb::Named_type t($1);
							symdb::Sym_entry *entry = symtable.find( &t );
							if( entry == NULL ) {
							  ERRLOG << "unknown type: " << $1;
							  $$ = new symdb::Invalid_type(); }
							else if( entry->sym->get_entry_tag() == symdb::TYPE_TAG )
							  $$ = dynamic_cast<symdb::Type*>(entry->sym)->get_type();
							else {
							  ERRLOG << "type expected, but " << symdb::sym_tag_to_string( entry->sym->get_entry_tag() ) 
								 << " found: " << $1;
							  $$ = new symdb::Invalid_type(); }
                                                      }
   | ARRAY '[' constant RANGE constant ']' OF type    { LOG(ParserLog) << "   type := ARRAY [ constant .. constant ] of type";
							symdb::Array_type *t = new symdb::Array_type();
							if( $3->type->is_int() && $5->type->is_int() )
							  t->range = symdb::Array_type::Range( atoi($3->literal.c_str()), atoi($5->literal.c_str()) );
							else {
							  ERRLOG << "range must consist of integers: [" << $3->type << ".." << $5->type << "]";
							  t->range = symdb::Array_type::Range(0, -1); }
							t->base_type = $8;
							$$ = t;
                                                      }
   | RECORD                        { symdb::Record_type *t = new symdb::Record_type(); 
				     t->scope = symtable.push_scope( new symdb::Sym_scope() );
				     $<type>1 = t; }
    fieldList END_TOKEN            { LOG(ParserLog) << "   type := RECORD fieldList END";
                                     symtable.pop_scope();
				     $$ = $<type>1; }

   ;

resultType
   : ID                                               { 
                                                        LOG(ParserLog) << "   resultType := id"; 
							symdb::Named_type t( $1 );
							symdb::Sym_entry *entry = symtable.find( &t );
							if( entry != NULL && entry->sym->get_entry_tag() == symdb::TYPE_TAG )
							  $$ = dynamic_cast<symdb::Type*>(entry->sym);
							else {
							  $$ = new symdb::Invalid_type();
							  ERRLOG << "type expected, but " << $1 << " is "
									<< (entry == NULL ? "UNK" : symdb::sym_tag_to_string(entry->sym->get_entry_tag())); }
                                                      }
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
   | IF expr THEN closedStmt ELSE closedStmt            { LOG(ParserLog) << "   closeStmt := if expr then closedStmt else closedStmt"; 
                                                          if( ! $2->is_bool() )
							    ERRLOG << "boolean expression expected as if-condition: found " << *$2;
                                                        }
   ;
openStructuredStmt
   : loopHeader openStmt                                { LOG(ParserLog) << "   openStmt := loopHeader openStmt"; }
   | IF expr THEN closedStmt ELSE openStmt              { LOG(ParserLog) << "   openStmt := if expr then closedStmt else openStmt";
                                                          if( ! $2->is_bool() )
							    ERRLOG << "boolean expression expected as if-condition: found " << *$2; 
                                                        }
   | IF expr THEN stmt                                  { LOG(ParserLog) << "   openStmt := if expr then stmt";
                                                          if( ! $2->is_bool() )
							    ERRLOG << "boolean expression expected as if-condition: found " << *$2;
                                                        }
   ;
loopHeader
   : WHILE expr DO                          { if( ! $2->is_bool() )
	                                      ERRLOG << "expected a boolean condition in loop header: found " << *$2;
                                            }
   | FOR ID ASSIGN expr TO expr DO          { // TODO: check expr type match            +
                                              // TODO: check expr type is integer (?)   +
                                              // TODO: --- either check ID is available
                                              // TODO: ---     or check ID is defined   +
                                              symdb::Var var($2, invalid_type);
					      symdb::Sym_entry *entry = symtable.find( &var );
					      if( entry == NULL )
						ERRLOG << "undefined variable: " << $2;
					      else if( entry->tag != symdb::VAR_TAG )
						ERRLOG << $2 << " is not a variable name";
					      else if( ! dynamic_cast<symdb::Var*>(entry->sym)->type->is_int() )
						ERRLOG << "integer variable expected in for-loop header: found " << *dynamic_cast<symdb::Var*>(entry->sym);
                                              if( ! $4->is_int() || ! $6->is_int() )
						ERRLOG << "integer expressions expected in loop header: found '" << *$4 << " to " << *$6 << "'";
                                            }
   ;
simpleStmt
   : assignmentStmt                                     { LOG(ParserLog) << "   simpleStmt := assignmentStmt"; }
   | procedureStmt                                      { LOG(ParserLog) << "   simpleStmt := procedureStmt"; }
   | /* emtpy */ 
   ;
assignmentStmt
   : variable ASSIGN expr                               { LOG(ParserLog) << "   assignmentStmt := variable := expr"; 
                                                          if( type_equivalence( $1->get_type(), $3 ) == NULL )
							    ERRLOG << "cannot assign expression of type " << *$3 << " to " << *$1;
                                                        }
   ;
procedureStmt
   : ID '(' actualParamList ')'             { LOG(ParserLog) << "   procedureStmt := id ( actualParamList )"; 
                                              symdb::Proc proc( $1 );
					      symdb::Sym_entry *entry = symtable.find( &proc );
					      if( entry == NULL || entry->tag != symdb::PROC_TAG ) {
						ERRLOG << "procedure name not found: " << $1;
					      }
					      else {
						symdb::Proc *p = dynamic_cast<symdb::Proc*>(entry->sym);
						int formalNum = p->formals.size();
						int actualNum = $3->size();
						std::list<symdb::Var*>::const_iterator formalItr( p->formals.begin() );
						std::list<symdb::Type*>::const_iterator actualItr( $3->begin() );
						for( int i = (actualNum < formalNum ? actualNum : formalNum); i > 0; i-- ) {
						  if( *formalItr == NULL || *actualItr == NULL )  continue;
						  if( NULL == type_equivalence( (*formalItr)->type, *actualItr ) ) {
						    ERRLOG << "actual parameter type doesn't match formal parameter type: expected " 
							   << **formalItr << ", but found " << **actualItr;
						  }
						  formalItr++;
						  actualItr++;
						}
						if( actualNum != formalNum ) {
						  ERRLOG << "function argument number mismatch: " << formalNum << " expected, " << actualNum << " given";
						}
					      }
                                            }
   ;
compoundStmt
   : BEGIN_TOKEN stmtSequence END_TOKEN     { LOG(ParserLog) << "   compoundStmt := begin stmtSequence end"; }
   ;
stmtSequence
   : stmt stmtSequenceTail                  { LOG(ParserLog) << "   stmtSequence := stmt stmtSequenceTail"; }
   ;
stmtSequenceTail
   : stmtSequenceTail ';' stmt              
   | /* empty */                            
   ;
    //===================================================================
expr
   : simpleExpr relOp simpleExpr      { LOG(ParserLog) << "   expr := simpleExpr relOp simpleExpr";
                                        $$ = result_of_op( $1, $2, $3 );
					if( $$ == NULL ) {
					  ERRLOG << "unexpected type of arguments of operator " << op_to_string($2) << ". Found: " << $1 << ", " << $3;
					  $$ = new symdb::Invalid_type(); }
                                      }
   | simpleExpr                       { LOG(ParserLog) << "   expr := simpleExpr";
                                        $$ = $1;
                                      }
   ;
simpleExpr
   : sign termList                    { LOG(ParserLog) << "   simpleExpr := sign termList";
                                        $$ = result_of_op( NULL, $1, $2 );
					if( $$ == NULL ) {
					  ERRLOG << "cannot apply unary " << op_to_string($1) << " to type: " << $1;
					  $$ = new symdb::Invalid_type(); }
                                      }
   |      termList                    { LOG(ParserLog) << "   simpleExpr := termList";
                                        $$ = $1;
                                      }
   ;
termList
   : termList addOp term              { $$ = result_of_op( $1, $2, $3 );
                                        if( $$ == NULL ) {
					  ERRLOG << "unexpected type of arguments of operator " << op_to_string($2) << ". Found: " << $1 << ", " << $3;
					  $$ = new symdb::Invalid_type(); }
                                      }
   | term                             { $$ = $1; }
   ;
term
   : factorList                       { LOG(ParserLog) << "   term := factorList";  
                                        $$ = $1;
                                      }
   ;
factorList
   : factorList mulOp factor  { $$ = result_of_op( $1, $2, $3 );
                                if(  $$ == NULL ) {
				  ERRLOG << "unexpected type of arguments of operator " << op_to_string($2) << ". Found: " << $1 << ", " << $3;
				  $$ = new symdb::Invalid_type(); }
                              }
   | factor                   { $$ = $1; }
   ;
factor
   : INTEGER                { LOG(ParserLog) << "   factor := int";
                              $$ = $1->type;    }
   | STRING                 { LOG(ParserLog) << "   factor := string";
                              $$ = $1->type;    }
   | variable               { LOG(ParserLog) << "   factor := variable";
                              $$ = $1->get_type();    }
   | functionReference      { LOG(ParserLog) << "   factor := functionReference";
                              $$ = ($$ == NULL ? new symdb::Invalid_type() : $1->return_type); }
   | NOT factor             { LOG(ParserLog) << "   factor := not factor";
                              $$ = result_of_op( NULL, NOT_OP, $2 );
			      if( $$ == NULL ) {
				ERRLOG << "cannot apply unary " << op_to_string(NOT_OP) << " to type: " << $2;
				$$ = new symdb::Invalid_type(); }
                            }
   | '(' expr ')'           { LOG(ParserLog) << "   factor := ( expr )";
                              $$ = $2; }
   ;
functionReference
   : ID '(' actualParamList ')'       { symdb::Func func( $1 );
					symdb::Sym_entry *entry = symtable.find( &func );
					if( entry == NULL || entry->tag != symdb::FUNC_TAG ) {
					  ERRLOG << "function name not found: " << $1;
					  $$ = NULL;
					}
					else {
					  $$ = dynamic_cast<symdb::Func*>(entry->sym);
					  std::list<symdb::Type*>::const_iterator actualItr( $3->begin() );
					  for( std::list<symdb::Var*>::const_iterator formalItr( $$->formals.begin() );
					       formalItr != $$->formals.end() && actualItr != $3->end();
					       formalItr++, actualItr++ ) {
					    if( *formalItr == NULL || *actualItr == NULL )  continue;  // this error was already reported
					    if( NULL == type_equivalence( (*formalItr)->type, *actualItr ) ) {
					      ERRLOG << "actual parameter type doesn't match formal parameter type: expected " 
						     << **formalItr << ", but found " << **actualItr;
					    }
					  }
					}
                                      }
   ;
addOp
   : '+'                              { LOG(ParserLog) << "   addOp := +";    $$ = PLUS_OP;  }
   | '-'                              { LOG(ParserLog) << "   addOp := *";    $$ = MINUS_OP; }
   | OR                               { LOG(ParserLog) << "   addOp := OR";   $$ = OR_OP;    }
   ;
mulOp
   : '*'                              { LOG(ParserLog) << "   mulOp := *";    $$ = TIMES_OP;   }
   | DIV                              { LOG(ParserLog) << "   mulOp := div";  $$ = INT_DIV_OP; }
   | MOD                              { LOG(ParserLog) << "   mulOp := %";    $$ = MOD_OP;     }
   | AND                              { LOG(ParserLog) << "   mulOp := AND";  $$ = AND_OP;     }
   ;
relOp
   : LT                               { LOG(ParserLog) << "   relOp := <";    $$ = LT_OP; }
   | LE                               { LOG(ParserLog) << "   relOp := <=";   $$ = LE_OP; }
   | GT                               { LOG(ParserLog) << "   relOp := >";    $$ = GT_OP; }
   | GE                               { LOG(ParserLog) << "   relOp := >=";   $$ = GE_OP; }
   | EQ                               { LOG(ParserLog) << "   relOp := =";    $$ = EQ_OP; }
   | NE                               { LOG(ParserLog) << "   relOp := <>";   $$ = NE_OP; }
   ;
    //===================================================================
%%

