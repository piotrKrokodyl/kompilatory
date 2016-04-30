CC=gcc
CPP=g++ --std=c++11
LEX=flex
YACC=bison
LD=gcc

all:	leks

leks:	def.tab.o lex.yy.o
	$(CPP) lex.yy.o def.tab.o -o leks -ll

lex.yy.o:	lex.yy.c
	$(CC) -c lex.yy.c

lex.yy.c: leks.l
	$(LEX) leks.l

def.tab.o:	def.tab.cc
	$(CPP) -c def.tab.cc

def.tab.cc:	def.yy
	$(YACC) -d def.yy

clean:
	rm *.o leks
