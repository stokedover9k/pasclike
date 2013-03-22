#ifndef __PARSER_SETTINGS_H__
#define __PARSER_SETTINGS_H__

#include <iostream>
#include <set>
#include <vector>
#include <cstddef>

//-------- parser output -----------
extern std::ostream rulesLog;
//----------------------------------

//-------- parser symbol table -----
struct SymRecord;  // symbol record
struct SymIdLess;  // comparator
typedef std::set<SymRecord, SymIdLess> SymDB;

extern SymDB symTable;
extern std::string const SYM_NIL_TYPE;

void addSymbol( std::string const& id, std::string const& type );

std::vector<SymRecord> toVector( SymDB const& );
//----------------------------------

#endif //__PARSER_SETTINGS_H__
