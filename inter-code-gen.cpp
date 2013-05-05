#include "inter-code-gen.h"

namespace cgen
{
  symdb::Invalid_type static_invalid;
  symdb::Invalid_type *invalid_type = &static_invalid;
  
  //================== Addr ===================//
  
  Addr::Addr( Var* _v ) :
    addr_type(VAR), 
    var(_v),
    resolution_type(NONE)
  { if( _v == NULL ) throw std::invalid_argument("Var *v is NULL");
    type = _v->type; }

  Addr::Addr( Lit* _lit ) :
    addr_type(LIT),
    lit(_lit),
    resolution_type(NONE)
  {
    if( _lit == NULL ) throw std::invalid_argument("Lit _lit is NULL");
    type = _lit->type; }

  Addr::Addr( Func* _func ) :
    addr_type(FUNC),
    func(_func),
    resolution_type(NONE)
  {
    if( _func == NULL ) throw std::invalid_argument("Func _func is NULL");
    type = _func->return_type; }

  Addr::Addr( Proc* _proc ) :
    addr_type(PROC),
    proc(_proc),
    resolution_type(NONE)
  {
    if( _proc == NULL ) throw std::invalid_argument("Proc _proc is NULL");
    type = invalid_type; }

  Addr::Addr( Tmp const* _tmp, Type* _type  ) :
    addr_type(TMP), 
    tmp(_tmp), 
    resolution_type(NONE),
    type(_type) { 
    if( _tmp == NULL ) throw std::invalid_argument("Tmp _tmp is NULL"); }

  Addr::Addr( Label const* _label ) :
    addr_type(LABEL),
    label(_label),
    resolution_type(NONE),
    type(invalid_type) {
    if( _label == NULL ) throw std::invalid_argument("Label _label is NULL"); }

  Var* Addr::get_var() const { 
    if( addr_type == VAR ) return var;
    throw std::logic_error("Address does not hold a var"); }

  Lit* Addr::get_lit() const {
    if( addr_type == LIT ) return lit;
    throw std::logic_error("Address does not hold a literal"); }

  Func* Addr::get_func() const {
    if( addr_type == FUNC ) return func;
    throw std::logic_error("Address does not hold a func"); }

  Proc* Addr::get_proc() const {
    if( addr_type == PROC ) return proc;
    throw std::logic_error("Address does not hold a proc"); }

  Tmp const* Addr::get_tmp() const { 
    if( addr_type == TMP ) return tmp;
    throw std::logic_error("Address does not hold a tmp"); }

  Label const* Addr::get_label() const { 
    if( addr_type == LABEL ) return label;
    throw std::logic_error("Address does not hold a label"); }

  Type* Addr::get_type() const   { return type; }

  void Addr::set_index( Addr * a ) {
    if( resolution_type != NONE && resolution_type != INDEX ) 
      throw std::logic_error("Cannot set address resolution: index");
    if( !type->is_valid() )  return;
    if( !type->is_array() )
      throw std::domain_error("Addr: Cannot index this type");
    type = dynamic_cast<symdb::Array_type*>(type)->base_type;
    index = a;
    resolution_type = INDEX; }

  void Addr::set_field( Addr * a ) {
    if( resolution_type != NONE && resolution_type != FIELD )
      throw std::logic_error("Cannot set address resolution: field");
    if( !type->is_valid() )  return;
    if( !type->is_record() )
      throw std::domain_error("Addr: Cannot select component of this type");
    if( a->addr_type != VAR )
      throw std::invalid_argument("Cannot set address resolution to non-field");
    symdb::Var *var = a->get_var();
    if( NULL == dynamic_cast<symdb::Record_type*>(type)->scope->get_sym( var ) )
      type = new symdb::Invalid_type();
    type = var->type;
    field = a;
    resolution_type = FIELD; }

  Addr * const Addr::get_index() const {
    if( resolution_type == INDEX )    return index;
    throw std::logic_error("Cannot get address resolution: index"); }

  Addr * const Addr::get_field() const {
    if( resolution_type == FIELD )    return field;
    throw std::logic_error("Cannot get address resolution: field"); }

  Addr::Resolution Addr::get_resolution_type() const {
    return resolution_type; }

  //=============== Operations ================//

  bool Op::is_binary( Op::Opcode op ) {
    switch( op ) {
    case MULT:
    case DIVIDE:
    case PLUS:
    case MINUS:
    case INDEXED_COPY: 
    case COPY_INDEXED:   
    case COMPONENT_COPY:
    case COPY_COMPONENT: return true;
    default:             return false; } }

  bool Op::is_unary( Op::Opcode op ) {
    switch( op ) {
    case UMINUS:
    case NOT:
    case COPY:
    case FUNCALL: return true;
    default:      return false;  } }

  bool Op::is_nonary( Op::Opcode op ) {
    switch( op ) {
    case PROCCALL:
    case LIT_ACCESS:
    case VAR_ACCESS:   return true;
    default:           return false; } }
  
  //================== Instr ==================//

