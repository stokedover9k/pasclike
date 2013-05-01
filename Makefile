
lang=pasclike
parser_EXECUTABLE = parser-${lang}
parser_INCLUDE_DIRS := lib-sym-table
parser_LIB_DIRS := lib-sym-table
parser_LIBS := symdb
scanner_HEADER = lex.yy.h

CXXFLAGS += $(foreach includedir,$(parser_INCLUDE_DIRS),-I$(includedir))
CXXFLAGS += -std=c++0x
CXXFLAGS += -DFILELOG_MAX_LEVEL=$(FILELOG_MAX_LVL) -DSCANNER_LOG_LVL=$(SCANNER_LOG_LVL_FOR_PARSER) -DPARSER_LOG_LVL=$(PARSER_LOG_LVL_FOR_PARSER)
LDFLAGS += $(foreach librarydir,$(parser_LIB_DIRS),-L$(librarydir))
LDFLAGS += $(foreach library,$(parser_LIBS),-l$(library))

PARSER_LOG_LVL_FOR_PARSER=logINFO
SCANNER_LOG_LVL_FOR_PARSER=logDEBUG2

FILELOG_MAX_LVL=logDEBUG2

parser_C_SRCS             := 
parser_CXX_SRCS           := parser-settings.cpp main-parser.cpp
parser_GENERATED_C_SRCS   := 
parser_GENERATED_CXX_SRCS := pasclike.tab.cpp lex.yy.cpp

parser_C_OBJS   := ${parser_C_SRCS:.c=.o} ${parser_GENERATED_C_SRCS:.c=.o}
parser_CXX_OBJS := ${parser_CXX_SRCS:.cpp=.o} ${parser_GENERATED_CXX_SRCS:.cpp=.o}
parser_OBJS     := ${parser_C_OBJS} ${parser_CXX_OBJS}

.PHONY: all clean libs

all: ${parser_EXECUTABLE} 

${parser_EXECUTABLE}: ${parser_OBJS} libs
	$(LINK.cc) $(parser_OBJS) -lfl -o $(parser_EXECUTABLE) $(LDFLAGS)

libs:
	$(MAKE) -C lib-sym-table

main-parser.o : pasclike.tab.h

pasclike.tab.cpp pasclike.tab.h: pasclike.y parser-settings.h 
	bison --output=pasclike.tab.cpp -d ${lang}.y
	mv pasclike.tab.hpp pasclike.tab.h

lex.yy.cpp lex.yy.h: pasclike.l pasclike.tab.h
	flex --outfile=lex.yy.cpp --header-file=lex.yy.h pasclike.l

clean:
	rm -fv ${parser_OBJS} ${LEXER_EXECUTABLE} ${PARSER_EXECUTABLE} ${lang}.tab.cpp ${lang}.tab.h lex.yy.cpp lex.yy.h ${SCANNER_HEADER}

main-parser.h:
	#imagining main-parser.h

zip:
	zip parser.zip lib-sym-table/* loglib.h main-parser.cpp main-scanner.cpp Makefile parser-settings.cpp parser-settings.h pasclike.l pasclike.y README scope_tree.h type_tests/*

define OBJECT_DEPENDS_ON_CORRESPONDING_HEADER
        $(1) : ${1:.o=.h}
endef

$(foreach object_file,$(parser_OBJS),$(eval $(call OBJECT_DEPENDS_ON_CORRESPONDING_HEADER,$(object_file))))