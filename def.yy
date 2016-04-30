%{
#include <string.h> // For C style strings. I guess there's no need for that here.
#include <string>
#include <stdio.h>
#include <stack>
#include <sstream>
#include <iostream>
#include <vector>
#include <fstream>
#include <map>

extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);

using namespace std;

FILE* plikONP;
FILE* plikTrojki;
FILE* plikASM;

vector<string> code;
vector<string> prolog;

void zapisTrojki(string);
void wypelnijProlog();
void write(vector<string>);

//add for IF and '='
void conditExp();
void conditionalEnd(int tempElse);
void storeConditOp(string op);
string conditionalOp;
void closeElse();

void inputInt(string id);
void printInt(string id);
void idlvalueFun(string id);

stack <string> labels;
stack <string> labelsElse;

struct elementStruktura
{
	int typ;
	string wartosc;
};

struct symbolStruktura
{
    int typ;
    string nazwa;
};

stack <elementStruktura> stos;
elementStruktura wypelnijStruktureElement(int, string);

symbolStruktura wypelnijStruktureSymbol(int, string);

//TODO zrobic funkcje do wpisywania nazwy, tak aby sprawdzalo czy nazwa sie nie powtorzyla
map<string, symbolStruktura> symbole;

template<typename T> 
string toString(T value)
{
	stringstream sstream;
	sstream << value;
	return sstream.str();
}
%}
%union 
{float fval;
char *text;
int	ival;};
%token <fval> FV
%token <text> ID
%token <ival> IV
%token DO WHILE
%token FOR
%token NEQ EQ GEQ LEQ
%token INT REAL
%token CHAR STRING
%token IF THEN ELSE
%token GETI GETF PUTI PUTF 
%%
statements
	:statement ';'
	|statement ';' statements
	;

statement 
	:wyr-lin
	|blok
	|wp
	|if_stat
	|tab
	;
	
tab
    :INT ID'['IV']' {
                printf("deklaracja tablicy INT\n");
                //createIntTable($4);
    }
    |REAL ID'['FV']' {
                printf("deklaracja tablicy FLOAT\n");
    }
    ;

blok
    :'{' statements '}'
    ;

wyr-lin
    :GETI '(' ID ')'  {
                printf("GETI\n");
                /*
                code.push_back("li $v0,5");
                code.push_back("syscall");
                symbolStruktura tempSymbol = wypelnijStruktureSymbol(IV, $3);
                symbole[$3] = tempSymbol;
                code.push_back("sw $v0," + toString($3));
                */
                printInt($3);
            }
    |GETF   {       
                printf("GETF\n");
            }
    |PUTI '(' ID ')'  {
                printf("PUTI\n");
                /*
                code.push_back("li $v0,1");
                
                symbolStruktura tempSymbol = wypelnijStruktureSymbol(IV, $3);
                symbole[$3] = tempSymbol;
                
                code.push_back("lw $a0," + toString($3));
                code.push_back("syscall");
                
                //code.push_back("sw $v0," + toString($3));
                */
                inputInt($3);
            }
    |PUTF   {
                printf("PUTF\n");   
            }
    ;
    
if_stat
    :if_begin statement
	|if_begin blok { conditionalEnd(0); }
	|if_begin blok { conditionalEnd(1); } ELSE blok {closeElse(); }
	;
	
if_begin
	:IF '('condit_exp')' THEN	{ conditExp(); }
	;
	
condit_exp
	:wyr '>' wyr	{printf("wyrazenie if > \n"); storeConditOp(">");}
	|wyr '<' wyr	{printf("wyrazenie if < \n"); storeConditOp("<");}
	|wyr LEQ wyr    {printf("wyrazenie if <= \n"); storeConditOp("<=");}//<=
	|wyr GEQ wyr	{printf("wyrazenie if >= \n"); storeConditOp(">=");}//>=
	|wyr EQ wyr		{printf("wyrazenie if == \n"); storeConditOp("==");}//==
	|wyr NEQ wyr	{printf("wyrazenie if <> \n"); storeConditOp("<>");}//<>
	;
	            
wp
    :lvalue '=' wyr {
                        printf("wyrazenie przypisania\n");
                        zapisTrojki("=");
                        /*
                        li $t1,5
                        sw $t1,a
                        */
                    }

lvalue
    :ID {
            /*
			printf("czynnik znakowy jako lvalue\n");
			fprintf(plikONP, " %s ", $1);
			elementStruktura temp = wypelnijStruktureElement(ID, $1);
			stos.push(temp);
			
			symbolStruktura tempStrukturka = wypelnijStruktureSymbol(IV, $1);
            symbole[$1] = tempStrukturka;
            */
            idlvalueFun($1);
		}
    
