%{
open Core_lang
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> ID
%token TRUE FALSE NONE
%token DEF IF ELSE ELIF WHILE FOR IN RETURN
%token CLASS IMPORT FROM AS LAMBDA
%token AND OR NOT IS IS_NOT
%token EQ NEQ LT LE GT GE
%token PLUS MINUS TIMES DIV FLOOR_DIV MOD POW
%token ASSIGN PLUS_ASSIGN MINUS_ASSIGN TIMES_ASSIGN DIV_ASSIGN
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE
%token COMMA COLON DOT SEMICOLON
%token EOF

%left OR
%left AND
%left IS IS_NOT
%left EQ NEQ LT LE GT GE
%left PLUS MINUS
%left TIMES DIV FLOOR_DIV MOD
%right POW
%right UMINUS UPLUS
%right NOT

%start program
%type <Core_lang.program> program

%%

program:
  | stmt_list EOF { $1 }
  ;

stmt_list:
  | stmt { [$1] }
  | stmt stmt_list { $1 :: $2 }
  ;

stmt:
  | simple_stmt { $1 }
  | compound_stmt { $1 }
  ;

simple_stmt:
  | expr_stmt { $1 }
  | return_stmt { $1 }
  | import_stmt { $1 }
  ;

expr_stmt:
  | expr { Expr $1 }
  | assignment { $1 }
  ;

assignment:
  | ID ASSIGN expr { Let ($1, $3, Var $1) }
  | ID PLUS_ASSIGN expr { Let ($1, BinOp (Plus, Var $1, $3), Var $1) }
  | ID MINUS_ASSIGN expr { Let ($1, BinOp (Minus, Var $1, $3), Var $1) }
  | ID TIMES_ASSIGN expr { Let ($1, BinOp (Times, Var $1, $3), Var $1) }
  | ID DIV_ASSIGN expr { Let ($1, BinOp (Div, Var $1, $3), Var $1) }
  ;

return_stmt:
  | RETURN expr { Return $2 }
  | RETURN { Return (Constructor ("None", [])) }
  ;

import_stmt:
  | IMPORT ID { Import $2 }
  | FROM ID IMPORT ID { ImportFrom ($2, $4) }
  ;

compound_stmt:
  | if_stmt { $1 }
  | while_stmt { $1 }
  | for_stmt { $1 }
  | func_def { $1 }
  | class_def { $1 }
  ;

if_stmt:
  | IF expr COLON stmt_list { If ($2, $4, []) }
  | IF expr COLON stmt_list ELSE COLON stmt_list { If ($2, $4, $7) }
  | IF expr COLON stmt_list elif_list { If ($2, $4, $5) }
  ;

elif_list:
  | ELIF expr COLON stmt_list { [If ($2, $4, [])] }
  | ELIF expr COLON stmt_list ELSE COLON stmt_list { [If ($2, $4, $7)] }
  | ELIF expr COLON stmt_list elif_list { If ($2, $4, []) :: $5 }
  ;

while_stmt:
  | WHILE expr COLON stmt_list { While ($2, $4) }
  ;

for_stmt:
  | FOR ID IN expr COLON stmt_list { For ($2, $4, $6) }
  ;

func_def:
  | DEF ID LPAREN param_list RPAREN COLON stmt_list { FunDef ($2, $4, $7) }
  | DEF ID LPAREN RPAREN COLON stmt_list { FunDef ($2, [], $6) }
  ;

param_list:
  | ID { [$1] }
  | ID COMMA param_list { $1 :: $3 }
  ;

class_def:
  | CLASS ID COLON stmt_list { ClassDef ($2, $4) }
  | CLASS ID LPAREN ID RPAREN COLON stmt_list { ClassDef ($2, $7) }
  ;

expr:
  | primary { $1 }
  | expr PLUS expr { BinOp (Plus, $1, $3) }
  | expr MINUS expr { BinOp (Minus, $1, $3) }
  | expr TIMES expr { BinOp (Times, $1, $3) }
  | expr DIV expr { BinOp (Div, $1, $3) }
  | expr FLOOR_DIV expr { BinOp (FloorDiv, $1, $3) }
  | expr MOD expr { BinOp (Mod, $1, $3) }
  | expr POW expr { BinOp (Pow, $1, $3) }
  | expr EQ expr { BinOp (Eq, $1, $3) }
  | expr NEQ expr { BinOp (Neq, $1, $3) }
  | expr LT expr { BinOp (Lt, $1, $3) }
  | expr LE expr { BinOp (Le, $1, $3) }
  | expr GT expr { BinOp (Gt, $1, $3) }
  | expr GE expr { BinOp (Ge, $1, $3) }
  | expr AND expr { BinOp (And, $1, $3) }
  | expr OR expr { BinOp (Or, $1, $3) }
  | expr IS expr { BinOp (Is, $1, $3) }
  | expr IS_NOT expr { BinOp (IsNot, $1, $3) }
  | MINUS expr %prec UMINUS { UnaryOp (Neg, $2) }
  | PLUS expr %prec UPLUS { UnaryOp (Pos, $2) }
  | NOT expr { UnaryOp (Not, $2) }
  | expr LPAREN arg_list RPAREN { App ($1, $3) }
  | expr LPAREN RPAREN { App ($1, []) }
  | expr DOT ID { FieldAccess ($1, $3) }
  | expr LBRACKET expr RBRACKET { Index ($1, $3) }
  | LAMBDA param_list COLON expr { Lambda ($2, $4) }
  | LAMBDA COLON expr { Lambda ([], $3) }
  ;

primary:
  | atom { $1 }
  | LPAREN expr RPAREN { $2 }
  ;

atom:
  | ID { Var $1 }
  | INT { Int $1 }
  | FLOAT { Float $1 }
  | STRING { String $1 }
  | TRUE { Constructor ("True", []) }
  | FALSE { Constructor ("False", []) }
  | NONE { Constructor ("None", []) }
  | list_literal { $1 }
  | dict_literal { $1 }
  | tuple_literal { $1 }
  ;

list_literal:
  | LBRACKET RBRACKET { Constructor ("List", []) }
  | LBRACKET expr_list RBRACKET { Constructor ("List", $2) }
  ;

dict_literal:
  | LBRACE RBRACE { Constructor ("Dict", []) }
  | LBRACE key_value_list RBRACE { Constructor ("Dict", $2) }
  ;

tuple_literal:
  | LPAREN RPAREN { Constructor ("Tuple", []) }
  | LPAREN expr COMMA RPAREN { Constructor ("Tuple", [$2]) }
  | LPAREN expr COMMA expr_list RPAREN { Constructor ("Tuple", $2 :: $4) }
  ;

expr_list:
  | expr { [$1] }
  | expr COMMA expr_list { $1 :: $3 }
  ;

key_value_list:
  | expr COLON expr { [Tuple [$1; $3]] }
  | expr COLON expr COMMA key_value_list { Tuple [$1; $3] :: $5 }
  ;

arg_list:
  | expr { [$1] }
  | expr COMMA arg_list { $1 :: $3 }
  ;

%%