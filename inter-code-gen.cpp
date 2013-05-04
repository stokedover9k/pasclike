#include "inter-code-gen.h"

namespace cgen
{

  //================== Addr ===================//
  
  Addr::Addr( Var* _v ) :
    addr_type(VAR), 
    var(_v),
    resolution_type(NONE)
  { if( _v == NULL ) throw std::invalid_argument("Var *v is NULL");
    //std::cout << "addr var: " << *var << std::endl;
    type = _v->type; }

  Addr::Addr( Lit* _lit ) :
    addr_type(LIT),
    lit(_lit),
    resolution_type(NONE)
  {
    if( _lit == NULL ) throw std::invalid_argument("Lit _lit is NULL");
    //std::cout << "addr lit: " << *lit << std::endl;
    type = _lit->type; }

  Addr::Addr( Func* _func ) :
    addr_type(FUN),
    func(_func),
    resolution_type(NONE)
  {
    if( _func == NULL ) throw std::invalid_argument("Func _func is NULL");
    //std::cout << "addr fun: " << *func << std::endl;
    type = _func->return_type; }

  Addr::Addr( Tmp const* _tmp, Type* _type  ) :
    addr_type(TMP), 
    tmp(_tmp), 
    resolution_type(NONE),
    type(_type) { 
    //std::cout << "addr tmp: " << *tmp << std::endl; 
  }

  Var* Addr::get_var() const { 
    if( addr_type == VAR ) return var;
    throw std::logic_error("Address does not hold a var"); }

  Lit* Addr::get_lit() const {
    if( addr_type == LIT ) return lit;
    throw std::logic_error("Address does not hold a literal"); }

  Tmp const* Addr::get_tmp() const { 
    if( addr_type == TMP ) return tmp;
    throw std::logic_error("Address does not hold a tmp"); }

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
      // arg2 should be null
    }
    else if( Op::is_nonary( _op ) ) {
      // both args should be null
    }
    //std::cout << to_string(_op) << std::endl;
  }

  //================== Tmp ====================//

  Tmp::Tmp() { }
  Tmp::Tmp(id_type _id) : id(_id) { }
  bool Tmp::operator== (Tmp const& t) const { return t.id == id; }

  Tmp::id_type const Tmp_gen::INVALID_ID = 0;

  //================ Tmp_gen ==================//

  Tmp_gen::Tmp_gen() : last_id( INVALID_ID ) {}

  Tmp const * Tmp_gen::gen_tmp() {
    auto p = tmps.insert( Tmp(++last_id) );
    return &*p.first; }

  size_t Tmp_gen::Tmp_hash::operator() (Tmp const& t) const {
    return std::hash<typename Tmp::id_type>()(t.id); } 

  //=================== IO =====================//

  char const * const to_string( Op::Opcode o ) {
    switch( o ) {
    case Op::MULT:            return "*";
    case Op::DIVIDE:          return "/";
    case Op::PLUS:            return "+";
    case Op::MINUS:           return "-";
    case Op::INDEXED_COPY:    return "[]=";
    case Op::COPY_INDEXED:    return "=[]";
    case Op::UMINUS:          return "neg";
    case Op::NOT:             return "not";
    case Op::COPY:            return "copy";
    case Op::FUNCALL:         return "callf";
    case Op::LIT_ACCESS:      return "accl";
    case Op::VAR_ACCESS:      return "accv";
    case Op::COMPONENT_COPY:  return ".=";
    case Op::COPY_COMPONENT:  return "=.";
    default:                  return "OP:UNK"; } }

  std::ostream& operator<< (std::ostream& os, Tmp const& t) {
    os << "t_" << t.id;  return os; }
  
  std::ostream& operator<< (std::ostream& os, Instr const& i) {
    switch( i.op )
      {
      case Op::MULT:            os << *i.res 
				   << " ??? " << to_string(i.op);   break;
      case Op::DIVIDE:          os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::PLUS:            os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::MINUS:           os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::INDEXED_COPY:    os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::COPY_INDEXED:    os << *i.res
				   << " := " << *i.arg1 
				   << '[' << *i.arg2 << ']';        break;
      case Op::UMINUS:          os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::NOT:             os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::COPY:            os << *i.res 
				   << " := " 
				   << *i.arg1;                      break;
      case Op::FUNCALL:         os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::LIT_ACCESS:      os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::VAR_ACCESS:      os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::COMPONENT_COPY:  os << *i.res
				   << " ??? " << to_string(i.op);   break;
      case Op::COPY_COMPONENT:  os << *i.res
				   << " ??? " << to_string(i.op);   break;
      };

    return os << std::endl;
  }

  std::ostream& operator<< (std::ostream& os, Addr const& a) {
    switch( a.addr_type ) 
      {
      case Addr::VAR:  os << a.get_var()->name;     break;
      case Addr::LIT:  os << a.get_lit()->literal;  break;
      case Addr::TMP:  os << *a.get_tmp();          break;
      default:         os << "Addr:UNK"; }

    if     ( a.resolution_type == Addr::INDEX )   os << '[' << *a.index << ']';
    else if( a.resolution_type == Addr::FIELD )   os << '.' << *a.field;

    return os; }
};
