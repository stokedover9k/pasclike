#ifndef __INTER_CODE_GEN__
#define __INTER_CODE_GEN__

#include "symtable.h"
#include <unordered_set>
#include <ostream>
#include <stdexcept>
#include <utility>

namespace cgen
{
  using symdb::Var;
  using symdb::Lit;
  using symdb::Func;
  using symdb::Proc;
  using symdb::Type;
  
  struct Tmp;
  struct Addr;
  struct Instr;
  struct Operation;
  struct Label;
  struct Expr;

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
    Addr( Proc* );
    Addr( Tmp const*, Type* );
    Addr( Label const* );

    Var*         get_var() const;
    Lit*         get_lit() const;
    Func*        get_func() const;
    Proc*        get_proc() const;
    Tmp const*   get_tmp() const;
    Label const* get_label() const;
    Type*        get_type() const;
    
    void set_index( Addr * );
    void set_field( Addr * );
    Addr * const get_index() const;
    Addr * const get_field() const;
    Resolution get_resolution_type() const;

    friend std::ostream& operator<< (std::ostream& os, Addr const& a);

  private:
    enum ADDR_TYPE { VAR, TMP, LIT, FUNC, PROC, LABEL } addr_type;

    union {
      Tmp const* tmp;
      Var* var;
      Lit* lit;
      Func* func;
      Proc* proc;
      Label const* label; };

    Resolution resolution_type;

    union {
      Addr *index;
      Addr *field; };

    Type* type; 
  }; //----------- end ADDR -------------------//

  //============== OPERATION ==================//
  struct Op { enum Opcode {                    //
  //===========================================//
      MULT, DIVIDE, PLUS, MINUS, MOD,          // binary:  x = y op z
      AND, OR,                                 //
      LT, LE, GT, GE, EQ, NE,                  //
      IF_LT_GOTO, IF_GT_GOTO,                  //
      INDEXED_COPY,                            //          x[y] = z
      COPY_INDEXED,                            //          x = y[z]
      COMPONENT_COPY,                          //          x.y = z
      COPY_COMPONENT,                          //          x = y.z
      UMINUS, NOT, COPY, FUNCALL, PROCCALL,    // unary:   x = op y
      IF_TRUE_GOTO, IF_FALSE_GOTO,             //
      PUSH_PARAM, LABEL,                       // nonary:  x
      GOTO,                                    //
      LIT_ACCESS, VAR_ACCESS,                  //
      FUNCRETURN, PROCRETURN                   //
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

  //============ Label =============//
  struct Label {                    //
  //================================//
    bool operator== (Label const&) const;

  private:
    typedef size_t id_type;
    id_type id;
    std::string text;
    Label();
    Label(id_type, std::string = "");
    friend class Label_gen;
    friend std::ostream& operator<< (std::ostream&, Label const&);
  }; //-------- end Label ----------//

  //=========== Label_gen ==========//
  struct Label_gen {                //
  //================================//
    Label_gen();
    Label const * gen_label();
    Label const * gen_label(std::string const& name);

  private:
    struct Label_hash { size_t operator() (Label const& t) const; };
    typedef std::unordered_set<Label, Label_hash, std::equal_to<Label> > Label_container;

    Label_container labels;
    Label::id_type last_id;

    static Label::id_type const INVALID_ID; 
  }; //------- end Label_gen -------//

  //============ Expr ==============//
  struct Expr {                     //
  //================================//
    Expr( Addr * );
    Expr( Expr const & );

    Addr *addr;
    bool is_bool() const;
    Type * get_type() const;
    Label const * get_branch( bool ) const;
    Label const * set_branch( bool, Label const * );
    void flip_branches();
    
  private:
    Label const * label_true;
    Label const * label_false;
  };
  
  //============ Helpers ===========//

  char const * const to_string( Op::Opcode );
  
};

#endif//__INTER_CODE_GEN__
