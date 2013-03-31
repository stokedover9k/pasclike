#ifndef __SYMTABLE4_H__
#define __SYMTABLE4_H__

#include <list>
#include <string>

namespace Symbol_DB
{
  //=========== struct Scope ==========
  template<typename E>
  struct Scope
  {
    E scope_data;
    Scope *parent_scope;
    std::list<Scope<E>*> children;
    
    E& operator* () { return scope_data; }
  };// end Scope

  //=========== class Scope_tree ========
  template<typename E>
  class Scope_tree
  {
    Scope<E> *global_scope;
    Scope<E> *current_scope;

  public:
    Scope_tree() {
      global_scope = new Scope<E>();
      current_scope = global_scope; }

    ~Scope_tree() {
      for( typename std::list<Scope<E>*>::iterator i = global_scope->children.begin();
	   i != global_scope->children.end(); i++ )
	delete *i;
      delete global_scope; }

    E* enter_new_scope() { 
      Scope<E> *s = new Scope<E>();
      s->parent_scope = current_scope;
      current_scope->children.push_back(s); 
      current_scope = s; 
      return &s->scope_data; }

    E* exit_current_scope() {
      current_scope = current_scope->parent_scope;
      return &current_scope->scope_data; }

    E* get_current_scope() {
      return &current_scope->scope_data; }

    E* get_global_scope() {
      return &global_scope->scope_data; }

  };// end Scope_tree

};// end Symbol_DB

#endif//__SYMTABLE4_H__
