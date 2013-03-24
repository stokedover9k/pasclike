#ifndef __SYM_TABLE_H__
#define __SYM_TABLE_H__

#include <ostream>
#include <iomanip>
#include <vector>
#include <map>

class Sym_table;
std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table);

extern Sym_table sym_table;

/*
  The symbol table is composed of two maps at its core.
  - symbol map:    symbol -> address and type
  - address map:  address -> symbol
  
  In reality, symbol map is an std::map<Id_type, Sym_info>.
  Sym_info has a field sym_index which can be used to index
  into the address map which is an std::vector of
  iterators pointing into the symbol map.

  Just after construction, symbol map contains predefined
  types which can be found in Sym_table::PREDEFINED_TYPES 
  vector. The last element of this vector is the NIL_TYPE
  ("nil"). NIL_TYPE index can be found in
  Sym_table::NIL_TYPE_INDEX. The address map then contains

  [predef(0), predef(1), ... predef(NIL_TYPE_INDEX-1), predef(NIL_TYPE_INDEX)]

  where predef(0) is an iterator to the symbol map pointing
  to the first predefined type and predef(NIL_TYPE_INDEX)
  is an iterator pointing to NIL_TYPE in the symbol map.
  
  The Sym_info objects pointed to by these pointers have
  appropriate symbol_index fields (0 through NIL_TYPE_INDEX)
  and type_index fields all equal to NIL_TYPE_INDEX.

  Additional symbols are added so that their addresses are
  greater than NIL_TYPE_INDEX and therefore their iterators
  in the address map appear at indices following
  NIL_TYPE_INDEX. This allows to iterate through the
  address map starting after the NIL_TYPE_INDEX during the
  printing of the symbol table in order to print only the
  program defined symbols.

  Since the procedures' and functions' types are defined as
  their number of arguments, the method set_routine_type
  should be used for setting their types instead of the
  normal set_type method. This method takes the number of
  the routine's arguments n as its second parameter and
  stores -n in the associated Sym_info.type_index field.
  When iterating through the symbols, the negative number
  alerts the Sym_table that it is not a pointer into the
  address map, but rather that it is itself the inverse
  of the type of the symbol.
  This was done to avoid polluting the symbol table with
  dummy types for each possible number of parameters a
  routine could have.
*/
class Sym_table
{
public:
  typedef std::string Id_type;
  typedef int Index_type;

  struct Sym_info {
    Index_type sym_index;
    Index_type type_index;
    
    Sym_info( Index_type sym, Index_type type ) : 
      sym_index(sym), type_index(type)
    {}
  };

  struct Id_less {
    bool operator() ( Id_type const& a, Id_type const& b )
    { return a.compare( b ) < 0; }
  };

  typedef std::map<Id_type, Sym_info, Id_less>              Symbol_map_type;
  typedef std::vector<typename Symbol_map_type::iterator>   Address_map_type;

  static std::vector<Id_type> const PREDEFINED_TYPES;
  static char const* const NIL_TYPE;
  static Index_type const NIL_TYPE_INDEX;

  //=========================================================================

  Sym_table();

  Index_type put( Id_type const& symbol );

  Id_type const& get_id( Index_type symbol_index ) const;
  Index_type get_type( Index_type symbol_index ) const;

  Index_type set_type( Id_type const& symbol,       Id_type const& type );
  Index_type set_type( Id_type const& symbol,       Index_type     type_index );
  Index_type set_type( Index_type     symbol_index, Index_type     type_index );
  Index_type set_type( Index_type     symbol_index, Id_type const& type );

  Index_type set_routine_type( Index_type symbol, int routine_type );

  friend std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table);

private:
  Symbol_map_type symbol_map_;    // maps Id_type -> Sym_info
  Address_map_type address_map_;  // maps Index_type -> iterator into symbol_map_
};

#endif//__SYM_TABLE_H__
