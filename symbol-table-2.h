#ifndef __SYM_TABLE_H__
#define __SYM_TABLE_H__

#include <ostream>
#include <iomanip>
#include <vector>
#include <map>
#include <cstddef>

class Sym_table;
std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table);

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

  friend std::ostream& operator<< (std::ostream& os, Sym_table const& sym_table);

private:
  Symbol_map_type symbol_map_;    // maps Id_type -> Sym_info
  Address_map_type address_map_;  // maps Index_type -> iterator into symbol_map_
};

#endif//__SYM_TABLE_H__
