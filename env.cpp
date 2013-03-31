#include "env.h"

namespace Symbol_DB
{

  void Sym_info::populate()
  {
    switch( tag ) {
    case PRIM_SYM_TAG:  prim_info = new Prim_info();  break;
    case REC_SYM_TAG:    rec_info = new  Rec_info();  break;
    default:
      throw std::string("cannot populate field with type: " + tag);
    }
  }

  Sym_info *Env::add_symbol( std::string const& sym, Sym_tag sym_type )
  {
    typename Sym_map_type::value_type val(sym, Sym_info(sym_type));
    std::pair<typename Sym_map_type::iterator, bool> p( symbols_.insert(val) );
    if( p.second )  
      p.first->second.populate();
    return &(p.first->second);
  }

};// end Symbol_DB
