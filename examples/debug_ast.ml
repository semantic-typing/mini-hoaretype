open Core_parser_module
open Core_lang
open Deep_core_lang

let () =
  let path = "examples/simple_test.fl" in
  print_endline "=== AST Debug ===";
  print_endline ("Parsing: " ^ path);
  
  match parse_core_file path with
  | Ok ast ->
      print_endline "\n1. Core-lang AST:";
      print_endline (Core_lang.show_program ast);
      
      print_endline "\n2. Translating to deep-core...";
      let deep_ast = of_core_program ast in
      
      print_endline "\n3. Deep-core AST:";
      List.iteri (fun i expr ->
        print_endline ("Expression " ^ string_of_int (i+1) ^ ":");
        print_endline (show_expr expr)
      ) deep_ast;
      
      print_endline "\n4. Deep-core code:";
      print_endline (show_program deep_ast)
      
  | Error (ParseError msg) -> Printf.printf "ParseError: %s\n" msg
  | Error _ -> Printf.printf "Other error\n" 