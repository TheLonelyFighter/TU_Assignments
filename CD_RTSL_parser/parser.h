/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_PARSER_H_INCLUDED
# define YY_YY_PARSER_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 2 "parser.y"

#include <stdbool.h>

#line 52 "parser.h"

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    BOOL = 258,
    INT = 259,
    UINT = 260,
    FLOAT = 261,
    DOUBLE = 262,
    TYPE = 263,
    STATE = 264,
    IDENTIFIER = 265,
    ERROR = 266,
    BREAK = 267,
    CONTINUE = 268,
    DO = 269,
    FOR = 270,
    WHILE = 271,
    SWITCH = 272,
    CASE = 273,
    DEFAULT = 274,
    IF = 275,
    ELSE = 276,
    RETURN = 277,
    STRUCT = 278,
    ATTRIBUTE = 279,
    CONST = 280,
    UNIFORM = 281,
    VARYING = 282,
    BUFFER = 283,
    SHARED = 284,
    COHERENT = 285,
    VOLATILE = 286,
    RESTRICT = 287,
    READONLY = 288,
    WRITEONLY = 289,
    LAYOUT = 290,
    CENTROID = 291,
    FLAT = 292,
    SMOOTH = 293,
    NOPERSPECTIVE = 294,
    PATCH = 295,
    SAMPLE = 296,
    SUBROUTINE = 297,
    IN = 298,
    OUT = 299,
    INOUT = 300,
    INVARIANT = 301,
    PRECISE = 302,
    DISCARD = 303,
    LOWP = 304,
    MEDIUMP = 305,
    HIGHP = 306,
    PRECISION = 307,
    CLASS = 308,
    ILLUMINANCE = 309,
    AMBIENT = 310,
    PUBLIC = 311,
    PRIVATE = 312,
    SCRATCH = 313,
    RT_PRIMITIVE = 314,
    RT_CAMERA = 315,
    RT_MATERIAL = 316,
    RT_TEXTURE = 317,
    RT_LIGHT = 318,
    LEFT_OP = 319,
    RIGHT_OP = 320,
    INC_OP = 321,
    DEC_OP = 322,
    LE_OP = 323,
    GE_OP = 324,
    EQ_OP = 325,
    NE_OP = 326,
    AND_OP = 327,
    OR_OP = 328,
    XOR_OP = 329,
    MUL_ASSIGN = 330,
    DIV_ASSIGN = 331,
    ADD_ASSIGN = 332,
    MOD_ASSIGN = 333,
    LEFT_ASSIGN = 334,
    RIGHT_ASSIGN = 335,
    AND_ASSIGN = 336,
    XOR_ASSIGN = 337,
    OR_ASSIGN = 338,
    SUB_ASSIGN = 339,
    VOID = 340
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 29 "parser.y"

    bool bval;
    int ival;
    double fval;
    char *str;

#line 156 "parser.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_PARSER_H_INCLUDED  */
