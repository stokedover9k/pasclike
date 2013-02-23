LANG_NAME=pasclike
LEXER_EXECUTABLE=lexan-${LANG_NAME}
CFLAGS=

${LEXER_EXECUTABLE}: lex.yy.c ${LANG_NAME}.tab.h
	g++ ${CFLAGS} lex.yy.c -o ${LEXER_EXECUTABLE}

${LANG_NAME}.tab.c ${LANG_NAME}.tab.h: ${LANG_NAME}.y
	bison -d ${LANG_NAME}.y

lex.yy.c: ${LANG_NAME}.l ${LANG_NAME}.tab.h
	flex ${LANG_NAME}.l

clean:
	rm -fv *.o ${LEXER_EXECUTABLE} ${LANG_NAME}.tab.c ${LANG_NAME}.tab.h lex.yy.c
