/*
 * Logging system which flushes streams during destruction.
 * 
 * When using Ouput2FILE policy, the output file can be set using the 
 * Output2FILE::Stream() function.  Outputs to standard error by default.
 *
 * SAMPLE CODE: 
 *   Output2FILE::Stream() = fopen(file_name, "w");
 *   Log<Output2FILE>.Get(logWARNING) << "text of warning";
 *   Log<Output2FILE>.WriteLevel() = logINFO;
 *   Log<Output2FILE>.Write("value: %d", i_val);
 *
 * Two useful macros are defined after the class declarations.
 * SAMPLE CODE (with macros):
 *   LOG(logERROR) << "error text";
 *   LOG_WRITE(logDEBUG2)("val: %f", f_val);
 */

#ifndef __LOGLIB_H__
#define __LOGLIB_H__

#include <iostream>
#include <sstream>
#include <cstdio>
#include <cstdarg>

#define LOG_BUFFER_LENGTH 256

#ifndef FILELOG_MAX_LEVEL
#define FILELOG_MAX_LEVEL logDEBUG4
#endif

//-----------------------------------------------------------------------------

enum TLogLevel { logERROR, logWARNING, logINFO,
		 logDEBUG, logDEBUG1, logDEBUG2, logDEBUG3, logDEBUG4 };

const char * logLevelToString( TLogLevel l );

///////////////////////////////////////////////////////////////////////////////

template <typename OutputPolicy>
class Log
{
 public:
  
  ~Log();

  std::ostringstream& Get(TLogLevel lvl);

  void Write(const char* format, ...);

  static TLogLevel& ReportingLevel(void);
  static TLogLevel& WriteLevel(void);

 protected:
  
  std::ostringstream os;
};

///////////////////////////////////////////////////////////////////////////////

class Output2FILE {
 public:

  inline static void Output( const std::string& msg ) {
    FILE* pstream = Stream();
    if( pstream ) {
      fprintf( pstream, "%s\n", msg.c_str() );
      fflush( pstream );
    }
  }

  inline static FILE*& Stream() {
    static FILE* pstream = stderr;
    return pstream;
  }

};

///////////////////////////////////////////////////////////////////////////////

typedef Log<Output2FILE> FileLog;

#define LOG(level) \
  if (level > FILELOG_MAX_LEVEL) ;					\
  else if (level > FileLog::ReportingLevel() || !Output2FILE::Stream()) ; \
  else FileLog().Get(level)

#define LOGF(level) \
  if (level > FILELOG_MAX_LEVEL) ; \
  else if (level > FileLog::ReportingLevel() || !Output2FILE::Stream()) ; \
  else FileLog().WriteLevel() = level, FileLog().Write

///////////////////////////////////////////////////////////////////////////////

template <typename OutputPolicy>
Log<OutputPolicy>::~Log(void)  {
  OutputPolicy::Output( os.str() );
}

template <typename OutputPolicy>
std::ostringstream& Log<OutputPolicy>::Get(TLogLevel lvl) {
  os << "- " << logLevelToString(lvl) << ": "
     << std::string(lvl > logDEBUG ? lvl - logDEBUG : 0, '\t');
  
  return os; 
}

template <typename OutputPolicy>
void Log<OutputPolicy>::Write(const char* format, ...) {
  va_list args;
  va_start(args, format);
    
  char str[LOG_BUFFER_LENGTH];
  vsprintf(str, format, args);
  va_end(args);

  Get(WriteLevel()) << str;
}

template <typename OutputPolicy>
TLogLevel& Log<OutputPolicy>::ReportingLevel(void) {
  static TLogLevel _reporting_level = FILELOG_MAX_LEVEL;
  return _reporting_level;
}

template <typename OutputPolicy>
TLogLevel& Log<OutputPolicy>::WriteLevel(void) {
  static TLogLevel _write_level = logINFO;
  return _write_level;
}

//-----------------------------------------------------------------------------

inline const char * logLevelToString( TLogLevel l ) {
  switch(l)
    {
    case logERROR:    return "ERROR";
    case logWARNING:  return "WARNING";
    case logINFO:     return "INFO";
    default:          return "DEBUG";
    }
}

#endif  /* __LOGLIB_H__ */
