{
open Core_parser
open Lexing

exception Error of string

let incr_linenum lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let alphanum = ['a'-'z' 'A'-'Z' '0'-'9' '_']
let whitespace = [' ' '\t']
let newline = '\r' | '\n' | "\r\n"

rule token = parse
  | whitespace+ { token lexbuf }
  | newline     { incr_linenum lexbuf; token lexbuf }
  | "(*"       { comment lexbuf }
  
  (* Keywords *)
  | "let"      { LET }
  | "in"       { IN }
  | "if"       { IF }
  | "then"     { THEN }
  | "else"     { ELSE }
  | "while"    { WHILE }
  | "do"       { DO }
  | "for"      { FOR }
  | "func"     { FUNC }
  | "function" { FUNCTION }
  | "fun"      { FUN }
  | "return"   { RETURN }
  | "match"    { MATCH }
  | "with"     { WITH }
  | "data"     { DATA }
  | "import"   { IMPORT }
  | "from"     { FROM }
  
  (* Type names (lowercase) *)
  | "int"      { TYPE_INT }
  | "float"    { TYPE_FLOAT }
  | "string"   { TYPE_STRING }
  | "bool"     { TYPE_BOOL }
  | "unit"     { TYPE_UNIT }
  
  (* Boolean literals *)
  | "true"     { TRUE }
  | "false"    { FALSE }
  | "null"     { NULL }
  
  (* Identifiers *)
  | alpha alphanum* as id { IDENT id }
  
  (* Numbers *)
  | digit+ as n { INT (int_of_string n) }
  | digit+ "." digit+ as f { FLOAT (float_of_string f) }
  
  (* Strings *)
  | '"' ([^'"']* as s) '"' { STRING s }
  
  (* Operators *)
  | "+"        { PLUS }
  | "-"        { MINUS }
  | "*"        { TIMES }
  | "/"        { DIV }
  | "%"        { MOD }
  | "=="       { EQ }
  | "!="       { NEQ }
  | "<"        { LT }
  | "<="       { LE }
  | ">"        { GT }
  | ">="       { GE }
  | "&&"       { AND }
  | "||"       { OR }
  | "!"        { NOT }
  | "|"        { PIPE }
  | "->"       { ARROW }
  | ":"        { COLON }
  
  (* Punctuation *)
  | "("        { LPAREN }
  | ")"        { RPAREN }
  | "["        { LBRACKET }
  | "]"        { RBRACKET }
  | "{"        { LBRACE }
  | "}"        { RBRACE }
  | ","        { COMMA }
  | ";"        { SEMICOLON }
  | "."        { DOT }
  | "="        { ASSIGN }
  
  (* End of file *)
  | eof        { EOF }
  
  (* Error *)
  | _ as c     { raise (Error ("Unexpected char: " ^ Char.escaped c)) }

and comment = parse
  | "*)"       { token lexbuf }
  | newline    { incr_linenum lexbuf; comment lexbuf }
  | _          { comment lexbuf }
  | eof        { raise (Error "Unterminated comment") }

{
} 