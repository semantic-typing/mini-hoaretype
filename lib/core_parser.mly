%{
open Core_lang
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT

(* Keywords *)
%token LET IN IF THEN ELSE WHILE DO FOR FUNC FUNCTION FUN RETURN
%token MATCH WITH DATA IMPORT FROM

(* Type names *)
%token TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL TYPE_UNIT

(* Boolean literals *)
%token TRUE FALSE NULL

(* Operators *)
%token PLUS MINUS TIMES DIV MOD POW EQ NEQ LT LE GT GE AND OR NOT PIPE ARROW COLON ASSIGN

(* Punctuation *)
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE
%token COMMA SEMICOLON DOT

(* End of file *)
%token EOF

%start program
%type <Core_lang.program> program

%start expr
%type <Core_lang.expr> expr

%%

program:
  | stmt_list { $1 }
  ;

stmt_list:
  | stmt { [$1] }
  | stmt SEMICOLON stmt_list { $1 :: $3 }
  ;

stmt:
  | expr { Expr $1 }
  | let_stmt { $1 }
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }
  | func_def { $1 }
  | data_def { $1 }
  | import_stmt { $1 }
  ;

expr:
  | let_expr { $1 }
  | if_expr { $1 }
  | lambda_expr { $1 }
  | app_expr { $1 }
  | bin_expr { $1 }
  | unary_expr { $1 }
  | primary_expr { $1 }
  ;

let_expr:
  | LET IDENT ASSIGN expr IN expr { Let ($2, $4, $6) }
  | LET IDENT COLON type_expr ASSIGN expr IN expr { Let ($2, $6, $8) }
  ;

if_expr:
  | IF expr THEN expr ELSE expr { BinOp (Eq, $2, Constructor ("true", [])) }
  ;

lambda_expr:
  | FUN param_list ARROW expr { Lambda ($2, $4) }
  | FUN IDENT COLON type_expr ARROW expr { Lambda ([$2], $6) }
  ;

param_list:
  | IDENT { [$1] }
  | IDENT param_list { $1 :: $2 }
  ;

app_expr:
  | primary_expr LPAREN expr_list RPAREN { App ($1, $3) }
  | primary_expr primary_expr { App ($1, [$2]) }
  ;

expr_list:
  | { [] }
  | expr { [$1] }
  | expr COMMA expr_list { $1 :: $3 }
  ;

bin_expr:
  | bin_expr PLUS bin_expr { BinOp (Plus, $1, $3) }
  | bin_expr MINUS bin_expr { BinOp (Minus, $1, $3) }
  | bin_expr TIMES bin_expr { BinOp (Times, $1, $3) }
  | bin_expr DIV bin_expr { BinOp (Div, $1, $3) }
  | bin_expr MOD bin_expr { BinOp (Mod, $1, $3) }
  | bin_expr POW bin_expr { BinOp (Pow, $1, $3) }
  | bin_expr EQ bin_expr { BinOp (Eq, $1, $3) }
  | bin_expr NEQ bin_expr { BinOp (Neq, $1, $3) }
  | bin_expr LT bin_expr { BinOp (Lt, $1, $3) }
  | bin_expr LE bin_expr { BinOp (Le, $1, $3) }
  | bin_expr GT bin_expr { BinOp (Gt, $1, $3) }
  | bin_expr GE bin_expr { BinOp (Ge, $1, $3) }
  | bin_expr AND bin_expr { BinOp (And, $1, $3) }
  | bin_expr OR bin_expr { BinOp (Or, $1, $3) }
  | unary_expr { $1 }
  ;

unary_expr:
  | MINUS unary_expr { UnaryOp (Neg, $2) }
  | NOT unary_expr { UnaryOp (Not, $2) }
  | primary_expr { $1 }
  ;

primary_expr:
  | literal { $1 }
  | IDENT { Var $1 }
  | LPAREN expr RPAREN { $2 }
  | tuple_expr { $1 }
  | match_expr { $1 }
  | field_access { $1 }
  | index_access { $1 }
  ;

literal:
  | INT { Int $1 }
  | FLOAT { Float $1 }
  | STRING { String $1 }
  | TRUE { Constructor ("true", []) }
  | FALSE { Constructor ("false", []) }
  | NULL { Constructor ("null", []) }
  ;

