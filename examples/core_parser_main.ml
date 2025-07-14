open Core_parser_module
open Core_lang

let () =
  let path = "examples/fib.fl" in
  Printf.printf "Parsing %s...\n" path;
  match parse_core_file path with
  | Ok ast ->
      print_endline "AST:";
      print_endline (show_program ast)
  | Error (ParseError msg) -> Printf.printf "ParseError: %s\n" msg
  | Error _ -> Printf.printf "Other error\n" 