  Instr::Instr( Op::Opcode _op, Addr *_arg1, Addr *_arg2, Addr *_res ) : 
    op(_op), arg1(_arg1), arg2(_arg2), res(_res) {
    if( _res == NULL ) throw std::invalid_argument("op: result address is NULL");

    if( Op::is_binary( _op ) ) {
      if( _arg1 == NULL )  throw std::invalid_argument("bin op: arg1 is NULL");
      if( _arg2 == NULL )  throw std::invalid_argument("bin op: arg2 is NULL");
    }
    else if( Op::is_unary( _op ) ) {
      if( _arg1 == NULL )  throw std::invalid_argument("unary op: arg1 is NULL");
      if( _arg2 != NULL )  throw std::invalid_argument("unary op: arg2 not NULL");
    }
    else if( Op::is_nonary( _op ) ) {
      if( _arg1 != NULL )  throw std::invalid_argument("unary op: arg1 not NULL");
      if( _arg2 != NULL )  throw std::invalid_argument("unary op: arg2 not NULL");
    }
  }

  //================== Tmp ====================//

  Tmp::Tmp() { }
  Tmp::Tmp(id_type _id) : id(_id) { }
  bool Tmp::operator== (Tmp const& t) const { return t.id == id; }

  //================= Label ===================//

  Label::Label() { }
  Label::Label(id_type _id) : id(_id) { }
  bool Label::operator== (Label const& l) const { return l.id == id; }

  //=============== Label_gen =================//

  Label_gen::Label_gen() : last_id( INVALID_ID ) {}

  Label const * Label_gen::gen_label() {
    auto p = labels.insert( Label(++last_id) );
    return &*p.first; }

  size_t Label_gen::Label_hash::operator() (Label const& l) const {
    return std::hash<typename Label::id_type>()(l.id); } 

  Label::id_type const Label_gen::INVALID_ID = 0;

  //================ Tmp_gen ==================//

  Tmp_gen::Tmp_gen() : last_id( INVALID_ID ) {}

  Tmp const * Tmp_gen::gen_tmp() {
    auto p = tmps.insert( Tmp(++last_id) );
    return &*p.first; }

  size_t Tmp_gen::Tmp_hash::operator() (Tmp const& t) const {
    return std::hash<typename Tmp::id_type>()(t.id); } 

  Tmp::id_type const Tmp_gen::INVALID_ID = 0;

  //=================== IO =====================//

  char const * const to_string( Op::Opcode o ) {
    switch( o ) {
    case Op::MULT:            return "*";
    case Op::DIVIDE:          return "/";
    case Op::PLUS:            return "+";
    case Op::MINUS:           return "-";
    case Op::MOD:             return "%";
    case Op::AND:             return "&&";
    case Op::OR:              return "||";
    case Op::INDEXED_COPY:    return "[]=";
    case Op::COPY_INDEXED:    return "=[]";
    case Op::UMINUS:          return "-";
    case Op::NOT:             return "not";
    case Op::COPY:            return "copy";
    case Op::FUNCALL:         return "funcall";
    case Op::PROCCALL:        return "call";
    case Op::LIT_ACCESS:      return "accl";
    case Op::VAR_ACCESS:      return "accv";
    case Op::PUSH_PARAM:      return "param";
    case Op::COMPONENT_COPY:  return ".=";
    case Op::COPY_COMPONENT:  return "=.";
    default:                  return "OP:UNK"; } }

  std::ostream& operator<< (std::ostream& os, Tmp const& t) {
    os << "t_" << t.id;  return os; }

  std::ostream& operator<< (std::ostream& os, Label const& l) {
    os << "LABEL_" << l.id;  return os; }
  
  std::ostream& operator<< (std::ostream& os, Instr const& i) {
    switch( i.op )
      {
      case Op::MULT:            // standard binary ops
      case Op::DIVIDE:
      case Op::PLUS: 
      case Op::MINUS:
      case Op::MOD:
      case Op::AND:
      case Op::OR:              os << *i.res << " := " 
				   << *i.arg1 
				   << ' ' << to_string(i.op) << ' '
				   << *i.arg2;                      break;

      case Op::INDEXED_COPY:    os << *i.res << '[' << *i.arg1 << "] := "
				   << *i.arg2;                      break;

      case Op::COPY_INDEXED:    os << *i.res << " := " << *i.arg1 
				   << '[' << *i.arg2 << ']';        break;

      case Op::COPY:            os << *i.res << " := " << *i.arg1;  break;

      case Op::NOT:             // standard unary ops
      case Op::UMINUS:
      case Op::FUNCALL:         os << *i.res << " := " 
				   << to_string(i.op) << ' '
				   << *i.arg1;                      break;
      case Op::LIT_ACCESS:      os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::VAR_ACCESS:      os << *i.res
				   << " ??? " << to_string(i.op);   break;

      case Op::PROCCALL:        // standard nonary ops
      case Op::PUSH_PARAM:      os << to_string(i.op) << ' '
				   << *i.res;                       break;

      case Op::COMPONENT_COPY:  os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::COPY_COMPONENT:  os << *i.res
				   << " ??? " << to_string(i.op);   break;
      default:
	os << *i.res << " ??? " << to_string(i.op);
      };

    return os << std::endl;
  }

  std::ostream& operator<< (std::ostream& os, Addr const& a) {
    switch( a.addr_type ) 
      {
      case Addr::TMP:   os << *a.get_tmp();          break;
      case Addr::VAR:   os << a.get_var()->name;     break;
      case Addr::LIT:   os << a.get_lit()->literal;  break;
      case Addr::FUNC:  os << a.get_func()->name;    break;
      case Addr::PROC:  os << a.get_proc()->name;    break;
      case Addr::LABEL: os << *a.get_label();        break;
      default:          os << "Addr:UNK"; }

    if     ( a.resolution_type == Addr::INDEX )   os << '[' << *a.index << ']';
    else if( a.resolution_type == Addr::FIELD )   os << '.' << *a.field;

    return os; }
};