wyr
	:wyr '+' skladnik	{
							printf("wyrazenie z + \n");
				 			fprintf(plikONP, " + ");
							zapisTrojki("add");
						}
				    
	|wyr '-' skladnik	{
							printf("wyrazenie z - \n");
				 			fprintf(plikONP, " - ");
				 			zapisTrojki("sub");
				 		}
				 		
	|skladnik		{
						printf("wyrazenie pojedyncze \n");
					}
	;
	
skladnik
	:skladnik '*' czynnik	{
								printf("skladnik z * \n");
				 				fprintf(plikONP, " * ");
				 				zapisTrojki("mul");
				 			}
				 			
	|skladnik '/' czynnik	{
								printf("skladnik z / \n");
				 				fprintf(plikONP, " / ");
				 				zapisTrojki("div");
				 			}
				 			
	|czynnik				{
								printf("skladnik pojedynczy \n");
							}
	;
czynnik	
	:ID	{
			printf("czynnik znakowy\n");
			fprintf(plikONP, " %s ", $1);
			elementStruktura temp = wypelnijStruktureElement(ID, $1);
			stos.push(temp);
		}
		 
	|IV	{
			printf("czynnik liczbowy\n");
			fprintf(plikONP, " %d ", $1);
			//stos.push(toString($1));
			elementStruktura temp = wypelnijStruktureElement(IV, toString($1));
			stos.push(temp);
		}
		
	|FV	{
			printf("czynnik liczbowy - float\n");
			fprintf(plikONP, " %f ", $1);
			//stos.push(toString($1));
			elementStruktura temp = wypelnijStruktureElement(FV, toString($1));
			stos.push(temp);
		}
	|'(' wyr ')'	{
						printf("wyrazenie w nawiasach\n");
					}
	;

%%
void zapisTrojki(string operation)
{
	int pierwszySkladnik, drugiSkladnik; 
	string wynik;
	elementStruktura szczytStosu2 = stos.top();
	sscanf(szczytStosu2.wartosc.c_str(), "%d", &pierwszySkladnik);
	stos.pop();
	elementStruktura szczytStosu1 = stos.top();
	sscanf(szczytStosu1.wartosc.c_str(), "%d", &drugiSkladnik);
	stos.pop();
	
	string ustalenieTypu = "i";
	if(szczytStosu1.typ == ID)
		ustalenieTypu = "w";
		
	//edit
	if(operation=="="){
	    ustalenieTypu = "i";
	    if(szczytStosu2.typ == ID)
			ustalenieTypu = "w";

		code.push_back("l" + ustalenieTypu + " $t1, " + szczytStosu2.wartosc);
		code.push_back("sw $t1, "+ szczytStosu1.wartosc );
	} else {
		
	    code.push_back("l" + ustalenieTypu + " $t1, " + szczytStosu1.wartosc);
	
	    ustalenieTypu = "i";
	    if(szczytStosu2.typ == ID)
	    	ustalenieTypu = "w";
		
	    code.push_back("l" + ustalenieTypu + " $t2, " + szczytStosu2.wartosc);
        code.push_back(operation + " $t1, $t1, $t2");
	    
	    
	    static int counter = 1;
	    wynik = "t" + toString(counter);
	
	    // mozna zbic w jedna linijke
	    symbolStruktura tempSymbol = wypelnijStruktureSymbol(IV, wynik); 
	    symbole[wynik] = tempSymbol;
	
	    code.push_back("sw $t1, " + wynik);
	
	    elementStruktura temp = wypelnijStruktureElement(ID, wynik);
	
	    counter++;
	
	    stos.push(temp);
	    fprintf(plikTrojki, "\n %s \n", toString(wynik).c_str());
	}
}

void conditionalEnd(int tempElse)
{
	
	string label= labels.top();
	labels.pop();

	if(tempElse==1)
	{
		static int counterElse=0;
		string labelElse = "etykietaElse" + toString(counterElse++);
		labelsElse.push(labelElse);		
		//string labelElse = labels.top(); //nie zdejmuje - zdejmujemy za blokiem
		code.push_back("j "+labelElse);
	}

	code.push_back(label+ ":");
}

void closeElse()
{
	string labelElse = labelsElse.top();
	labelsElse.pop();
	code.push_back(labelElse+":");
}

