#include "symbol-table-2.h"
#include <utility>


char const* const Sym_table::NIL_TYPE = "nil";

std::vector<typename Sym_table::Id_type> const Sym_table::PREDEFINED_TYPES = 
  { "array", "record", Sym_table::NIL_TYPE };

Sym_table::Index_type const Sym_table::NIL_TYPE_INDEX = 
  Sym_table::PREDEFINED_TYPES.size() - 1;



Sym_table::Sym_table()
{
  for( int i = 0; i < PREDEFINED_TYPES.size(); ++i ) {
    std::pair<typename Symbol_map_type::iterator, bool> p = 
      symbol_map_.insert( std::make_pair(PREDEFINED_TYPES[i], 
					 Sym_info(i, NIL_TYPE_INDEX)) );
    if( !p.second ) throw "could not add a predefined type to symbol table";
    address_map_.push_back( p.first );
  }
}

Sym_table::Index_type Sym_table::put( Id_type const& symbol )
{
  Index_type new_index = symbol_map_.size();
  std::pair<typename Symbol_map_type::iterator, bool> p = 
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

std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table)
{
  for( int i = Sym_table::NIL_TYPE_INDEX + 1; i < sym_table.address_map_.size(); ++i ) {
    os << sym_table.address_map_[i]->first << " " 
       << sym_table.address_map_[i]->second.type_index << " "
       << sym_table.address_map_[sym_table.address_map_[i]->second.type_index]->first
       << "\n";
  }
  return os;
}


#include <iostream>

int main(int argc, char* argv[])
{
  Sym_table tbl;
  std::cout << tbl << std::endl;

  int ind;
  ind = tbl.put("integer");
  std::cout << tbl << std::endl;

  ind = tbl.put("numbers");
  tbl.set_type(ind, "array");
  std::cout << tbl << std::endl;
  
  return 0;
}
