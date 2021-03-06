/* Types that are used in %union should be defined in this code block. */
%code requires {
#include <stdbool.h>
}

/* Everything else can go in this code block. */
%code {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int line_number;
extern FILE *yyin;
extern int yylex();
static void yyerror(const char *s);
}

/* Enable verbose error messages. */
%define parse.error verbose

/* Declare type for semantic value. You may need to extend this. */
%union {
    bool bval;
    int ival;
    double fval;
    char *str;
};

/* Declare tokens with semantic values */
%token<bval> BOOL
%token<ival> INT UINT

%token<fval> FLOAT
%token<fval> DOUBLE
%token<str> TYPE STATE IDENTIFIER ERROR COLOR

/* Declare tokens without semantic values */
%token BREAK CONTINUE DO FOR WHILE SWITCH CASE DEFAULT IF ELSE RETURN STRUCT
%token ATTRIBUTE CONST UNIFORM VARYING BUFFER SHARED COHERENT VOLATILE RESTRICT
%token READONLY WRITEONLY LAYOUT CENTROID FLAT SMOOTH NOPERSPECTIVE PATCH SAMPLE
%token SUBROUTINE IN OUT INOUT INVARIANT PRECISE DISCARD LOWP MEDIUMP HIGHP PRECISION

%token CLASS ILLUMINANCE AMBIENT PUBLIC PRIVATE SCRATCH
%token RT_PRIMITIVE RT_CAMERA RT_MATERIAL RT_TEXTURE RT_LIGHT

%token LEFT_OP RIGHT_OP INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP AND_OP OR_OP XOR_OP

%token MUL_ASSIGN DIV_ASSIGN ADD_ASSIGN MOD_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN
%token AND_ASSIGN XOR_ASSIGN OR_ASSIGN SUB_ASSIGN

// Tokens declared by me

%token VOID

// %token VEC2 VEC3 VEC4 DVEC2 DVEC3  DVEC4 BVEC2 BVEC3 BVEC4 IVEC2 IVEC3 IVEC4 
// %token MAT2 MAT3 MAT4 MAT2X2 MAT2X3 MAT2X4 MAT3X2 MAT3X3 MAT3X4 MAT4X2 MAT4X3 MAT4X4
// %token DMAT2 DMAT3 DMAT4 DMAT2X2 DMAT2X3 DMAT2X4 DMAT3X2 DMAT3X3 DMAT3X4 DMAT4X2 DMAT4X3 DMAT4X4



/* You can specify the type for a production using %type.
 * For example, if "function_header" should have a "str" value, use:
 * %type<str> function_header
 */

/* Start production. */
%start translation_unit

%%

/* TODO Implement RTSL grammar here */

/* This is a GLSL grammar extracted from section 9 of the GLSL 4.40 specification
 * and adjusted to use Bison-compatible syntax.
 *
 * This grammar is *NOT* directly usable with your lexer, because token names are
 * different. If you want to use this grammar, you need to:
 *  * Adjust token names to the ones you use (e.g. INT instead of INTCONSTANT). Some places
 *    may require larger adjustments, for example we use a single TYPE token, while the GLSL
 *    grammar specifies each type separately.
 *  * Replace some token names with single-char tokens (e.g. '[' instead of LEFT_BRACKET)
 *  * Drop cases that use TYPE_NAME, because these are too complicated to handle.
 *    (Can you explain why replacing TYPE_NAME with IDENTIFIER doesn't work, and why GLSL
 *    uses a separate TYPE_NAME token in the first place?)
 *
 * Once you have a working GLSL grammar, there are only few changes necessary to convert it
 * into an RTSL grammar. After that, you still need to implement the necessary output code
 * and the necessary semantic checks.
 */

variable_identifier
    : IDENTIFIER 
    ;

primary_expression
    : variable_identifier 
    | INT
    | UINT
    | FLOAT
    | DOUBLE
    | BOOL 
    | CLASS
    | '(' expression ')' 
    ;

postfix_expression
    : primary_expression 
    | postfix_expression '[' integer_expression ']'
    | function_call 
    /*| postfix_expression DOT FIELD_SELECTION */
    | postfix_expression INC_OP 
    | postfix_expression DEC_OP 
    ;