void conditExp()
{
	static int labelCount=0;
	string labelName="etykieta" + toString(labelCount);	
	labelCount++;

	int pierwszySkladnik, drugiSkladnik; 
	string wynik;
	elementStruktura szczytStosu2 = stos.top();
	sscanf(szczytStosu2.wartosc.c_str(), "%d", &pierwszySkladnik);
	stos.pop();
	elementStruktura szczytStosu1 = stos.top();
	sscanf(szczytStosu1.wartosc.c_str(), "%d", &drugiSkladnik);
	stos.pop();
	
	string ustalenieTypu = "i";
	if(szczytStosu1.typ == ID)
		ustalenieTypu = "w";
		
	code.push_back("l" + ustalenieTypu + " $t1, " + szczytStosu1.wartosc);
	
	ustalenieTypu = "i";
	if(szczytStosu2.typ == ID)
		ustalenieTypu = "w";

	code.push_back("l" + ustalenieTypu + " $t2, " + szczytStosu2.wartosc);		

	labels.push(labelName);

	/*if(tempElse==1)
	{
		string labelNameElse="etykieta" + toString(labelCount);
		labels.push(labelNameElse); //umyslnie wrzucam jako druga - bo zdejme jako druga
		labelCount++;
		
	}*/

	if(conditionalOp==">")
	{
		code.push_back("sub $t1, $t1, $t2");
		code.push_back("blez $t1, "+labelName);
	}
	else if(conditionalOp==">=")
	{
		code.push_back("sub $t1, $t1, $t2"); 
		code.push_back("bltz $t1, "+labelName);
	}
	else if(conditionalOp=="<")
	{
		code.push_back("sub $t1, $t1, $t2"); 
		code.push_back("bgez $t1, "+labelName);
	}
	else if(conditionalOp=="<=")
	{
		code.push_back("sub $t1, $t1, $t2"); 
		code.push_back("bgtz $t1, "+labelName);
	}
	else if(conditionalOp=="==")
	{
		code.push_back("sub $t1, $t1, $t2"); //co tutaj ????? wszedzie sub??
		code.push_back("beq $t1, "+labelName);
	}
	else if(conditionalOp=="<>")
	{
		code.push_back("sub $t1, $t1, $t2");
		code.push_back("bne $t1, "+labelName);
	}

				
	
}


void storeConditOp(string op)
{
	conditionalOp = op;
}


void inputInt(string id)
{
	code.push_back("li $v0, 5");
	code.push_back("syscall");
	struct symbolStruktura tempSymbol = wypelnijStruktureSymbol(ID, id);
	symbole[id] = tempSymbol;
	code.push_back("sw $v0, " + toString(id));
}


void printInt(string id)
{
	code.push_back("li $v0, 1");
	struct symbolStruktura tempSymbol = wypelnijStruktureSymbol(IV, id);
	symbole[id] = tempSymbol;
	code.push_back("lw $t0," + toString(id));
	code.push_back("la $a0, ($t0)");
	code.push_back("syscall");
}


void idlvalueFun(string id)
{
	//fprintf(fileONP, " %s ", id.c_str());
	//fprintf(fileTrojki, " %s ", id.c_str());
	elementStruktura temp = wypelnijStruktureElement(ID, toString(id));
	stos.push(temp);
	symbolStruktura tempSymbol = wypelnijStruktureSymbol(ID, toString(id));
	symbole[id] = tempSymbol;
}

elementStruktura wypelnijStruktureElement(int typ, string wartosc)
{
	elementStruktura strukturka;
	strukturka.typ = typ;
	strukturka.wartosc = wartosc;
	return strukturka;
}

symbolStruktura wypelnijStruktureSymbol(int typ, string nazwa)
{
	symbolStruktura strukturka;
	strukturka.typ = typ;
	strukturka.nazwa = nazwa;
	return strukturka;
}



void wypelnijProlog()
{
	prolog.push_back(".data");
	/*
	prolog.push_back("x: .word 1");
	prolog.push_back("t1: .word 0");
	prolog.push_back("t2: .word 0");
	prolog.push_back("t3: .word 0");
	prolog.push_back("t4: .word 0");
	*/
	
	typedef map<string, symbolStruktura>::iterator cur;
	for(cur iterator = symbole.begin(); iterator != symbole.end(); ++iterator)
	{
		string typ="";
		// ani razu nie odpalilo
		if(iterator->second.typ == IV) typ = ".word 0";
		prolog.push_back(iterator->second.nazwa + ": "+typ);
	}
	
	prolog.push_back(".text");
	prolog.push_back("main:");
}

void write(vector<string> vectorDoZapisania)
{
	ofstream plikASM("out.asm", ofstream::app);
	
	for(auto s : vectorDoZapisania)
	{
		plikASM << s << endl;
	}
	
	plikASM.close();
}

int main(int argc, char *argv[])
{
	plikONP = fopen("ONP.txt", "w");
	plikTrojki = fopen("trojki.txt", "w");
	ofstream plikASM("out.asm", ofstream::out);
	plikASM.close();
	
	yyparse();
	
	wypelnijProlog();
	write(prolog);
	write(code);
	
	fclose(plikONP);
	fclose(plikTrojki);
	return 0;
}
