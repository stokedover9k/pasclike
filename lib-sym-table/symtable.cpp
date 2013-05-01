#include "symtable.h"

namespace symdb
{

  Scope_tree::Scope_tree( Sym_scope *_global_scope ) : 
    global_scope(_global_scope == NULL ?
		 throw std::invalid_argument("in Scope_tree::Scope_tree"
					     "( Sym_scope * ) arg1 is NULL") : 
		 _global_scope->get_parent_scope() != NULL ?
		 throw std::invalid_argument("in Scope_tree::Scope_tree"
					     "( Sym_scope * ) arg1 has non-NULL"
					     " parent scope") :
		 _global_scope),
    current_scope(_global_scope) { }

  Sym_scope * Scope_tree::get_current_scope() {
    return current_scope; }
  
  Sym_scope * Scope_tree::get_global_scope() {
    return global_scope; }
  
  Sym_scope * Scope_tree::set_current_scope( Sym_scope * scope ) {
    current_scope = scope;
    return scope; }
  
  Sym_scope * Scope_tree::add_to_current_scope( Sym_scope * scope ) {
    scope->parent_scope = current_scope;
    return scope; }

  Sym_scope * Scope_tree::push_scope( Sym_scope * scope ) {
    add_to_current_scope( scope );
    return set_current_scope( scope ); }

  Sym_scope * Scope_tree::pop_scope() {
    Sym_scope * scope = current_scope;
    set_current_scope( current_scope->get_parent_scope() ); 
    return scope; }

  Sym_table::Sym_table( Sym_scope * scope ) : 
    Scope_tree(scope), put_successful(true) { }

  Sym_entry * Sym_table::find( Sym const* sym ) {
    Sym_entry * entry = NULL;
    for( Sym_scope * scope = get_current_scope();
	 entry == NULL && scope != NULL;
	 scope = scope->get_parent_scope() ) {
      //std::cout << "searching for " << *sym << " in " << scope << std::endl;
      entry = scope->get_sym( sym );
    }
    return entry; }

  Sym_entry * Sym_table::put( Sym * sym ) {
    Sym_entry * entry = get_current_scope()->add_sym( sym );
    put_successful = get_current_scope()->add_success();
    return entry; }

  bool Sym_table::put_success() const {
    return put_successful; }

}; // end symdb
