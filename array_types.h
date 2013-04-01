#ifndef __ARRAY_TYPES_H__
#define __ARRAY_TYPES_H__

#include "env.h"
#include <unordered_map>
#include <set>
#include <map>

namespace Symbol_DB
{

  struct Array_range {
    int low;
    int high; };

  struct Array_range_ordering {
    bool operator() (Array_range const &, Array_range const&); };

  typedef Env::Sym_map_type::const_iterator Base_type;

  struct Base_type_compare {
    bool operator() (Base_type const&, Base_type const&); };

  struct Range_record {
    typedef std::map<Array_range, Range_record, Array_range_ordering> Range_map;
    //
    Array_range range;
    Range_record *parent_range;
    Base_type base_type;
    Range_map subranges; };

  typedef std::map<Base_type,
		   typename Range_record::Range_map, 
		   Base_type_compare> Type_map;

  struct Array_types_tree {
    Type_map::iterator add_base_type( Base_type const& );
    Range_record::Range_map::iterator add_range( Type_map::iterator, Array_range );
    Range_record::Range_map::iterator add_range( Range_record::Range_map::iterator,
						 Array_range );
  private:
    Type_map types_;
    static Range_record make_range_record(Array_range const&,
					  Base_type const&,
					  Range_record *parent = NULL);
  };

};// end Symbol_DB

#endif//__ARRAY_TYPES_H__