integer_expression
    : expression 
    ;

function_call
    : function_call_or_method
    ;

function_call_or_method
    : function_call_generic 
    ;

function_call_generic
    : function_call_header_with_parameters ')'
    | function_call_header_no_parameters ')'
    ;

function_call_header_no_parameters
    : function_call_header VOID 
    | function_call_header 
    ;

function_call_header_with_parameters
    : function_call_header assignment_expression 
    | function_call_header_with_parameters ',' assignment_expression 
    ;

function_call_header
    : function_identifier '(' 
    ;

function_identifier
    : type_specifier
    | postfix_expression
    ;

unary_expression
    : postfix_expression 
    | INC_OP unary_expression 
    | DEC_OP unary_expression 
    | unary_operator unary_expression 
    ;

unary_operator
    : '+' //PLUS
    | '-' //DASH
    | '!' //BANG 
    | '~' //TILDE
    ;

multiplicative_expression
    : unary_expression 
    | multiplicative_expression '*' unary_expression  //STAR
    | multiplicative_expression '/' unary_expression   //SLASH
    | multiplicative_expression '%' unary_expression    //PERCENT
    ;

additive_expression
    : multiplicative_expression 
    | additive_expression '+' multiplicative_expression //PLUS
    | additive_expression '-' multiplicative_expression //DASH
    ;

shift_expression
    : additive_expression 
    | shift_expression LEFT_OP additive_expression
    | shift_expression RIGHT_OP additive_expression
    ;

relational_expression
    : shift_expression 
    | relational_expression '<' shift_expression   //LEFT_ANGLE
    | relational_expression '>' shift_expression   //RIGHT_ANGLE
    | relational_expression LE_OP shift_expression 
    | relational_expression GE_OP shift_expression 
    ;

equality_expression
    : relational_expression 
    | equality_expression EQ_OP relational_expression 
    | equality_expression NE_OP relational_expression 
    ;

and_expression
    : equality_expression 
    | and_expression '&' equality_expression   //AMPERSAND
    ;

exclusive_or_expression
    : and_expression 
    | exclusive_or_expression '^' and_expression   //CARET
    ;

inclusive_or_expression
    : exclusive_or_expression 
    | inclusive_or_expression '|' exclusive_or_expression  //VERTICAL_BAR
    ;

logical_and_expression
    : inclusive_or_expression 
    | logical_and_expression AND_OP inclusive_or_expression 
    ;

logical_xor_expression
    : logical_and_expression 
    | logical_xor_expression XOR_OP logical_and_expression 
    ;

logical_or_expression
    : logical_xor_expression 
    | logical_or_expression OR_OP logical_xor_expression 
    ;

conditional_expression
    : logical_or_expression 
    | logical_or_expression '?' expression : assignment_expression //QUESTION COLON
    ;

assignment_expression
    : conditional_expression 
    | unary_expression assignment_operator assignment_expression 
    ;

assignment_operator
    : '=' // EQUAL
    | MUL_ASSIGN
    | DIV_ASSIGN
    | MOD_ASSIGN
    | ADD_ASSIGN 
    | SUB_ASSIGN 
    | LEFT_ASSIGN
    | RIGHT_ASSIGN
    | AND_ASSIGN
    | XOR_ASSIGN
    | OR_ASSIGN
    ;

// expression
//     : assignment_expression 
//     | expression ',' assignment_expression     //COMMA
//     ;

constant_expression
    : conditional_expression 
    ;

declaration 
    : function_prototype ';' // SEMICOLON 
    | init_declarator_list ';' // SEMICOLON 
    | PRECISION precision_qualifier type_specifier //SEMICOLON 
    | type_qualifier IDENTIFIER '{' struct_declaration_list '}' ';' //LEFT_BRACE RIGHT_BRACE SEMICOLON
    | type_qualifier IDENTIFIER '{' struct_declaration_list '}' IDENTIFIER ';' //LEFT_BRACE RIGHT_BRACE SEMICOLON
    | type_qualifier IDENTIFIER '{' struct_declaration_list '}' IDENTIFIER array_specifier ';' // LEFT_BRACE RIGHT_BRACE SEMICOLON
    | type_qualifier ';' //SEMICOLON
    | type_qualifier IDENTIFIER ';'  //SEMICOLON
    | type_qualifier IDENTIFIER identifier_list ';' //SEMICOLON
    ;

