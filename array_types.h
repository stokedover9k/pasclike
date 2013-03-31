#ifndef __ARRAY_TYPES_H__
#define __ARRAY_TYPES_H__

#include "env.h"
#include <unordered_map>
#include <set>

namespace Symbol_DB
{

  struct Array_range {
    int low;
    int high; };

  typedef Env::Sym_map_type::const_iterator Base_type_ptr;

  struct Range_node;
  struct Range_node_compare {
    bool operator() (Range_node const&, Range_node const&); }; 

  struct Range_node {
    typedef std::set<Range_node, Range_node_compare> Range_set;
    //
    Array_range range;
    mutable Range_set nodes;
    mutable Range_set::const_iterator parent; };

  struct Type_node {
    Base_type_ptr base_type;
    mutable typename Range_node::Range_set ranges; };

  struct Type_node_compare {
    bool operator() (Type_node const&, Type_node const&); };

  struct Array_types_tree {
    typedef std::set<Type_node, Type_node_compare> Type_set;
    typedef Range_node::Range_set::iterator Range_ptr;
    typedef Type_set::iterator Type_ptr;

    Type_ptr add_base_type( Base_type_ptr const& );
    Range_ptr add_range( Base_type_ptr, Array_range );
    static Range_ptr add_range( Range_node&, Array_range );
    static Range_ptr add_range( Type_node&, Array_range );
  private:
    Type_set types_;
    static Type_node make_type_node( Base_type_ptr const& );
    static Range_node make_range_node( Array_range const& );
  };



  bool Range_node_compare::operator() (Range_node const& a, Range_node const& b) {
      return (a.range.low == b.range.low) ? 
	a.range.high < b.range.high : 
	a.range.low < b.range.low; }

  bool Type_node_compare::operator() (Type_node const& a, Type_node const& b) {
    return &*a.base_type < &*b.base_type; }

  Range_node
  Array_types_tree::make_range_node( Array_range const& array_range ) {
    Range_node rn;
    rn.range = array_range;
    return rn; }

  Type_node
  Array_types_tree::make_type_node( Base_type_ptr const& base_type_ptr ) {
    Type_node tn;
    tn.base_type = base_type_ptr;
    return tn; }

  typename Array_types_tree::Type_ptr
  Array_types_tree::add_base_type( Base_type_ptr const& base_type_ptr ) {
    return types_.insert( make_type_node(base_type_ptr) ).first; }

  typename Array_types_tree::Range_ptr
  Array_types_tree::add_range( Base_type_ptr base_type_ptr, Array_range range ) {
    return add_base_type( base_type_ptr )->             // Type_ptr
      ranges.insert( make_range_node(range) ).first; }  // ->ranges.insert(...)
  

};// end Symbol_DB

#endif//__ARRAY_TYPES_H__
