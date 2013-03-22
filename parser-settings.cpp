#include "parser-settings.h"

//-------- parser output -----------
std::ostream rulesLog(std::cout.rdbuf());
//----------------------------------

//-------- parser symbol table -----
std::string const SYM_NIL_TYPE("NIL");

struct SymRecord {
  std::string id;
  std::string type;
  size_t address;

  SymRecord( std::string newId, std::string newType, size_t newAddress = -1 ) : 
    id(newId), 
    type(newType), 
    address(newAddress)
  { }

  SymRecord( ) :
    id(""),
    type(SYM_NIL_TYPE),
    address(-1)
  { }
};

struct SymIdLess {
  bool operator() ( SymRecord const& a, SymRecord const& b )
  { return a.id.compare( b.id ) < 0; }
};

struct SymAddressLess {
  bool operator() ( SymRecord const& a, SymRecord const& b )
  { return a.address < b.address; }
};

SymDB symTable;

void addSymbol( std::string const& id, std::string const& type )
{
  std::pair<SymDB::iterator, bool> p =
    symTable.insert( SymRecord( id, type, symTable.size() + 1 ) );

  // If the record already exists, neither the address nor type were updated.
  if( p.second == false ) {     // if not inserted (record exists)
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
    table[record.address-1] = record;
  return std::move(table);
}

//----------------------------------
