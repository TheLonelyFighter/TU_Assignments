/* Marius-Mihail Gurgu 453084, Wei-Heng Ke 454447, Tamil Selvi Pandiyan 0453060 */
%option noyywrap noinput nounput
%x IN_COMMENT

%{

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <math.h>

// Global variable for the line number
int line_number = 1;

// If we're using bison (2nd assignment), include the generated header.
// Otherwise, manually define a couple of things that bison would usually
// handle for us.
#ifdef FOR_PARSER
# include "parser.h"
#else

// Declare type for semantic value
typedef union {
    bool bval;
    int ival;
    double fval;
    char *str;
} lex_val;
lex_val yylval;


// Declare tokens
#define TOKENS \
 X(BOOL) \
 X(INT) \
 X(FLOAT) \
 X(TYPE) \
 X(STATE) \
 X(IDENTIFIER) \
 X(ERROR) \
 X(BREAK) \
 X(CONTINUE) \
 X(DO) \
 X(FOR) \
 X(WHILE) \
 X(SWITCH) \
 X(CASE) \
 X(DEFAULT) \
 X(IF) \
 X(ELSE) \
 X(RETURN) \
 X(STRUCT) \
 X(ATTRIBUTE) \
 X(CONST) \
 X(UNIFORM) \
 X(VARYING) \
 X(BUFFER) \
 X(SHARED) \
 X(COHERENT) \
 X(VOLATILE) \
 X(RESTRICT) \
 X(READONLY) \
 X(WRITEONLY) \
 X(LAYOUT) \
 X(CENTROID) \
 X(FLAT) \
 X(SMOOTH) \
 X(NOPERSPECTIVE) \
 X(PATCH) \
 X(SAMPLE) \
 X(SUBROUTINE) \
 X(IN) \
 X(OUT) \
 X(INOUT) \
 X(INVARIANT) \
 X(PRECISE) \
 X(DISCARD) \
 X(LOWP) \
 X(MEDIUMP) \
 X(HIGHP) \
 X(PRECISION) \
 X(CLASS) \
 X(ILLUMINANCE) \
 X(AMBIENT) \
 X(PUBLIC) \
 X(PRIVATE) \
 X(SCRATCH) \
 X(RT_PRIMITIVE) \
 X(RT_CAMERA) \
 X(RT_MATERIAL) \
 X(RT_TEXTURE) \
 X(RT_LIGHT) \
 X(LEFT_OP) \
 X(RIGHT_OP) \
 X(INC_OP) \
 X(DEC_OP) \
 X(LE_OP) \
 X(GE_OP) \
 X(EQ_OP) \
 X(NE_OP) \
 X(AND_OP) \
 X(OR_OP) \
 X(XOR_OP) \
 X(MUL_ASSIGN) \
 X(DIV_ASSIGN) \
 X(ADD_ASSIGN) \
 X(MOD_ASSIGN) \
 X(LEFT_ASSIGN) \
 X(RIGHT_ASSIGN) \
 X(AND_ASSIGN) \
 X(XOR_ASSIGN) \
 X(OR_ASSIGN) \
 X(SUB_ASSIGN)

enum {
    _MAXCHAR = 255,
#define X(token) token,
    TOKENS
#undef X
} token;

#endif /* FOR_PARSER */

%}

 /* TODO Helper definitions here  */
 
 /* Regular Expressions Definitions */

delim	[ \t]
ws 	{delim}+
digit	[0-9]
IDENT	[a-zA-Z][a-zA-Z0-9_]*
newline \n
special [;:()\[\].,\+\-~!\*\/%<>&\^\|\?=\{\}]
comment [\/\/]{2}[^\n]*\n  
state   rt_[a-zA-Z0-9_]*
type 	(void)|(bool)|(color)|(int)|(uint)|(float)|(double)|((d|b|i)?vec[2-4])|(d?mat[2-4](x[2-4])?)
bool	(true)|(false)

 /*The following regex were imported from the flex manual, see https://westes.github.io/flex/manual/Numbers.html#Numbers */
int	([[:digit:]]{-}[0])[[:digit:]]*(u|U)?
hexa_int 0[xX][[:xdigit:]]+(u|U)?
octal_int 0[01234567]*(u|U)?

dseq      ([[:digit:]]+)
dseq_opt  ([[:digit:]]*)
frac    (({dseq_opt}"."{dseq})|{dseq}".")
exp      ([eE][+-]?{dseq})
exp_opt   ({exp}?)
fsuff    ([flFL]|(lf)|(LF))
fsuff_opt ({fsuff}?)
hpref     (0[xX])
hdseq     ([[:xdigit:]]+)
hdseq_opt ([[:xdigit:]]*)
hfrac     (({hdseq_opt}"."{hdseq})|({hdseq}"."))
bexp      ([pP][+-]?{dseq})
dfc      (({frac}{exp_opt}{fsuff_opt})|({dseq}{exp}{fsuff_opt}))
hfc      (({hpref}{hfrac}{bexp}{fsuff_opt})|({hpref}{hdseq}{bexp}{fsuff_opt}))

c99_floating_point_constant  ({dfc}|{hfc})

%%

 /* TODO Implement the rest... */

{newline}	{line_number++;}
{ws} 		{/* do nothing bby */}

{comment}	{line_number++;} //single line comment 

 /* Operators */
 