identifier_list
    : ',' IDENTIFIER // COMMA
    | identifier_list ',' IDENTIFIER // COMMA
    ;

function_prototype
    : function_declarator ')' //RIGHT_PAREN 
    ;

function_declarator
    : function_header 
    | function_header_with_parameters 
    ;

function_header_with_parameters
    : function_header parameter_declaration 
    | function_header_with_parameters ',' parameter_declaration //COMMA
    ;

function_header
    : fully_specified_type IDENTIFIER '(' // LEFT_PAREN 
    ;

parameter_declarator
    : type_specifier IDENTIFIER 
    | type_specifier IDENTIFIER array_specifier
    ;

parameter_declaration
    :  type_qualifier parameter_declarator 
    |  parameter_declarator 
    |  type_qualifier parameter_type_specifier 
    |  parameter_type_specifier 
    ;

parameter_type_specifier
    : type_specifier 
    ;

init_declarator_list
    : single_declaration 
    | init_declarator_list ',' IDENTIFIER // COMMA
    | init_declarator_list ',' IDENTIFIER array_specifier //COMMA
    | init_declarator_list ',' IDENTIFIER array_specifier '=' initializer //COMMA EQUAL
    | init_declarator_list ',' IDENTIFIER '=' initializer //COMMA EQUAL
    ;

single_declaration
    : fully_specified_type 
    | fully_specified_type IDENTIFIER 
    | fully_specified_type IDENTIFIER array_specifier
    | fully_specified_type IDENTIFIER array_specifier '=' initializer //EQUAL
    | fully_specified_type IDENTIFIER '=' initializer //EQUAL
    ;

fully_specified_type
    : type_specifier 
    | type_qualifier type_specifier 
    ;

invariant_qualifier
    : INVARIANT
    ;

interpolation_qualifier
    : SMOOTH
    | FLAT
    | NOPERSPECTIVE
    ;

layout_qualifier
    : LAYOUT '(' layout_qualifier_id_list ')' //LEFT_PAREN RIGHT_PAREN
    ;

layout_qualifier_id_list
    : layout_qualifier_id
    | layout_qualifier_id_list ',' layout_qualifier_id //COMMA
    ;

layout_qualifier_id
    : IDENTIFIER
IDENTIFIER '=' constant_expression // EQUAL
    | SHARED
    ;

precise_qualifier
    : PRECISE
    ;

type_qualifier
    : single_type_qualifier
    | type_qualifier single_type_qualifier
    ;

single_type_qualifier
    : storage_qualifier
    | layout_qualifier
    | precision_qualifier
    | interpolation_qualifier
    | invariant_qualifier
    | precise_qualifier
    ;

storage_qualifier
    : CONST 
    | INOUT
    | IN
    | OUT
    | CENTROID
    | PATCH
    | SAMPLE
    | UNIFORM 
    | BUFFER
    | SHARED
    | COHERENT
    | VOLATILE
    | RESTRICT
    | READONLY
    | WRITEONLY
    | SUBROUTINE 
    | ATTRIBUTE
    | VARYING
    /* | SUBROUTINE '(' type_name_list ')' // LEFT_PAREN RIGHT_PAREN */
    ;

// this commenting could be a problem

/* type_name_list // drop cases that use type_name
    : TYPE_NAME 
    | type_name_list COMMA TYPE_NAME
    ; */

type_specifier
    : type_specifier_nonarray 
    | type_specifier_nonarray array_specifier
    ;

array_specifier
    : '(' ')' //LEFT_BRACKET RIGHT_BRACKET 
    | '(' constant_expression ')' // LEFT_BRACKET RIGHT_BRACKET
    | array_specifier '(' ')' //LEFT_BRACKET RIGHT_BRACKET
    | array_specifier '(' constant_expression ')' //LEFT_BRACKET RIGHT_BRACKET
    ;

