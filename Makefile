LANG_NAME=pasclike
LEXER_EXECUTABLE=scanner-${LANG_NAME}
SCANNER_HEADER=${LANG_NAME}-scanner.h
CFLAGS=-DFILELOG_MAX_LEVEL=logINFO

${LEXER_EXECUTABLE}: main.cpp lex.yy.c ${LANG_NAME}.tab.h ${SCANNER_HEADER}
	g++  ${CFLAGS} lex.yy.c main.cpp -o ${LEXER_EXECUTABLE}

${LANG_NAME}.tab.c ${LANG_NAME}.tab.h: ${LANG_NAME}.y
	bison -d ${LANG_NAME}.y

lex.yy.c ${SCANNER_HEADER}: ${LANG_NAME}.l ${LANG_NAME}.tab.h
	flex --header-file=${SCANNER_HEADER} ${LANG_NAME}.l

clean:
	rm -fv *.o ${LEXER_EXECUTABLE} ${LANG_NAME}.tab.c ${LANG_NAME}.tab.h lex.yy.c ${SCANNER_HEADER}