(<<)		return LEFT_OP;
(>>)		return RIGHT_OP;
(\+\+)		return INC_OP;
(\-\-)		return DEC_OP;
(<=)		return LE_OP;
(>=)		return GE_OP;
(==)		return EQ_OP;
(!=)		return NE_OP;
(&&)		return AND_OP;
(\|\|)		return OR_OP;
(\^\^)		return XOR_OP;
(\*=)		return MUL_ASSIGN;
(\/=)		return DIV_ASSIGN;
(\+=)		return ADD_ASSIGN;
(%=) 		return MOD_ASSIGN;
(<<=)		return LEFT_ASSIGN;
(>>=)		return RIGHT_ASSIGN;
(&=)		return AND_ASSIGN;
(\^=)		return XOR_ASSIGN;
(\|=)		return OR_ASSIGN;
(-=)		return SUB_ASSIGN;

 /* C Keywords */
if 		return IF;
else		return ELSE;
break		return BREAK;
continue	return CONTINUE;
do		return DO;
while		return WHILE;
for		return FOR;
switch		return SWITCH;
case		return CASE;
default	return DEFAULT;
return		return RETURN;
struct		return STRUCT;

 /* GLSL keywords */
attribute	return ATTRIBUTE;
const		return CONST;
uniform	return UNIFORM;
buffer		return BUFFER;
shared		return SHARED;
coherent	return COHERENT;
volatile	return VOLATILE;
restrict	return RESTRICT;
readonly	return READONLY;
writeonly	return WRITEONLY;
layout		return LAYOUT;
centroid	return CENTROID;
flat		return FLAT;
smooth		return SMOOTH;
noperspective	return NOPERSPECTIVE;
patch		return PATCH;
sample		return SAMPLE;
subroutine	return SUBROUTINE;
in		return IN;
out		return OUT;
inout 		return INOUT;
invariant	return INVARIANT;
precise	return PRECISE;
discard	return DISCARD;
lowp		return LOWP;
mediump	return MEDIUMP;
highp		return HIGHP;
precision	return PRECISION;

 /* RTSL keywords */
 
class		return CLASS;
illuminance	return ILLUMINANCE;
ambient	return AMBIENT;
public		return PUBLIC;
private	return PRIVATE;
scratch	return SCRATCH;

 /* RTSL interface types */
 
rt_Primitive	return RT_PRIMITIVE;
rt_Camera	return RT_CAMERA;
rt_Material	return RT_MATERIAL;
rt_Texture	return RT_TEXTURE;
rt_Light	return RT_LIGHT;

{state} { yylval.str = strdup(yytext); return STATE; }
{type}  { yylval.str = strdup(yytext); return TYPE; } 
{bool}  {
	  char *string = strdup(yytext); 
	  if (strcmp(string, "true") == 0) yylval.bval = 1;
	  else if (strcmp(string, "false") == 0) yylval.bval = 0;
	  return BOOL; 
	} 
{int} 	{ yylval.ival = atoi(yytext); return INT; }	
{hexa_int} { yylval.ival = (int)strtol(yytext, NULL, 0); return INT; }
{octal_int} { yylval.ival = (int)strtol(yytext, NULL, 0); return INT; }
{c99_floating_point_constant} { yylval.fval = atof(yytext); return FLOAT; } 
{IDENT} 	{ yylval.str = strdup(yytext); return IDENTIFIER; }
{special}	{yylval.str = strdup(yytext); return (int) yylval.str[0]; } //you have to put this after IDENTIFIER, dunno why yet;otherwise single-letter identifier will be seen as unary operators, long live empiricism aka 'if it works, it works'
									    

 /* Takes care of multiline comments, see 'How can I match C-style comments?' in flex manual aka RTFM, see https://westes.github.io/flex/manual/How-can-I-match-C_002dstyle-comments_003f.html#How-can-I-match-C_002dstyle-comments_003f */
 
<INITIAL>{
"/*"              BEGIN(IN_COMMENT);
}
<IN_COMMENT>{
"*/"      BEGIN(INITIAL);
[^*\n]+   // eat comment in chunks
"*"       // eat the lone star
\n        line_number++;
}



 /* error situation */
.                       { yylval.str = strdup(yytext); return ERROR; }

%%

// Generate main code only for standalone compilation,
// but not if we're using bison (2nd assignment)
#ifndef FOR_PARSER
static const char *token_name(int token) {
    switch (token) {
#define X(token) \
        case token: \
            return #token;
TOKENS
#undef X
    }
    return NULL;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
		if (!yyin) {
			printf("File %s not found.\n", argv[1]);
			return 1;
		}
    } else {
        yyin = stdin;
    }

    int token;
    while ((token = yylex())) {
		printf("Line%3d:    ", line_number);
        if (token < 256) {
            printf("\"%c\"\n", token);
        } else {
            const char *name = token_name(token);
            if (!name) {
                printf("???\n");
            } else {
                switch (token) {
                    default:
                        printf("%s\n", name);
                        break;
                    case BOOL:
                        printf("%s [%s]\n", name, yylval.bval ? "true" : "false");
                        break;
                    case INT:
                        printf("%s [%d]\n", name, yylval.ival);
                        break;
                    case FLOAT:
                        printf("%s [%f]\n", name, yylval.fval);
                        break;
                    case TYPE:
                    case STATE:
                    case IDENTIFIER:
                    case ERROR:
                        printf("%s [%s]\n", name, yylval.str);
                        free(yylval.str);
                        break;
                }
            }
        }
    }

    return 0;
}
#endif /* FOR_PARSER */
