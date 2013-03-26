#include "symbol-table.h"
#include <utility>


char const* const Sym_table::NIL_TYPE = "nil";

std::vector<Sym_table::Id_type> const Sym_table::PREDEFINED_TYPES = 
  { "array", "record", Sym_table::NIL_TYPE };

Sym_table::Index_type const Sym_table::NIL_TYPE_INDEX = 
  Sym_table::PREDEFINED_TYPES.size() - 1;



Sym_table::Sym_table()
{
  for( int i = 0; i < PREDEFINED_TYPES.size(); ++i ) {
    std::pair<Symbol_map_type::iterator, bool> p = 
      symbol_map_.insert( std::make_pair(PREDEFINED_TYPES[i], 
					 Sym_info(i, NIL_TYPE_INDEX)) );
    if( !p.second ) throw "could not add a predefined type to symbol table";
    address_map_.push_back( p.first );
  }
}

Sym_table::Index_type Sym_table::put( Id_type const& symbol )
{
  Index_type new_index = symbol_map_.size();
  std::pair<Symbol_map_type::iterator, bool> p = 
    symbol_map_.insert( std::make_pair(symbol,
				       Sym_info(new_index, NIL_TYPE_INDEX)) );
  if( p.second ) {  // if inserted
    address_map_.push_back( p.first );
  }
  
  if( address_map_[p.first->second.sym_index] != p.first )
    throw "invalid indexing in table";

  return p.first->second.sym_index;
}

Sym_table::Id_type const& Sym_table::get_id( Index_type symbol_index ) const
{
  return address_map_[symbol_index]->first;
}

Sym_table::Index_type Sym_table::get_type( Index_type symbol_index ) const
{
  return address_map_[symbol_index]->second.type_index;
}

Sym_table::Index_type Sym_table::set_type( Index_type symbol_index, Index_type type_index )
{
  address_map_[symbol_index]->second.type_index = type_index;
}

Sym_table::Index_type Sym_table::set_type( Id_type const& symbol, Index_type type_index )
{
  set_type( put(symbol), type_index );
}

Sym_table::Index_type Sym_table::set_type( Id_type const& symbol, Id_type const& type )
{
  set_type( put(symbol), put(type) );
}

Sym_table::Index_type Sym_table::set_type( Index_type symbol_index, Id_type const& type )
{
  set_type( symbol_index, put(type) );
}

Sym_table::Index_type Sym_table::set_routine_type( Index_type symbol_index, int routine_type )
{
  address_map_[symbol_index]->second.type_index = -routine_type;
}

std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table)
{
  for( int i = Sym_table::NIL_TYPE_INDEX + 1; i < sym_table.address_map_.size(); ++i ) {
    Sym_table::Symbol_map_type::const_iterator itr = sym_table.address_map_[i];
    Sym_table::Index_type  sym_index = itr->second.sym_index;
    Sym_table::Index_type type_index = itr->second.type_index;

    os << std::left
       << "address: "       << std::setw(5)  << (sym_index - Sym_table::NIL_TYPE_INDEX - 1)
       << ",  identifier: " << std::setw(14) << itr->first
       << ",  type: ";
    if( type_index < 0 )       // if rountine type
      os << -type_index << '\n';
    else                       // other types
      os << sym_table.address_map_[type_index]->first << '\n';
  }
  return os;
}

#ifndef __SYM_TABLE_DEFINED__
#define __SYM_TABLE_DEFINED__
Sym_table sym_table;
#endif//__SYM_TABLE_DEFINED__

