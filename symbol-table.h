#ifndef __SYMBOL_TABLE_H__
#define __SYMBOL_TABLE_H__

#include <ostream>
#include <iomanip>
#include <set>
#include <vector>
#include <cstddef>

//-------- parser symbol table -----
extern std::string const SYM_NIL_TYPE;

struct SymRecord {
  std::string id;
  std::string type;
  size_t address;

  SymRecord( std::string newId, 
	     std::string newType = SYM_NIL_TYPE, 
	     size_t newAddress = -1 ) : 
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

typedef std::set<SymRecord, SymIdLess> SymDB;

extern SymDB symTable;

void addSymbol( std::string const& id );
void addSymbol( std::string const& id,
		std::string const& type,
		bool allowOverride = true );
std::vector<SymRecord> toVector( SymDB const& );
std::ostream& operator<< (std::ostream&, SymRecord const& );
//----------------------------------

#endif //__SYMBOL_TABLE_H__
