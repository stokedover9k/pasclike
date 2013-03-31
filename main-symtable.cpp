#include "env.h"
#include "scope_tree.h"
#include "array_types.h"
#include <iostream>

std::ostream& operator<< (std::ostream& os, Symbol_DB::Sym_info const& info)
{
  os << "sym info: ";
  switch( info.tag ) {
  case Symbol_DB::Sym_tag::PRIM_SYM_TAG:
    os << "primitive, size=" << info.prim_info->size;   break;
  case Symbol_DB::Sym_tag::REC_SYM_TAG:
    os << "record, environment_address=" << info.rec_info->env;  break;
  default:  throw std::string("cannot output field with type: " + info.tag);
  }
  return os;
}

int main(int argc, char* argv[]) 
{
  using std::cout;
  using std::endl;
  using std::flush;

  using namespace Symbol_DB;

  Scope_tree<Env> symtable;
  Sym_info *info;

  info = symtable.get_current_scope()->add_symbol("foo", PRIM_SYM_TAG);
  cout << *info << endl;
  info->prim_info->size = 4;
  cout << *info << endl;

  info = symtable.get_current_scope()->add_symbol("bar", REC_SYM_TAG);
  cout << *info << endl;
  info->rec_info->env = symtable.enter_new_scope();
  cout << *info << endl;

  symtable.exit_current_scope();
  
}
