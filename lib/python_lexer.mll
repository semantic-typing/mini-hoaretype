{
open Python_parser
open Lexing

exception Error of string

let incr_linenum lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let alphanum = alpha | digit | '_'
let whitespace = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let integer = digit+
let float = digit+ '.' digit* | digit* '.' digit+
let identifier = alpha alphanum*
let string_literal = '"' [^ '"']* '"' | "'" [^ ''']* "'"

rule token = parse
  | whitespace    { token lexbuf }
  | newline       { incr_linenum lexbuf; token lexbuf }
  | '#' [^ '\n']* '\n' { incr_linenum lexbuf; token lexbuf }
  | integer as i  { INT (int_of_string i) }
  | float as f    { FLOAT (float_of_string f) }
  | string_literal as s { STRING (String.sub s 1 (String.length s - 2)) }
  | "True"        { TRUE }
  | "False"       { FALSE }
  | "None"        { NONE }
  | "def"         { DEF }
  | "if"          { IF }
  | "else"        { ELSE }
  | "elif"        { ELIF }
  | "while"       { WHILE }
  | "for"         { FOR }
  | "in"          { IN }
  | "return"      { RETURN }
  | "class"       { CLASS }
  | "import"      { IMPORT }
  | "from"        { FROM }
  | "as"          { AS }
  | "lambda"      { LAMBDA }
  | "and"         { AND }
  | "or"          { OR }
  | "not"         { NOT }
  | "is"          { IS }
  | "is not"      { IS_NOT }
  | "=="          { EQ }
  | "!="          { NEQ }
  | "<"           { LT }
  | "<="          { LE }
  | ">"           { GT }
  | ">="          { GE }
  | "+"           { PLUS }
  | "-"           { MINUS }
  | "*"           { TIMES }
  | "/"           { DIV }
  | "//"          { FLOOR_DIV }
  | "%"           { MOD }
  | "**"          { POW }
  | "="           { ASSIGN }
  | "+="          { PLUS_ASSIGN }
  | "-="          { MINUS_ASSIGN }
  | "*="          { TIMES_ASSIGN }
  | "/="          { DIV_ASSIGN }
  | "("           { LPAREN }
  | ")"           { RPAREN }
  | "["           { LBRACKET }
  | "]"           { RBRACKET }
  | "{"           { LBRACE }
  | "}"           { RBRACE }
  | ","           { COMMA }
  | ":"           { COLON }
  | "."           { DOT }
  | ";"           { SEMICOLON }
  | identifier as id { ID id }
  | eof           { EOF }
  | _ as c        { raise (Error ("Unexpected char: " ^ Char.escaped c)) }

{
} 