open Core_lang
open Sys

exception ParseError of string

(* Parse Core Language source code to AST *)
let parse_core (source_code : string) : program result =
  let lexbuf = Lexing.from_string source_code in
  try
    print_endline ("Source code: [" ^ source_code ^ "]");
    let core_ast = Core_parser.program Core_lexer.token lexbuf in
    Ok core_ast
  with
  | Core_lexer.Error msg -> Error (ParseError ("Lexer error: " ^ msg))
  | Core_parser.Error ->
      let pos = Lexing.lexeme_start_p lexbuf in
      Error (ParseError ("Parser error at position " ^ string_of_int pos.pos_cnum))
  | e -> Error (ParseError ("Unexpected error: " ^ Printexc.to_string e))

let rec read_all_lines ic acc =
  try
    let line = input_line ic in
    read_all_lines ic (acc ^ line ^ "\n")
  with End_of_file -> acc

(* Parse Core Language from file *)
let parse_core_file (filename : string) : program result =
  try
    let ic = open_in filename in
    let source_code = read_all_lines ic "" in
    close_in ic;
    print_endline "File read OK";
    let res = parse_core source_code in
    print_endline "Parse core OK";
    res
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

