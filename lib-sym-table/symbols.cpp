#include "symbols.h"

namespace symdb
{

  Sym_tag  Lit::get_entry_tag() const { return  LIT_TAG; }
  Sym_tag Type::get_entry_tag() const { return TYPE_TAG; }
  Sym_tag  Var::get_entry_tag() const { return  VAR_TAG; }
  Sym_tag Proc::get_entry_tag() const { return PROC_TAG; }
  Sym_tag Func::get_entry_tag() const { return FUNC_TAG; }

  bool Type::is_int()    const { return get_type_tag() ==     INT_TYPE_TAG; }
  bool Type::is_bool()   const { return get_type_tag() ==    BOOL_TYPE_TAG; }
  bool Type::is_string() const { return get_type_tag() ==  STRING_TYPE_TAG; }
  bool Type::is_array()  const { return get_type_tag() ==   ARRAY_TYPE_TAG; }
  bool Type::is_record() const { return get_type_tag() ==  RECORD_TYPE_TAG; }
  bool Type::is_valid()  const { return get_type_tag() != INVALID_TYPE_TAG; }

  Type::Type_tag     Int_type::get_type_tag() const { return     INT_TYPE_TAG; }
  Type::Type_tag    Bool_type::get_type_tag() const { return    BOOL_TYPE_TAG; }
  Type::Type_tag  String_type::get_type_tag() const { return  STRING_TYPE_TAG; }
  Type::Type_tag   Array_type::get_type_tag() const { return   ARRAY_TYPE_TAG; }
  Type::Type_tag  Record_type::get_type_tag() const { return  RECORD_TYPE_TAG; }
  Type::Type_tag Invalid_type::get_type_tag() const { return INVALID_TYPE_TAG; }
  Type::Type_tag   Named_type::get_type_tag() const { return refers_to->get_type_tag(); }

  std::string Type::get_type_name() const { 
    return std::string( type_tag_to_string(get_type_tag()) ); }

  std::string Named_type::get_type_name() const {
    return name; }



  Lit::Lit( std::string const& _literal, Type *_type ) :
    literal(_literal), type(_type) { }

  Var::Var( std::string const& _name, Type *_type ) :
    name(_name), type(_type) { }

  Proc::Proc( std::string const& _name ) :
    name(_name), scope(NULL) { }

  Func::Func( std::string const& _name ) :
    name(_name), scope(NULL), return_type(NULL) { }

  Array_type::Array_type() :
    base_type(NULL) { }

  Record_type::Record_type() :
    scope(NULL) { }

  Named_type::Named_type( std::string const& _name ) : 
    name(_name), refers_to(NULL) { }

  Type       *       Type::get_type()       { return this; }
  Type const *       Type::get_type() const { return this; }
  Type       * Named_type::get_type()       { return refers_to->get_type(); }
  Type const * Named_type::get_type() const { return refers_to->get_type(); }

  size_t Sym::get_alloc_size() const    { return 0; }  // all but var's
  size_t Var::get_alloc_size() const    { return 1; }

  //---- helper functions ----//

  char const * sym_tag_to_string( Sym_tag tag ) {
    switch( tag ) {
    case  LIT_TAG:  return "LIT";
    case TYPE_TAG:  return "TYPE";
    case  VAR_TAG:  return "VAR";
    case PROC_TAG:  return "PROC";
    case FUNC_TAG:  return "FUNC";
    default:        return "UNK";  } }
  
  char const * type_tag_to_string( Type::Type_tag tag ) {
    switch( tag ) {
    case Type::    INT_TYPE_TAG:  return "integer";
    case Type::   BOOL_TYPE_TAG:  return "boolean";
    case Type:: STRING_TYPE_TAG:  return "string";
    case Type::  ARRAY_TYPE_TAG:  return "ARRAY";
    case Type:: RECORD_TYPE_TAG:  return "RECORD";
    case Type::INVALID_TYPE_TAG:  return "N/A";
    default:                      return "UNK";  } }

}; // end symdb
