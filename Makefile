# These files will be packaged on call to target 'zip'
PACKAGE_FILES = loglib.h main-parser.cpp main-scanner.cpp Makefile parser-settings.cpp parser-settings.h pasclike.l pasclike.y README symbol-table.cpp symbol-table.h

LANG_NAME=pasclike
LEXER_EXECUTABLE=scanner-${LANG_NAME}
PARSER_EXECUTABLE=parser-${LANG_NAME}
SCANNER_HEADER=${LANG_NAME}-scanner.h

SCANNER_LOG_LVL_FOR_PARSER=logDEBUG1
SCANNER_LOG_LVL_FOR_SCANNER=logDEBUG4
PARSER_LOG_LVL_FOR_PARSER=logINFO
PARSER_LOG_LVL_FOR_SCANNER=logDEBUG4

FILELOG_MAX_LVL_DEBUG=logDEBUG2
FILELOG_MAX_LVL_DEFAULT=logINFO

######## choose one of the following ########
# FILELOG_MAX_LVL=${FILELOG_MAX_LVL_DEBUG}
FILELOG_MAX_LVL=${FILELOG_MAX_LVL_DEFAULT}
############################################

CFLAGS = -DFILELOG_MAX_LEVEL=$(FILELOG_MAX_LVL) -std=c++0x

${PARSER_EXECUTABLE}: CFLAGS += \
 -DSCANNER_LOG_LVL=${SCANNER_LOG_LVL_FOR_PARSER} \
 -DPARSER_LOG_LVL=${PARSER_LOG_LVL_FOR_PARSER}
${LEXER_EXECUTABLE}: CFLAGS += \
 -DSCANNER_LOG_LVL=$(SCANNER_LOG_LVL_FOR_SCANNER) \
 -DPARSER_LOG_LVL=$(PARSER_LOG_LVL_FOR_SCANNER)

${PARSER_EXECUTABLE}: lex.yy.c ${LANG_NAME}.tab.c ${LANG_NAME}.tab.h parser-settings.h parser-settings.cpp main-parser.cpp symbol-table.o
	g++ ${CFLAGS} ${LANG_NAME}.tab.c lex.yy.c parser-settings.cpp main-parser.cpp symbol-table.o -lfl -o ${PARSER_EXECUTABLE} 

${LEXER_EXECUTABLE}: lex.yy.c ${LANG_NAME}.tab.h ${SCANNER_HEADER} main-scanner.cpp symbol-table.o
	g++ $(CFLAGS) lex.yy.c main-scanner.cpp symbol-table.o -o ${LEXER_EXECUTABLE} 

${LANG_NAME}.tab.c ${LANG_NAME}.tab.h: ${LANG_NAME}.y parser-settings.h 
	bison -d ${LANG_NAME}.y

lex.yy.c ${SCANNER_HEADER}: ${LANG_NAME}.l ${LANG_NAME}.tab.h
	flex --header-file=${SCANNER_HEADER} ${LANG_NAME}.l

symbol-table.o: symbol-table.h symbol-table.cpp
	g++ $(CFLAGS) -c symbol-table.cpp
zip: 
	mkdir parser-skobov-yury
	cp ${PACKAGE_FILES} parser-skobov-yury/
	zip pasclike.zip parser-skobov-yury/*
	rm -rf parser-skobov-yury

clean:
	rm -fv *.o ${LEXER_EXECUTABLE} ${PARSER_EXECUTABLE} ${LANG_NAME}.tab.c ${LANG_NAME}.tab.h lex.yy.c ${SCANNER_HEADER}
