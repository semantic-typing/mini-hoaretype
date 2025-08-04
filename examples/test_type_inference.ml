open Core_parser_module
open Core_lang
open Deep_core_lang
open Type_inference

let () =
  print_endline "Testing Type Inference System";
  print_endline "==============================";
  
  (* Test 1: Simple arithmetic *)
  let test1 = "let x = 5 + 3 in x" in
  print_endline "\nTest 1: Simple arithmetic";
  print_endline ("Input: " ^ test1);
  
  (* Test 2: Function definition *)
  let test2 = "let f = fun x -> x + 1 in f(5)" in
  print_endline "\nTest 2: Function definition";
  print_endline ("Input: " ^ test2);
  
  (* Test 3: Conditional *)
  let test3 = "let x = 10 in if x > 5 then x else 0" in
  print_endline "\nTest 3: Conditional";
  print_endline ("Input: " ^ test3);
  
  (* Test 4: Recursive function *)
  let test4 = "let rec fact = fun n -> if n <= 1 then 1 else n * fact(n-1) in fact(5)" in
  print_endline "\nTest 4: Recursive function";
  print_endline ("Input: " ^ test4);
  
  print_endline "\nNote: This is a test file. To run actual type inference, use core_parser_main.ml" 