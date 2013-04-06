#include "symtable.h"

#include <iostream>

int main( int argc, char* argv[] )
{
  using namespace std;
  using namespace symdb;

  Sym_scope* scope = new Sym_scope;
  
  Sym *sym = NULL;
  Type *type = NULL;
  
  Var *var;
  Proc *proc;
  Func *func;

  Int_type       *int_type = new Int_type();
  Bool_type     *bool_type = new Bool_type();
  String_type *string_type = new String_type();
  Array_type   *array_type = new Array_type();
  Record_type *record_type = new Record_type();
  Named_type   *named_type = new Named_type("number");

  Sym_entry *entry = NULL;
  
  //---- Primitive types ----//
  entry = scope->add_sym( int_type );
  cout << *entry << " --- "
       << (scope->get_sym( int_type ) == entry ? "check" : "fail") << endl;

  entry = scope->add_sym( bool_type );
  cout << *entry << " --- "
       << (scope->get_sym( bool_type ) == entry ? "check" : "fail") << endl;

  entry = scope->add_sym( string_type );
  cout << *entry << " --- "
       << (scope->get_sym( string_type ) == entry ? "check" : "fail") << endl;

  //---- Primitive variables ----//
  var = new Var("a");
  var->type = bool_type;
  entry = scope->add_sym( var );
  cout << *entry << " --- "
       << (scope->get_sym( var ) == entry ? "check" : "fail") << endl;

  //---- Array type ----//
  array_type->base_type = int_type;
  array_type->ranges.push_back( Array_type::Range(1, 10) );
  array_type->ranges.push_back( Array_type::Range(0, 19) );

  var = new Var("nums");
  var->type = array_type;
  entry = scope->add_sym( var );
  var = new Var("nums");
  cout << *entry << " --- "
       << (scope->get_sym( var ) == entry ? "check" : "fail") << endl;
  delete var;

  //---- Record type ----//
  Sym_scope *record_scope = new Sym_scope();
  var = new Var("a");
  var->type = string_type;
  record_scope->add_sym( var );
  record_type->scope = record_scope;

  var = new Var("obj");
  var->type = record_type;
  entry = scope->add_sym( var );
  var = new Var("obj");
  cout << *entry << " --- "
       << (scope->get_sym( var ) == entry ? "check" : "fail") << endl;
  delete var;

  //---- Named type ----//
  Type *t = new Int_type;
  named_type->refers_to = dynamic_cast<Type*>(scope->get_sym( t )->sym);
  entry = scope->add_sym( named_type );
  cout << *entry << " --- "
       << (scope->get_sym( named_type ) == entry ? "check" : "fail") << endl;

  var = new Var("n");
  var->type = named_type;
  entry = scope->add_sym( var );
  cout << *entry << " --- "
       << (scope->get_sym( var ) == entry ? "check" : "fail") << endl;

  //---- Scope ----//
  cout << "----- Scope -----"
       << *scope << endl;

  return 0;
}
