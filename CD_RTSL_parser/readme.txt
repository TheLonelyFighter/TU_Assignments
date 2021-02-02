Using bison and a previously implemented lexer, I have coded a parser for RTSL. The grammar for the parser was based on a GLSL grammar that had to be modified (see glsl_grammar_converted.txt ). Apart from making sure the syntax of the code is correct, the parser also implements some basic semantic checks (see tests 6, 7, 8).
The grammar has only one shift/reduce conflict (if else).
