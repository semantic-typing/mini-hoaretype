%{
open Core_lang
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> IDENT
%token LET IN IF THEN ELSE WHILE DO FOR FUN RETURN MATCH WITH DATA IMPORT TRUE FALSE NULL
%token PLUS MINUS TIMES DIV MOD POW EQ NEQ LT LE GT GE AND OR NOT PIPE ARROW COLON ASSIGN
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COMMA SEMICOLON DOT EOF
%token TYPE_INT TYPE_FLOAT TYPE_STRING TYPE_BOOL TYPE_UNIT
%token DONE

%start program
%type <Core_lang.program> program

%%
program:
  | stmt_list EOF { $1 }
  | expr EOF { [Expr $1] }
;

stmt_list:
  | stmt SEMICOLON stmt_list { $1 :: $3 }
  | stmt { [$1] }
;

stmt:
  | let_stmt { $1 }
  | assign_stmt { $1 }
  | return_stmt { $1 }
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }
  | func_def { $1 }
  | data_def { $1 }
  | import_stmt { $1 }
  | block_stmt { $1 }
;

let_stmt:
  | LET IDENT ASSIGN expr IN block_expr { Let ($2, $4, $6) }
;

assign_stmt:
  | IDENT ASSIGN expr { Assign ($1, $3) }
;

return_stmt:
  | RETURN expr { Return $2 }
;

if_stmt:
  | IF expr THEN stmt_list ELSE stmt_list { If ($2, $4, $6) }
;

while_stmt:
  | WHILE expr DO stmt_list DONE { While ($2, $4) }
;

for_stmt:
  | FOR IDENT IN expr DO stmt_list { For ($2, $4, $6) }
;

func_def:
  | FUN IDENT LPAREN param_list RPAREN ASSIGN block_stmt { FunDef ($2, $4, match $7 with Block b -> b | _ -> [$7]) }
;

data_def:
  | DATA IDENT ASSIGN constructor_defs { DataDef ($2, $4) }
;

constructor_defs:
  | constructor_def { [$1] }
  | constructor_def PIPE constructor_defs { $1 :: $3 }
;

constructor_def:
  | IDENT LPAREN type_list RPAREN { ($1, $3) }
  | IDENT { ($1, []) }
;

import_stmt:
  | IMPORT IDENT { Import $2 }
;

block_stmt:
  | LBRACE stmt_list RBRACE { Block $2 }
;

param_list:
  | /* empty */ { [] }
  | IDENT { [$1] }
  | IDENT COMMA param_list { $1 :: $3 }
;

expr:
  | LET IDENT ASSIGN expr IN block_expr { Let ($2, $4, $6) }
  | IF expr THEN expr ELSE expr { If ($2, $4, $6) }
  | lambda_expr { $1 }
  | match_expr { $1 }
  | app_expr { $1 }
  | bin_expr { $1 }
  | unary_expr { $1 }
  | primary_expr { $1 }
;

lambda_expr:
  | FUN param_list ARROW expr { Lambda ($2, $4) }
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
  | IDENT LPAREN pattern_list RPAREN { PConstructor ($1, $3) }
;

pattern_list:
  | /* empty */ { [] }
  | pattern { [$1] }
  | pattern COMMA pattern_list { $1 :: $3 }
;

app_expr:
  | primary_expr LPAREN expr_list RPAREN { App ($1, $3) }
  | primary_expr primary_expr { App ($1, [$2]) }
;

expr_list:
  | /* empty */ { [] }
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
  | record_literal { $1 }
  | field_access { $1 }
  | index_access { $1 }
;

literal:
  | INT { Int $1 }
  | FLOAT { Float $1 }
  | STRING { String $1 }
  | TRUE { Bool true }
  | FALSE { Bool false }
  | NULL { Null }
;

tuple_expr:
  | LPAREN expr COMMA expr_list RPAREN { Tuple ($2 :: $4) }
;

record_literal:
  | LBRACE field_list RBRACE { Record $2 }
;

field_list:
  | /* empty */ { [] }
  | field { [$1] }
  | field COMMA field_list { $1 :: $3 }
;

field:
  | IDENT COLON expr { ($1, $3) }
;

field_access:
  | primary_expr DOT IDENT { FieldAccess ($1, $3) }
;

index_access:
  | primary_expr LBRACKET expr RBRACKET { Index ($1, $3) }
;

type_expr:
  | IDENT { TVar $1 }
  | basic_type { $1 }
  | type_expr ARROW type_expr { TArrow ($1, $3) }
  | LPAREN type_expr RPAREN { $2 }
  | type_expr PIPE type_expr { TUnion ($1, $3) }
  | type_expr AND type_expr { TIntersection ($1, $3) }
  | NOT type_expr { TNegation $2 }
  | tuple_type { $1 }
  | constructor_type { $1 }
;

basic_type:
  | TYPE_INT { TInt }
  | TYPE_FLOAT { TFloat }
  | TYPE_STRING { TString }
  | TYPE_BOOL { TBool }
  | TYPE_UNIT { TUnit }
;

tuple_type:
  | LPAREN type_expr TIMES type_list RPAREN { TTuple ($2 :: $4) }
;

type_list:
  | /* empty */ { [] }
  | type_expr { [$1] }
  | type_expr TIMES type_list { $1 :: $3 }
;

constructor_type:
  | IDENT LPAREN type_list RPAREN { TConstructor ($1, $3) }
  | IDENT { TConstructor ($1, []) }
;

block_expr:
  | stmt_list expr { Block ($1 @ [Expr $2]) }
  | stmt_list { Block $1 }
  | expr { $1 }
  | LBRACE stmt_list RBRACE expr { Block ($2 @ [Expr $4]) }
  | LBRACE stmt_list RBRACE { Block $2 }
;

%% 