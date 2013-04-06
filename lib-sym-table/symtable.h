#ifndef __SYMTABLE_H__
#define __SYMTABLE_H__

#include "symbols.h"
#include "scope.h"

namespace symdb
{

  struct Sym_table;
  struct Scope_tree;
  

  //========================//
  struct Scope_tree {       //
  //========================//
    Sym_scope * get_current_scope();
    Sym_scope * get_global_scope();
    Sym_scope * push_scope( Sym_scope * );
    Sym_scope * pop_scope();
    
    Scope_tree( Sym_scope * global_scope );

    friend std::ostream& operator<< (std::ostream& os, Scope_tree const&);

  protected:
    Sym_scope * set_current_scope( Sym_scope * );
    Sym_scope * add_to_current_scope( Sym_scope * );

  private:
    Sym_scope * global_scope;
    Sym_scope * current_scope; };

  //=======================================//
  struct Sym_table : public Scope_tree {   //
  //=======================================//
    Sym_entry * find( Sym const* );
    Sym_entry * put( Sym * );
    bool put_success() const;

    Sym_table( Sym_scope * global_scope = new Sym_scope(NULL) );

  private:
    bool put_successful;
  };

}; // end symdb

#endif//__SYMTABLE_H__
