open Mini_hoaretype.Python_to_core

let python_code =
  "def add(a, b):\n\
     return a + b\n\
\n\
   def mul(a, b):\n\
     return a * b\n\
\n\
   x = 10\n\
   y = 2\n\
   z = add(x, y)\n\
   w = mul(z, 3)\n\
   f = 3.14\n\
   s = \"hello\"\n\
   nums = [1, 2, 3, 4]\n\
   if x > y:\n\
       m = x - y\n\
   else:\n\
       m = y - x\n\
   print(z)\n\
   print(w)\n\
   print(f)\n\
   print(s)\n\
   print(nums)\n\
   print(m)\n"

let () =
  match convert python_code with
  | Ok prog ->
      Printf.printf "Successfully:\n";
      Printf.printf "%s\n" (print_core_ast prog)
  | Error (ParseError msg) ->
      Printf.printf "ParseError: %s\n" msg
  | Error (TypeError msg) ->
      Printf.printf "TypeError: %s\n" msg
  | Error (UnificationError msg) ->
      Printf.printf "UnificationError: %s\n" msg