type_specifier_nonarray
    : VOID 
    | FLOAT 
    | DOUBLE
    | INT
    | UINT
    | BOOL 
    | COLOR
    | CLASS
    // | VEC2 
    // | VEC3 
    // | VEC4 
    // | DVEC2 
    // | DVEC3 
    // | DVEC4 
    // | BVEC2 
    // | BVEC3 
    // | BVEC4 
    // | IVEC2 
    // | IVEC3 
    // | IVEC4 
    // | MAT2
    // | MAT3
    // | MAT4
    // | MAT2X2 
    // | MAT2X3 
    // | MAT2X4
    // | MAT3X2 
    // | MAT3X3 
    // | MAT3X4
    // | MAT4X2 
    // | MAT4X3 
    // | MAT4X4
    // | DMAT2
    // | DMAT3
    // | DMAT4
    // | DMAT2X2 
    // | DMAT2X3 
    // | DMAT2X4
    // | DMAT3X2 
    // | DMAT3X3 
    // | DMAT3X4
    // | DMAT4X2 
    // | DMAT4X3 
    // | DMAT4X4
    ;

precision_qualifier
    : HIGHP
    | MEDIUMP
    | LOWP
    ;

struct_specifier
    : STRUCT IDENTIFIER '{' struct_declaration_list '}' //LEFT_BRACE RIGHT_BRACE
    | STRUCT '{' struct_declaration_list '}' //LEFT_BRACE RIGHT_BRACE
    ;

struct_declaration_list
    : struct_declaration 
    | struct_declaration_list struct_declaration 
    ;

struct_declaration
    : type_specifier struct_declarator_list ';' //SEMICOLON 
    | type_qualifier type_specifier struct_declarator_list ';' //SEMICOLON
    ;

struct_declarator_list
    : struct_declarator 
    | struct_declarator_list ',' struct_declarator // COMMA
    ;

struct_declarator
    : IDENTIFIER 
    | IDENTIFIER array_specifier
    ;

initializer
    : assignment_expression 
    | '{' initializer_list '}' // LEFT_BRACE LEFT_BRACE
    | '{' initializer_list ',' '}' //LEFT_BRACE COMMA RIGHT_BRACE
    ;

initializer_list
    : initializer
    | initializer_list ',' initializer // COMMA
    ;

declaration_statement
    : declaration 
    ;

statement
    : compound_statement 
    | simple_statement 
    ;

simple_statement
    : declaration_statement 
    | expression_statement 
    | selection_statement
    | switch_statement 
    | case_label
    | iteration_statement 
    | jump_statement 
    ;

compound_statement
    : '{' '}' //LEFT_BRACE RIGHT_BRACE 
    | '{' statement_list '}' // LEFT_BRACE RIGHT_BRACE
    ;

statement_no_new_scope
    : compound_statement_no_new_scope 
    | simple_statement 
    ;

compound_statement_no_new_scope
    : '{' '}' //LEFT_BRACE RIGHT_BRACE 
    | '{' statement_list '}' // LEFT_BRACE RIGHT_BRACE
    ;

statement_list
    : statement 
    | statement_list statement 
    ;

expression_statement
    : ';' //SEMICOLON 
    | expression ; //SEMICOLON 
    ;

selection_statement
    : IF '(' expression ')' selection_rest_statement // LEFT_PAREN RIGHT_PAREN
    ;

selection_rest_statement
    : statement ELSE statement 
    | statement 
    ;

condition
    : expression 
    | fully_specified_type IDENTIFIER '=' initializer //EQUAL
    ;

switch_statement
    : SWITCH '(' expression ')' '{' switch_statement_list '}' // LEFT_PAREN RIGHT_PAREN LEFT_BRACE RIGHT_BRACE
    ;

switch_statement_list
    : /* nothing */
    | statement_list
    ;

case_label
    : CASE expression ':' //COLON
    | DEFAULT ':' //COLON
    ;

iteration_statement
    : WHILE '(' condition ')' statement_no_new_scope // LEFT_PAREN RIGHT_PAREN
    | DO statement WHILE '(' expression ')' ';' // LEFT_PAREN RIGHT_PAREN SEMICOLON
    | FOR '(' for_init_statement for_rest_statement ')' statement_no_new_scope // LEFT_PAREN RIGHT_PAREN
    ;

