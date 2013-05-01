#ifndef __SCOPE_H__
#define __SCOPE_H__

#include "symbols.h"

#include <unordered_map>
#include <functional>
#include <stdexcept>

namespace symdb
{
  
  struct Sym_entry;
  struct Sym_scope;
  struct Scope_tree;
  struct Sym_table;

  //==============================//
  struct Sym_entry {              //
  //==============================//
    Sym_tag tag;
    Sym *sym;
    Sym_scope *scope;
    int offset;

    // throws std::invalid_argument if sym is NULL
    Sym_entry( Sym* sym, Sym_scope* = NULL, int offset = -1 );
  };

  //==============================//
  template <typename K,           // -key type
	    typename Hash,        // -type which hashes key type objects
	    typename Pred>        // -predicate which compares key type objects
  struct Sym_hasher_interface {   //
  //==============================//
    typedef K Key;
    typedef Hash Key_hash;
    typedef Pred Key_pred;
    
    virtual K gen_key( Sym const& ) const = 0;
  };

  //=============================================================//
  struct Sym_string_hasher                                       //
    : public Sym_hasher_interface<std::string,                   // -key
				  std::hash<std::string>,        // -hash
				  std::equal_to<std::string> > { // -predicate
  //=============================================================//
    typedef std::string Key;
    typedef std::hash<Key> Key_hash;
    typedef std::equal_to<Key> Key_pred;

    virtual std::string gen_key( Sym const& ) const;
  };

  //==============================//
  struct Sym_scope {              //
  //==============================//
    friend struct Scope_tree;
    
    typedef Sym_string_hasher SH;

    typedef SH::Key Key;
    typedef SH::Key_hash Key_hash;
    typedef SH::Key_pred Key_pred;

    typedef std::unordered_map<Key, Sym_entry, Key_hash, Key_pred> Sym_map;
    
    Sym_scope( Sym_scope * parent_scope = NULL );

    Sym_entry * get_sym( Sym const *sym );
    Sym_entry * add_sym( Sym *sym );
    bool add_success() const;
    Sym_scope * get_parent_scope() const;
    size_t get_alloc_size() const;
    void send_to( std::ostream&, std::string const& delim ) const;

    Sym_map::const_iterator begin() const;
    Sym_map::const_iterator end() const;

    friend std::ostream& operator<< (std::ostream&, Scope_tree const&);

  private:
    size_t alloc_size;
    Sym_map symbols;
    bool add_successful;
    Sym_scope * parent_scope;
  };

  //==========================//
  //---- helper functions ----//
  //==========================//
  std::ostream& operator<< (std::ostream&, Sym_scope const&);
  std::ostream& operator<< (std::ostream&, Sym_entry const&);
  std::ostream& operator<< (std::ostream&, Sym const&);

}; // end symdb

#endif//__SCOPE_H__
