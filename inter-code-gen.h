#ifndef __INTER_CODE_GEN__
#define __INTER_CODE_GEN__

#include "symtable.h"
#include <unordered_set>
#include <ostream>
#include <stdexcept>

namespace cgen
{
  using symdb::Var;
  using symdb::Lit;
  using symdb::Func;
  using symdb::Type;
  
  struct Tmp;
  struct Addr;
  struct Instr;
  struct Operation;

  std::ostream& operator<< (std::ostream&, Tmp const&);
  std::ostream& operator<< (std::ostream&, Instr const&);
  std::ostream& operator<< (std::ostream&, Addr const&);

  //================ ADDR =====================//
  struct Addr {                                //
  //===========================================//
    enum Resolution { INDEX, FIELD, NONE };

    Addr( Var* );
    Addr( Lit* );
    Addr( Func* );
    Addr( Tmp const*, Type* );

    Tmp const*  get_tmp() const;
    Lit*        get_lit() const;
    Var*        get_var() const;
    Type*       get_type() const;
    
    void set_index( Addr * );
    void set_field( Addr * );
    Addr * const get_index() const;
    Addr * const get_field() const;
    Resolution get_resolution_type() const;

    friend std::ostream& operator<< (std::ostream& os, Addr const& a);

  private:
    enum ADDR_TYPE { VAR, TMP, LIT, FUN } addr_type;

    union { 
      Tmp const* tmp;  
      Var* var;
      Lit* lit; 
      Func* func; };

    Resolution resolution_type;

    union {
      Addr *index;
      Addr *field; };

    Type* type; 
  }; //----------- end ADDR -------------------//

  //============== OPERATION ==================//
  struct Op { enum Opcode {                    //
  //===========================================//
      MULT, DIVIDE, PLUS, MINUS,               // binary:  x = y op z
      INDEXED_COPY,                            //          x[y] = z
      COPY_INDEXED,                            //          x = y[z]
      COMPONENT_COPY,                          //          x.y = z
      COPY_COMPONENT,                          //          x = y.z
      UMINUS, NOT, COPY, FUNCALL,              // unary:   x = op y
      LIT_ACCESS, VAR_ACCESS                   // nonary:  x
    }; 
    
    bool static is_binary( Opcode );
    bool static is_unary( Opcode );
    bool static is_nonary( Opcode );
  }; //---------- end OPERATION ---------------//

  //================ INSTR ====================//
  struct Instr {                               //
  //===========================================//
    Instr( Op::Opcode _op,
	   Addr * _arg1,
	   Addr * _arg2,
	   Addr * _res );

    Op::Opcode op;
    Addr *arg1;
    Addr *arg2;
    Addr *res;
  }; //----------- end INSTR ------------------//

  //================ Tmp ===============//
  struct Tmp {                          //
  //====================================//
    bool operator== (Tmp const&) const;

  private:
    typedef size_t id_type;
    id_type id;
    Tmp();
    Tmp(id_type);
    friend class Tmp_gen;
    friend std::ostream& operator<< (std::ostream&, Tmp const&); 
  }; //--------- end Tmp ---------------//

  //============ Tmp_gen ===========//
  struct Tmp_gen {                  //
  //================================//
    Tmp_gen();
    Tmp const * gen_tmp();

  private:
    struct Tmp_hash { size_t operator() (Tmp const& t) const; };
    typedef std::unordered_set<Tmp, Tmp_hash, std::equal_to<Tmp> > Tmp_container;

    Tmp_container tmps;
    Tmp::id_type last_id;

    static Tmp::id_type const INVALID_ID; 
  }; //--------- end Tmp_gen -------//

  //========= Helpers ===========//
  
  char const * const to_string( Op::Opcode );
  
};

#endif//__INTER_CODE_GEN__