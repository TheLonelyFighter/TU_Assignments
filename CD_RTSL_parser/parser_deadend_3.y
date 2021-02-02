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
%token<ival> INT
%token<fval> FLOAT
%token<str> TYPE STATE IDENTIFIER ERROR

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

/* You can specify the type for a production using %type.
 * For example, if "function_header" should have a "str" value, use:
 * %type<str> function_header
 */

/* Start production. */
%start translation_unit

%%

/* TODO Implement RTSL grammar here */

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

compound_statement_no_new_scope
    : '{' '}' //LEFT_BRACE RIGHT_BRACE 
    | '{' statement_list '}' // LEFT_BRACE RIGHT_BRACE
    ;

statement_list
    : statement 
    | statement_list statement 
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

declaration_statement
    : declaration 
    ;

expression_statement
    : ';' //SEMICOLON 
    | expression ; //SEMICOLON 
    ;

expression
    : assignment_expression 
    | expression ',' assignment_expression     //COMMA
    ;

assignment_expression
    : conditional_expression 
    | unary_expression assignment_operator assignment_expression 
    ;

conditional_expression
    : logical_or_expression 
    | logical_or_expression '?' expression ':' assignment_expression //QUESTION COLON
    ;

selection_statement
    : IF '(' expression ')' selection_rest_statement // LEFT_PAREN RIGHT_PAREN
    ;

selection_rest_statement
    : statement ELSE statement 
    | statement 
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

compound_statement
    : '{' '}' //LEFT_BRACE RIGHT_BRACE 
    | '{' statement_list '}' // LEFT_BRACE RIGHT_BRACE
    ;

statement_no_new_scope
    : compound_statement_no_new_scope 
    | simple_statement 
    ;

declaration
    : CLASS IDENTIFIER state_list ';' //SEMICOLON
    ;

state_list
    : RT_PRIMITIVE 
    | RT_CAMERA 
    | RT_MATERIAL 
    | RT_TEXTURE 
    | RT_LIGHT
    ;

function_prototype
    : function_declarator ')' //RIGHT_PAREN 
    ;

function_declarator
    : function_header 
    | function_header_with_parameters 
    ;

function_header
    : TYPE IDENTIFIER '(' // LEFT_PAREN 
    ;

function_header_with_parameters
    : function_header parameter_declaration 
    | function_header_with_parameters ',' parameter_declaration //COMMA
    ;

parameter_declaration
    :  type_qualifier parameter_declarator 
    |  parameter_declarator 
    |  type_qualifier parameter_type_specifier 
    |  parameter_type_specifier 
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

precision_qualifier
    : HIGHP
    | MEDIUMP
    | LOWP
    ;

interpolation_qualifier
    : SMOOTH
    | FLAT
    | NOPERSPECTIVE
    ;

invariant_qualifier
    : INVARIANT
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
