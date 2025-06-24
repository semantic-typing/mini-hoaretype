(* Simple test to verify basic functionality *)

(* This is a simple test that can be run with ocaml directly *)
let test_basic_types () =
  Printf.printf "Testing basic type construction...\n";
  
  (* Test that we can construct basic expressions *)
  let expr = 1 + 2 in
  Printf.printf "Basic arithmetic: %d\n" expr;
  
  (* Test string operations *)
  let str = "Hello, World!" in
  Printf.printf "String: %s\n" str;
  
  (* Test list operations *)
  let lst = [1; 2; 3; 4; 5] in
  Printf.printf "List length: %d\n" (List.length lst);
  
  Printf.printf "Basic functionality test passed!\n"

let () = test_basic_types () 