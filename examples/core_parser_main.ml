open Core_parser_module
open Core_lang
open Deep_core_lang

let () =
  let path = "examples/complex1.fl" in
  Printf.printf "Parsing %s...\n" path;
  match parse_core_file path with
  | Ok ast ->
      print_endline "AST:";
      print_endline (Core_lang.show_program ast);
      print_endline "\nTranslating to deep-core...";
      let deep_ast = of_core_program ast in
      let code = show_program deep_ast in
      print_endline "Deep-core code:";
      print_endline code
  | Error (ParseError msg) -> Printf.printf "ParseError: %s\n" msg
  | Error _ -> Printf.printf "Other error\n" 