#include "symbol-table.h"
#include <iostream>

//-------- parser symbol table -----
std::string const SYM_NIL_TYPE("nil");

std::ostream& operator<< ( std::ostream& os, SymRecord const& record ) {
  static int const _address_width = 5;
  static int const _id_width = 20;
  os << std::left
     <<     "address: "   << std::setw(_address_width) << record.address
     << ",  identifier: " << std::setw(_id_width)      << record.id
     << ",  type: "                                    << record.type;
  return os;
}

#ifndef __SYM_TABLE_DEFINED__
#define __SYM_TABLE_DEFINED__
SymDB symTable;
#endif//__SYM_TABLE_DEFINED__

void addSymbol( std::string const& id )
{
  addSymbol( id, SYM_NIL_TYPE, false );  // don't allow override of type
}

void addSymbol( std::string const& id, std::string const& type, bool allowOverride )
{
  std::pair<SymDB::iterator, bool> p =
    symTable.insert( SymRecord( id, type, symTable.size() ) );

  // If the record already exists, neither the address nor type were updated.
  if( allowOverride && !p.second ) {     // if not inserted (record exists)
    SymDB::const_iterator hint( p.first );
    hint++;
    SymRecord record( id, type, p.first->address );
    symTable.erase( p.first );
    symTable.insert( hint, record );
  }
}

std::vector<SymRecord> toVector( SymDB const& symbols )
{
  std::vector<SymRecord> table( symbols.size() );
  for( SymRecord const& record : symbols )
    table[record.address] = record;
  return std::move(table);
}

//----------------------------------
