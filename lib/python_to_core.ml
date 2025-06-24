open Core_lang

exception ParseError of string

let parse_python_to_core (source_code : string) : program result =
  try
    let lexbuf = Lexing.from_string source_code in
    let core_ast = Python_parser.program Python_lexer.token lexbuf in
    Ok core_ast
  with
  | Python_lexer.Error msg -> Error (ParseError ("Lexer error: " ^ msg))
  | Python_parser.Error -> Error (ParseError "Parser error")
  | e -> Error (ParseError ("Unexpected error: " ^ Printexc.to_string e))


let parse_python_file (filename : string) : program result =
  try
    let ic = open_in filename in
    let source_code = really_input_string ic (in_channel_length ic) in
    close_in ic;
    parse_python_to_core source_code
  with
  | Sys_error msg -> Error (ParseError ("File error: " ^ msg))
  | e -> Error (ParseError ("Unexpected error: " ^ Printexc.to_string e))

let rec pp_expr = function
  | Var x -> x
  | Int n -> string_of_int n
  | Float f -> string_of_float f
  | String s -> "\"" ^ s ^ "\""
  | Constructor (c, []) -> c
  | Constructor (c, args) -> c ^ "(" ^ String.concat ", " (List.map pp_expr args) ^ ")"
  | App (f, args) -> pp_expr f ^ "(" ^ String.concat ", " (List.map pp_expr args) ^ ")"
  | Let (x, e1, e2) -> "let " ^ x ^ " = " ^ pp_expr e1 ^ " in " ^ pp_expr e2
  | Lambda (params, body) -> "λ" ^ String.concat " " params ^ ". " ^ pp_expr body
  | Match (e, cases) ->
      "match " ^ pp_expr e ^ " with\n" ^
      String.concat "\n" (List.map (fun (p, e') -> "  " ^ pp_pattern p ^ " -> " ^ pp_expr e') cases)
  | BinOp (op, e1, e2) -> "(" ^ pp_expr e1 ^ " " ^ pp_binop op ^ " " ^ pp_expr e2 ^ ")"
  | UnaryOp (op, e) -> pp_unop op ^ pp_expr e
  | FieldAccess (e, field) -> pp_expr e ^ "." ^ field
  | Index (e1, e2) -> pp_expr e1 ^ "[" ^ pp_expr e2 ^ "]"
  | Tuple es -> "(" ^ String.concat ", " (List.map pp_expr es) ^ ")"

and pp_pattern = function
  | PVar x -> x
  | PConstructor (c, []) -> c
  | PConstructor (c, ps) -> c ^ "(" ^ String.concat ", " (List.map pp_pattern ps) ^ ")"

and pp_binop = function
  | Plus -> "+"
  | Minus -> "-"
  | Times -> "*"
  | Div -> "/"
  | FloorDiv -> "//"
  | Mod -> "%"
  | Pow -> "**"
  | Eq -> "=="
  | Neq -> "!="
  | Lt -> "<"
  | Le -> "<="
  | Gt -> ">"
  | Ge -> ">="
  | And -> "&&"
  | Or -> "||"
  | Is -> "is"
  | IsNot -> "is not"

and pp_unop = function
  | Pos -> "+"
  | Neg -> "-"
  | Not -> "!"

let rec pp_stmt = function
  | Expr e -> pp_expr e
  | Let (x, e1, e2) -> "let " ^ x ^ " = " ^ pp_expr e1 ^ " in " ^ pp_expr e2
  | Return e -> "return " ^ pp_expr e
  | If (cond, then_branch, else_branch) ->
      "if " ^ pp_expr cond ^ " then\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) then_branch) ^ "\n" ^
      "else\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) else_branch)
  | While (cond, body) ->
      "while " ^ pp_expr cond ^ " do\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | For (var, iter, body) ->
      "for " ^ var ^ " in " ^ pp_expr iter ^ " do\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | FunDef (name, params, body) ->
      "fun " ^ name ^ "(" ^ String.concat ", " params ^ ") =\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | ClassDef (name, body) ->
      "class " ^ name ^ " =\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | Import module_name -> "import " ^ module_name
  | ImportFrom (module_name, item) -> "from " ^ module_name ^ " import " ^ item

let pp_program prog = String.concat "\n" (List.map pp_stmt prog)

let print_core_ast (prog : program) : string =
  pp_program prog

let python_to_core_string (source_code : string) : string result =
  match parse_python_to_core source_code with
  | Ok prog -> Ok (print_core_ast prog)
  | Error e -> Error e

let python_file_to_core_string (filename : string) : string result =
  match parse_python_file filename with
  | Ok prog -> Ok (print_core_ast prog)
  | Error e -> Error e


let convert = parse_python_to_core
let convert_file = parse_python_file
let convert_to_string = python_to_core_string
let convert_file_to_string = python_file_to_core_string 