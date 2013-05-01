#ifndef __SYMBOLS_H__
#define __SYMBOLS_H__

#include <string>
#include <list>
#include <utility>

#include <iostream>

namespace symdb
{
  enum Sym_tag { LIT_TAG, TYPE_TAG, VAR_TAG, PROC_TAG, FUNC_TAG };

  struct Sym;
  struct Sym_scope;

  struct Sym;        // parent of the following types:
  struct Lit;
  struct Type;
  struct Var;
  struct Proc;
  struct Func;

  struct Type;       // parent of the following types:
  struct Named_type;
  struct Int_type;
  struct Bool_type;
  struct String_type;
  struct Array_type;
  struct Record_type;
  struct Invalid_type;

  struct Sym { 
    virtual Sym_tag get_entry_tag() const = 0;
    virtual size_t get_alloc_size() const;
    virtual void send_to( std::ostream& ) const = 0; };

  ////----------------------------------////
  ////---- Types inherited from Sym ----////
  ////----------------------------------////

  //======================================//
  struct Lit : public Sym {               //
  //======================================//
    std::string literal;
    Type *type;

    virtual Sym_tag get_entry_tag() const;
    Lit(std::string const& literal);
    virtual void send_to( std::ostream& ) const; };
  
  //======================================//
  struct Type : public Sym {              //
  //======================================//
    bool is_int()    const;
    bool is_bool()   const;
    bool is_string() const;
    bool is_array()  const;
    bool is_record() const;
    bool is_valid()  const;

    enum Type_tag { INVALID_TYPE_TAG,
		    INT_TYPE_TAG,
		    BOOL_TYPE_TAG,
		    STRING_TYPE_TAG,
		    ARRAY_TYPE_TAG,
		    RECORD_TYPE_TAG };

    virtual Type *get_type();
    virtual Type const *get_type() const;
    virtual Type_tag get_type_tag() const = 0;
    virtual std::string get_type_name() const;
    virtual Sym_tag get_entry_tag() const;
    virtual void send_to( std::ostream& ) const; };


  //======================================//
  struct Var : public Sym {               //
  //======================================//
    std::string name;
    Type *type;
    //
    virtual Sym_tag get_entry_tag() const;
    Var(std::string const& _name, Type *_type);
    virtual size_t get_alloc_size() const;
    virtual void send_to( std::ostream& ) const; };

  //======================================//
  struct Proc : public Sym {              //
  //======================================//
    std::string name;
    Sym_scope *scope;
    std::list<Var *> formals; 
    //
    virtual Sym_tag get_entry_tag() const;
    Proc(std::string const& _name);
    virtual void send_to( std::ostream& ) const; };

  //======================================//
  struct Func : public Sym {              //
  //======================================//
    std::string name;
    Sym_scope *scope;
    std::list<Var *> formals;
    Type *return_type;
    //
    virtual Sym_tag get_entry_tag() const;
    Func(std::string const& _name);
    virtual void send_to( std::ostream& ) const; };

  ////-----------------------------------////
  ////---- Types inherited from Type ----////
  ////-----------------------------------////

  //======================================//
  struct Int_type : public Type {         //
  //======================================//
    virtual Type_tag get_type_tag() const; };

  //======================================//
  struct Bool_type : public Type {        //
  //======================================//
    virtual Type_tag get_type_tag() const; };

  //======================================//
  struct String_type : public Type {      //
  //======================================//
    virtual Type_tag get_type_tag() const; };

  //======================================//
  struct Array_type : public Type {       //
  //======================================//
    typedef std::pair<int, int> Range;
    //
    Range range;
    Type *base_type;
    //
    Array_type();
    virtual Type_tag get_type_tag() const;
    virtual void send_to( std::ostream& ) const; };

  //======================================//
  struct Record_type : public Type {      //
  //======================================//
    Sym_scope *scope;
    //
    Record_type();
    virtual Type_tag get_type_tag() const;
    virtual void send_to( std::ostream& ) const; };

  //======================================//
  struct Invalid_type : public Type {     //
  //======================================//
    virtual Type_tag get_type_tag() const; };
  
  //======================================//
  struct Named_type : public Type {       //
  //======================================//
    std::string name;
    Type *refers_to;
    //
    Named_type( std::string const& _name );
    virtual Type *get_type();
    virtual Type const *get_type() const;
    virtual std::string get_type_name() const;
    virtual Type_tag get_type_tag() const;
    virtual void send_to( std::ostream& ) const; };

  //==========================//   two methods for displaying tags described in
  //---- helper functions ----//   this file: general Type_tag's and specific
  //==========================//   Type_tag's.
  char const * sym_tag_to_string( Sym_tag );
  char const * type_tag_to_string( Type::Type_tag tag );

}; // end symdb

#endif//__SYMBOLS_H__
