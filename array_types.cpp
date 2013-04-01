#include "array_types.h"

namespace Symbol_DB
{

  bool Array_range_ordering::operator() (Array_range const& a, Array_range const& b) {
    return (a.low == b.low) ? a.high < b.high : a.low < b.low; }

  bool Base_type_compare::operator() (Base_type const& a, Base_type const& b) {
    return &*a < &*b; };

  Type_map::iterator 
  Array_types_tree::add_base_type( Base_type const& t ) {
    Type_map::mapped_type range_map;
    return types_.insert( std::make_pair(t, range_map) ).first; }

  Range_record::Range_map::iterator
  Array_types_tree::add_range( Type_map::iterator type_ptr, Array_range range ) {
    Range_record r( make_range_record(range, type_ptr->first, NULL) );
    return type_ptr->second.insert( std::make_pair(range, r) ).first;
  }

  Range_record::Range_map::iterator
  Array_types_tree::add_range( Range_record::Range_map::iterator range_ptr, 
			       Array_range range ) {
    Range_record r( make_range_record(range, 
				      range_ptr->second.base_type,
				      &range_ptr->second) );
    return range_ptr->second.subranges.insert( std::make_pair( range, r ) ).first; }

  Range_record
  Array_types_tree::make_range_record( Array_range const& range,
				       Base_type const& t, 
				       Range_record *parent ) {
    Range_record range_record;
    range_record.range = range;
    range_record.base_type = t;
    range_record.parent_range = parent;
    return range_record; }

};// end Symbol_DB