tuple_expr:
  | LPAREN expr COMMA expr_list RPAREN { Tuple ($2 :: $4) }
  ;

match_expr:
  | MATCH expr WITH match_branches { Match ($2, $4) }
  ;

match_branches:
  | match_branch { [$1] }
  | match_branch match_branches { $1 :: $2 }
  ;

match_branch:
  | PIPE pattern ARROW expr { ($2, $4) }
  ;

pattern:
  | IDENT { PVar $1 }
  | constructor_pattern { $1 }
  ;

constructor_pattern:
  | IDENT LPAREN pattern_list RPAREN { PConstructor ($1, $3) }
  | IDENT { PConstructor ($1, []) }
  ;

pattern_list:
  | { [] }
  | pattern { [$1] }
  | pattern COMMA pattern_list { $1 :: $3 }
  ;

field_access:
  | primary_expr DOT IDENT { FieldAccess ($1, $3) }
  ;

index_access:
  | primary_expr LBRACKET expr RBRACKET { Index ($1, $3) }
  ;

type_expr:
  | basic_type { $1 }
  | function_type { $1 }
  | tuple_type { $1 }
  | constructor_type { $1 }
  | union_type { $1 }
  | intersection_type { $1 }
  | negation_type { $1 }
  | type_var { $1 }
  | LPAREN type_expr RPAREN { $2 }
  ;

basic_type:
  | TYPE_INT { TInt }
  | TYPE_FLOAT { TFloat }
  | TYPE_STRING { TString }
  | TYPE_BOOL { TBool }
  | TYPE_UNIT { TUnit }
  ;

function_type:
  | type_expr ARROW type_expr { TArrow ($1, $3) }
  ;

tuple_type:
  | LPAREN type_expr TIMES type_list RPAREN { TTuple ($2 :: $4) }
  ;

type_list:
  | { [] }
  | type_expr { [$1] }
  | type_expr TIMES type_list { $1 :: $3 }
  ;

constructor_type:
  | IDENT LPAREN type_list RPAREN { TConstructor ($1, $3) }
  | IDENT { TConstructor ($1, []) }
  ;

union_type:
  | type_expr PIPE type_expr { TUnion ($1, $3) }
  ;

intersection_type:
  | type_expr AND type_expr { TIntersection ($1, $3) }
  ;

negation_type:
  | NOT type_expr { TNegation $2 }
  ;

type_var:
  | IDENT { TVar $1 }
  ;

let_stmt:
  | LET IDENT ASSIGN expr IN stmt { Let ($2, $4, $6) }
  ;

if_stmt:
  | IF expr THEN stmt_list ELSE stmt_list { If ($2, $4, $6) }
  ;

while_stmt:
  | WHILE expr DO stmt_list { While ($2, $4) }
  ;

for_stmt:
  | FOR IDENT IN expr DO stmt_list { For ($2, $4, $6) }
  ;

func_def:
  | FUNC IDENT LPAREN param_def_list RPAREN COLON type_expr ASSIGN stmt_list { FunDef ($2, $4, $9) }
  | FUNCTION IDENT LPAREN param_def_list RPAREN COLON type_expr ASSIGN stmt_list { FunDef ($2, $4, $9) }
  | FUNC IDENT LPAREN param_def_list RPAREN ASSIGN stmt_list { FunDef ($2, $4, $7) }
  | FUNCTION IDENT LPAREN param_def_list RPAREN ASSIGN stmt_list { FunDef ($2, $4, $7) }
  ;

param_def_list:
  | { [] }
  | param_def { [$1] }
  | param_def COMMA param_def_list { $1 :: $3 }
  ;

param_def:
  | IDENT { $1 }
  | IDENT COLON type_expr { $1 }
  ;

data_def:
  | DATA IDENT ASSIGN constructor_defs { ClassDef ($2, []) }
  ;

constructor_defs:
  | constructor_def { [$1] }
  | constructor_def PIPE constructor_defs { $1 :: $3 }
  ;

constructor_def:
  | IDENT LPAREN type_list RPAREN { Expr (Constructor ($1, [])) }
  | IDENT { Expr (Constructor ($1, [])) }
  ;

import_stmt:
  | IMPORT IDENT { Import $2 }
  | FROM IDENT IMPORT IDENT { ImportFrom ($2, $4) }
  ;

%% 