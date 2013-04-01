#ifndef __ENV_H__
#define __ENV_H__

#include <unordered_map>
#include <cstddef>
#include <string>

namespace Symbol_DB
{
  struct Env;

  enum Sym_tag { PRIM_SYM_TAG, REC_SYM_TAG, ARRAY_SYM_TAG };

  struct Prim_info;
  struct Rec_info;
  struct Array_info;

  //---- struct Sym_info ----
  struct Sym_info {
    Sym_tag tag;
    union {
      Prim_info *prim_info;
      Rec_info *rec_info; 
    };
    Sym_info(Sym_tag t) : tag(t), prim_info(NULL) {}
    void populate();
  };// end Sym_info

  //====================== struct Env ===============
  struct Env
  {
    typedef std::unordered_map<std::string, Sym_info> Sym_map_type;

    Sym_info *add_symbol( std::string const& sym, Sym_tag sym_type );

  private:
    Sym_map_type symbols_;

  };// end Env

};

#include "array_types.h"

namespace Symbol_DB
{
  //---- struct Prim_info ----
  struct Prim_info {
    size_t size; 
    Prim_info() : size(0) {} };
    
  //---- struct Rec_info ----
  struct Rec_info {
    Env *env; 
    Rec_info() : env(NULL) {} };

  //---- struct Array_info
  struct Array_info {
    Range_record *range_record;
    Array_info() : range_record(NULL) {} };
  
};// end Symbol_DB

#endif//__ENV_H__