for_init_statement
    : expression_statement 
    | declaration_statement 
    ;

conditionopt
    : condition 
    | /* empty */
    ;

for_rest_statement
    : conditionopt ';' //SEMICOLON 
    | conditionopt ';' expression //SEMICOLON 
    ;

jump_statement
    : CONTINUE ';' //SEMICOLON 
    | BREAK ';' //SEMICOLON 
    | RETURN ';' //SEMICOLON 
    | RETURN expression ';' //SEMICOLON 
    | DISCARD ';' //SEMICOLON   // Fragment shader only.
    ;

translation_unit
    : external_declaration 
    | translation_unit external_declaration 
    ;

external_declaration
    : function_definition 
    | declaration 
    ;

function_definition
    : function_prototype compound_statement_no_new_scope 
    ;

%%
 
/* Data tables for interface methods and states, so you don't have to extract them yourself.
 * Note: The paper contains a number of errors regarding the allowed state variables. These
 * errors are already corrected here and marked with a comment. */

static const char *camera_methods[] = {
    "constructor",
    "generateRay",
    NULL
};

static const char *primitive_methods[] = {
    "constructor",
    "intersect",
    "computeBounds",
    "computeNormal",
    "computeTextureCoordinates",
    "computeDerivatives",
    "generateSample",
    "samplePDF",
    NULL
};

static const char *texture_methods[] = {
    "constructor",
    "lookup",
    NULL
};

static const char *material_methods[] = {
    "constructor",
    "shade",
    "BSDF",
    "sampleBSDF",
    "evaluatePDF",
    "emission",
    NULL
};

static const char *light_methods[] = {
    "constructor",
    "illumination",
    NULL
};

static const char **interface_methods[] = {
    primitive_methods, camera_methods, material_methods, texture_methods, light_methods, NULL
};

static const char *camera_states[] = {
    "RayOrigin",
    "RayDirection",
    "InverseRayDirection",
    "Epsilon",
    "HitDistance",
    "ScreenCoord",
    "LensCoord",
    "du",
    "dv",
    "TimeSeed",
    NULL
};

static const char *primitive_states[] = {
    "RayOrigin",
    "RayDirection",
    "InverseRayDirection",
    "Epsilon",
    "HitDistance",
    "BoundMin",
    "BoundMax",
    "GeometricNormal",
    "dPdu",
    "dPdv",
    "ShadingNormal",
    "TextureUV",
    "TextureUVW",
    "dsdu",
    "dsdv",
    "PDF",
    "TimeSeed",
    "HitPoint", // missing in paper
    NULL
};

static const char *texture_states[] = {
    "TextureUV",
    "TextureUVW",
    "TextureColor",
    "FloatTextureValue",
    "du",
    "dv",
    "dsdu",
    "dtdu",
    "dsdv",
    "dtdv",
    "dPdu",
    "dPdv",
    "TimeSeed",
    NULL
};

static const char *material_states[] = {
    "RayOrigin",
    "RayDirection",
    "InverseRayDirection",
    "HitPoint",
    "dPdu",
    "dPdv",
    "LightDirection",
    "LightDistance",
    "LightColor",
    "EmissionColor",
    "BSDFSeed",
    "TimeSeed",
    "PDF",
    "SampleColor",
    "BSDFValue",
    "du",
    "dv",
    "ShadingNormal", // missing in paper
    "HitDistance", // missing in paper
    NULL
};

static const char *light_states[] = {
    "HitPoint",
    "GeometricNormal",
    "ShadingNormal",
    "LightDirection",
    "TimeSeed",
    NULL
};

static const char **interface_states[] = {
    primitive_states, camera_states, material_states, texture_states, light_states
};

/* TODO You'll probably want to add some additional functions to implement the
 * semantic checks here. */
 
static void yyerror(const char *s) {
    fprintf(stderr, "%s on line %d\n", s, line_number);
    exit(-1);
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
    
    do {
        yyparse();
    } while (!feof(yyin));
    return 1;
}
