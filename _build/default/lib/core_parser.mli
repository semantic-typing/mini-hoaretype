
(* The type of tokens. *)

type token = 
  | WITH
  | WHILE
  | TYPE_UNIT
  | TYPE_STRING
  | TYPE_INT
  | TYPE_FLOAT
  | TYPE_BOOL
  | TRUE
  | TIMES
  | THEN
  | STRING of (string)
  | SEMICOLON
  | RPAREN
  | RETURN
  | RBRACKET
  | RBRACE
  | POW
  | PLUS
  | PIPE
  | OR
  | NULL
  | NOT
  | NEQ
  | MOD
  | MINUS
  | MATCH
  | LT
  | LPAREN
  | LET
  | LE
  | LBRACKET
  | LBRACE
  | INT of (int)
  | IN
  | IMPORT
  | IF
  | IDENT of (string)
  | GT
  | GE
  | FUN
  | FOR
  | FLOAT of (float)
  | FALSE
  | EQ
  | EOF
  | ELSE
  | DOT
  | DONE
  | DO
  | DIV
  | DATA
  | COMMA
  | COLON
  | ASSIGN
  | ARROW
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val program: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Core_lang.program)
