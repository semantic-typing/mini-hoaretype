open Deep_core_lang
open Type_inference

let () =
  print_endline "Debug Type Inference Test";
  print_endline "==========================";
  
  (* Test with a very simple program *)
  let simple_program = [
    Let ("x", Int 5, Var "x")
  ] in
  
  print_endline "\nDeep-core program:";
  print_endline (show_program simple_program);
  
  print_endline "\nPerforming type inference...";
  try
    let (types, substitution) = type_infer_program simple_program in
    print_endline (show_type_inference_result (types, substitution))
  with e ->
    print_endline ("Error: " ^ Printexc.to_string e);
    print_endline ("Backtrace: " ^ Printexc.get_backtrace ()) 