open Core_lang
open Sys

exception ParseError of string

(* Parse Core Language source code to AST *)
let parse_core (source_code : string) : program result =
  try
    let lexbuf = Lexing.from_string source_code in
    let core_ast = Core_parser.program Core_lexer.token lexbuf in
    Ok core_ast
  with
  | Core_lexer.Error msg -> Error (ParseError ("Lexer error: " ^ msg))
  | Core_parser.Error -> Error (ParseError "Parser error")
  | e -> Error (ParseError ("Unexpected error: " ^ Printexc.to_string e))

(* Parse Core Language from file *)
let parse_core_file (filename : string) : program result =
  try
    let ic = open_in filename in
    let source_code = really_input_string ic (in_channel_length ic) in
    close_in ic;
    parse_core source_code
  with
  | Sys_error msg -> Error (ParseError ("File error: " ^ msg))
  | e -> Error (ParseError ("Unexpected error: " ^ Printexc.to_string e))

(* Parse a string into a Core Language program *)
let parse_program input =
  let lexbuf = Lexing.from_string input in
  try
    let program = Core_parser.program Core_lexer.token lexbuf in
    Ok program
  with
  | Core_lexer.Error msg ->
      Error (ParseError ("Lexer error: " ^ msg))
  | Core_parser.Error ->
      let pos = Lexing.lexeme_start_p lexbuf in
      Error (ParseError ("Parser error at position " ^ string_of_int pos.pos_cnum))

