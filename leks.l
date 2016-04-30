%{
#include <stdlib.h>
#include <string.h>
#include "def.tab.hh"
extern int yylineno;
int yyerror(const char *msg, ...);
%}
%%
\{			{printf("poczatek-blok\n"); return '{';}
\}			{printf("koniec-blok\n"); return '}';}
"int"			{printf("int\n"); return INT;}
"real"			{printf("real\n"); return REAL;}
"char"			{printf("char\n"); return CHAR;}
"string"		{printf("string\n"); return STRING;}
"if"			{printf("if\n"); return IF;}
"then"          {printf("then\n"); return THEN;}
"else"			{printf("else\n"); return ELSE;}
"for"			{printf("for\n"); return FOR;}
"geti"			{printf("get\n"); return GETI;}
"getf"			{printf("get\n"); return GETF;}
"puti"			{printf("put\n"); return PUTI;}
"putf"			{printf("put\n"); return PUTF;}
\(			{printf("(\n"); return '(';}
\)			{printf(")\n"); return ')';}
\[			{printf("[\n"); return '[';}
\]			{printf("]\n"); return ']';}
\=			{printf("=\n"); return '=';}
\+			{printf("+\n"); return '+';}
\*			{printf("*\n"); return '*';}
\/			{printf("/\n"); return '/';}
\-			{printf("-\n"); return '-';}
\>			{printf(">\n"); return '>';}
\>=			{printf(">=\n"); return GEQ;}
\<			{printf("<\n"); return '<';}
\<=			{printf("<=\n"); return LEQ;}
\<>			{printf("<>\n"); return NEQ;}
\==			{printf("==\n"); return EQ;}
[1-9][0-9]*		{printf("liczba\n"); 
			 yylval.ival = atoi(yytext);
 			 return IV;}
[1-9][0-9]*[.][0-9]* 	{printf("liczba\n");
			 yylval.fval = atof(yytext);
			 return FV;}
[A-Za-z_][A-Za-z0-9_]*	{printf("nazwa\n");
			 yylval.text = strdup(yytext);
			 return ID;}
			 
\ |\t       {;}
\;			{printf("srednik\n"); return ';';}
\n			{printf("nowa linia\n"); yylineno++;}
.			{yyerror("B³±d leksykalny\n");}
%%
int yyerror(const char *msg,...)
{
	printf("%d: %s", yylineno, msg);
	exit(1);
}
