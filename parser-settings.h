#ifndef __PARSER_SETTINGS_H__
#define __PARSER_SETTINGS_H__

#include <iostream>

//-------- parser output -----------
extern std::ostream rulesLog;
//----------------------------------

#include "loglib.h"

// used solely to allos an additional log
class Output2FILE2 {
 public:

  inline static void Output( const std::string& msg ) {
    FILE* pstream = Stream();
    if( pstream ) {
      fprintf( pstream, "%s\n", msg.c_str() );
      fflush( pstream );
    }
  }

  inline static FILE*& Stream() {
    static FILE* pstream = stdout;
    return pstream;
  }
};

typedef Log<Output2FILE2> ErrLog;

#define ERRLOG \
  if (logERROR > FILELOG_MAX_LEVEL) ;					\
  else if (logERROR > ErrLog::ReportingLevel() || !Output2FILE2::Stream()) ; \
  else ErrLog().Get(logERROR)


#endif //__PARSER_SETTINGS_H__
