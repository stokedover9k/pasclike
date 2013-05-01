#include "scope.h"

namespace symdb
{

  Sym_entry::Sym_entry( Sym* _sym, Sym_scope* _scope, int _offset ) : 
    tag( _sym == NULL ? 
	 throw
	 std::invalid_argument("in Sym_entry::Sym_entry(Sym *) arg1 = NULL"),
	 TYPE_TAG : _sym->get_entry_tag() ),
    sym(_sym), 
    scope(_scope),
    offset(_offset) { }

  Sym_scope::Sym_scope( Sym_scope *_parent_scope ) :
    add_successful(true), parent_scope(_parent_scope), alloc_size(0) { }

  Sym_entry * Sym_scope::get_sym( Sym const *sym ) {
    Key key( SH().gen_key( *sym ) );
    Sym_map::iterator itr( symbols.find( key ) );
    return itr == symbols.end() ? NULL : &itr->second;
  }

  Sym_entry * Sym_scope::add_sym( Sym *sym ) {
    Key key( SH().gen_key( *sym ) );
    Sym_entry entry( sym );
    entry.scope = this;
    entry.offset = alloc_size;
    Sym_map::value_type val( key, entry );
    std::pair<Sym_map::iterator, bool> p = symbols.insert( val );
    add_successful = p.second;
    if( add_successful )
      alloc_size += sym->get_alloc_size();
    return &p.first->second; }

  Sym_scope * Sym_scope::get_parent_scope() const {
    return parent_scope; }

  size_t Sym_scope::get_alloc_size() const {
    return alloc_size; }

  bool Sym_scope::add_success() const {
    return add_successful; }

  Sym_scope::Sym_map::const_iterator Sym_scope::begin() const {
    return symbols.begin(); }

  Sym_scope::Sym_map::const_iterator Sym_scope::end() const {
    return symbols.end(); }

  std::string Sym_string_hasher::gen_key( Sym const& sym ) const {
    switch( sym.get_entry_tag() ) {
    case  LIT_TAG:  return dynamic_cast< Lit const&>(sym).literal;
    case TYPE_TAG:  return dynamic_cast<Type const&>(sym).get_type_name();
    case  VAR_TAG:  return dynamic_cast< Var const&>(sym).name;
    case PROC_TAG:  return dynamic_cast<Proc const&>(sym).name;
    case FUNC_TAG:  return dynamic_cast<Func const&>(sym).name;
    default:
      throw std::invalid_argument("in Sym_string_hasher::gen_key(Sym const&) arg1 returned unknown tag");
    }
  }

}; // end symdb

