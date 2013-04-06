#ifndef __SYMBOL_IO_CPP__
#define __SYMBOL_IO_CPP__

#include "symbols.h"
#include "scope.h"
#include "symtable.h"

#include <list>

#include <iostream>

namespace symdb
{

  void Lit::send_to( std::ostream& os ) const {
    os << literal << " of type ";
    if( type == NULL )  os << "N/A";
    else                type->send_to( os ); }

  void Type::send_to( std::ostream& os ) const {
    os << type_tag_to_string( get_type_tag() ); }

  void Var::send_to( std::ostream& os ) const {
    os << name << " of type ";
    if( type == NULL )  os << "N/A";
    else                type->send_to( os ); }

  void Proc::send_to( std::ostream& os ) const {
    os << name << " (";
    for( std::list<Var *>::const_iterator i( formals.begin() );
	 i != formals.end(); i++ ) {
      if( i != formals.begin() )  os << ", ";
      if( *i == NULL )  os << "N/A";
      else              (*i)->send_to( os ); }
    os << ")"; }

  void Func::send_to( std::ostream& os ) const {
    os << name << " (";
    for( std::list<Var *>::const_iterator i( formals.begin() );
	 i != formals.end(); i++ ) {
      if( i != formals.begin() )  os << ", ";
      if( *i == NULL )  os << "N/A";
      else              (*i)->send_to( os ); }
    os << ") returning ";
    if( return_type == NULL )  os << "N/A";
    else                       return_type->send_to( os ); }

  void Array_type::send_to( std::ostream& os ) const {
    os << "ARRAY";
    for( std::list<Range>::const_iterator r( ranges.begin() );
	 r != ranges.end(); r++ ) {
      os << "[" << r->first << ".." << r->second << "]"; }
    os << " of ";
    base_type->send_to( os ); }

  void Record_type::send_to( std::ostream& os ) const {
    os << "RECORD[";
    if( scope == NULL )  os << "NIL";
    else                 scope->send_to( os, ", " );
    os << "]"; }

  void Named_type::send_to( std::ostream& os ) const {
    os << name << " (alias for: ";
    if( refers_to == NULL )  os << "N/A";
    else                     refers_to->send_to( os );
    os << ")"; }

  void Sym_scope::send_to( std::ostream& os, std::string const& delim ) const {
    Sym_map::const_iterator i(symbols.begin());
    if( i == symbols.end() )  return;
    os << i->second;
    for( i++; i != symbols.end(); i++ )
      os << delim << i->second; }
  
  std::ostream& operator<< (std::ostream& os, Sym const& sym) {
    sym.send_to(os);
    return os; }

  std::ostream& operator<< (std::ostream& os, Sym_entry const& entry) {
    os << (sym_tag_to_string( entry.tag )) << ": ";
    if( entry.sym == NULL )  os << "N/A";
    else                     entry.sym->send_to(os);
    return os; }
  
  std::ostream& operator<< (std::ostream& os, Sym_scope const& scope) {
    scope.send_to( os, std::string("\n") );
    return os; }

  std::ostream& operator<< (std::ostream& os, Scope_tree const& table) {
    std::list<Sym_scope const*> q;
    q.push_back( table.global_scope );
    for( std::list<Sym_scope const*>::const_iterator i(q.begin());
	 i != q.end(); i++ ) {
      os << "--- scope at: " << *i << '\n';
      typename Sym_scope::Sym_map::const_iterator e_itr( (*i)->symbols.begin() );
      for( ; e_itr != (*i)->symbols.end(); e_itr++ ) {
	os << e_itr->second << "\n";
	Sym_tag tag = e_itr->second.tag;
	if( tag == PROC_TAG ) 
	  {
	    q.push_back(dynamic_cast<Proc const*>(e_itr->second.sym)->scope);
	  } 
	else if( tag == FUNC_TAG ) 
	  {
	    q.push_back(dynamic_cast<Func const*>(e_itr->second.sym)->scope);
	  } 
	else if(tag == TYPE_TAG &&
		dynamic_cast<Type const*>(e_itr->second.sym)->is_record()) 
	  {
	    Type const *t =
	      dynamic_cast<Type const*>(e_itr->second.sym)->get_type();
	    q.push_back(dynamic_cast<Record_type const*>(t)->scope);
	  } } }
    return os; }

}; // end symdb

#endif//__SYMBOL_IO_CPP__
