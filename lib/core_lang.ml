(* Binary operators *)
type binop =
  | Plus
  | Minus
  | Times
  | Div
  | FloorDiv
  | Mod
  | Pow
  | Eq
  | Neq
  | Lt
  | Le
  | Gt
  | Ge
  | And
  | Or
  | Is
  | IsNot

(* Unary operators *)
type unop =
  | Pos
  | Neg
  | Not

(* Core language types *)
type typ =
  | TVar of string                   (* Type variable *)
  | TArrow of typ * typ              (* Function type *)
  | TConstructor of string * typ list (* ADT constructor type *)
  | TTuple of typ list               (* Product type *)
  | TUnion of typ * typ              (* Union type *)
  | TIntersection of typ * typ       (* Intersection type *)
  | TNegation of typ                 (* Negation type *)
  | TInt                             (* Integer type *)
  | TFloat                           (* Float type *)
  | TString                          (* String type *)
  | TBool                            (* Boolean type *)
  | TUnit                            (* Unit type *)

(* Core language expressions *)
type expr =
  | Var of string
  | Int of int
  | Float of float
  | String of string
  | Bool of bool
  | Null
  | Let of string * expr * expr
  | Lambda of string list * expr
  | App of expr * expr list
  | BinOp of binop * expr * expr
  | UnaryOp of unop * expr
  | If of expr * expr * expr
  | Match of expr * (pattern * expr) list
  | Tuple of expr list
  | Record of (string * expr) list
  | FieldAccess of expr * string
  | Index of expr * expr
  | Constructor of string * expr list
  | Block of stmt list

(* Patterns for pattern matching *)
and pattern =
  | PVar of string
  | PConstructor of string * pattern list

(* Core language statements *)
and stmt =
  | Expr of expr
  | Let of string * expr * expr
  | Assign of string * expr
  | Return of expr
  | If of expr * stmt list * stmt list
  | While of expr * stmt list
  | For of string * expr * stmt list
  | FunDef of string * string list * stmt list
  | DataDef of string * (string * typ list) list
  | Import of string
  | Block of stmt list

(* Core language program *)
type program = stmt list

(* Type annotations for expressions *)
type typed_expr = expr * typ option

(* Error types *)
type error =
  | TypeError of string
  | ParseError of string
  | UnificationError of string
  | TypeInferenceError of string

(* Result type for operations that can fail *)
type 'a result = Ok of 'a | Error of error

let rec pp_type = function
  | TVar x -> x
  | TInt -> "int"
  | TFloat -> "float"
  | TString -> "string"
  | TBool -> "bool"
  | TUnit -> "unit"
  | TArrow (t1, t2) -> "(" ^ pp_type t1 ^ " -> " ^ pp_type t2 ^ ")"
  | TConstructor (c, []) -> c
  | TConstructor (c, ts) -> c ^ "(" ^ String.concat ", " (List.map pp_type ts) ^ ")"
  | TTuple ts -> "(" ^ String.concat " * " (List.map pp_type ts) ^ ")"
  | TUnion (t1, t2) -> "(" ^ pp_type t1 ^ " | " ^ pp_type t2 ^ ")"
  | TIntersection (t1, t2) -> "(" ^ pp_type t1 ^ " & " ^ pp_type t2 ^ ")"
  | TNegation t -> "~" ^ pp_type t

(* Pretty printer for expressions *)
let rec pp_expr = function
  | Var x -> x
  | Int n -> string_of_int n
  | Float f -> string_of_float f
  | String s -> "\"" ^ s ^ "\""
  | Bool b -> string_of_bool b
  | Null -> "null"
  | Constructor (c, []) -> c
  | Constructor (c, args) -> c ^ "(" ^ String.concat ", " (List.map pp_expr args) ^ ")"
  | App (func, []) -> pp_expr func
  | App (func, args) -> pp_expr func ^ "(" ^ String.concat ", " (List.map pp_expr args) ^ ")"
  | Let (x, e1, e2) -> "let " ^ x ^ " = " ^ pp_expr e1 ^ " in " ^ pp_expr e2
  | Lambda (params, body) -> "\\" ^ String.concat " " params ^ " -> " ^ pp_expr body
  | Match (e, cases) ->
      "match " ^ pp_expr e ^ " with\n" ^
      String.concat "\n" (List.map (fun (p, e) -> "  | " ^ pp_pattern p ^ " -> " ^ pp_expr e) cases)
  | BinOp (op, e1, e2) -> "(" ^ pp_expr e1 ^ " " ^ pp_binop op ^ " " ^ pp_expr e2 ^ ")"
  | UnaryOp (op, e) -> pp_unop op ^ pp_expr e
  | If (cond, then_expr, else_expr) ->
      "if " ^ pp_expr cond ^ " then\n" ^
      pp_expr then_expr ^ "\n" ^
      "else\n" ^
      pp_expr else_expr
  | FieldAccess (e, field) -> pp_expr e ^ "." ^ field
  | Index (e, i) -> pp_expr e ^ "[" ^ pp_expr i ^ "]"
  | Tuple es -> "(" ^ String.concat ", " (List.map pp_expr es) ^ ")"
  | Record fields -> "{" ^ String.concat ", " (List.map (fun (k, v) -> k ^ ": " ^ pp_expr v) fields) ^ "}"
  | Block stmts -> "{\n" ^ String.concat "\n" (List.map pp_stmt stmts) ^ "\n}"

and pp_stmt = function
  | Expr e -> pp_expr e
  | Let (x, e1, e2) -> "let " ^ x ^ " = " ^ pp_expr e1 ^ " in " ^ pp_expr e2
  | Assign (x, e) -> x ^ " = " ^ pp_expr e
  | Return e -> "return " ^ pp_expr e
  | If (cond, then_stmts, else_stmts) ->
      "if " ^ pp_expr cond ^ " then\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) then_stmts) ^ "\n" ^
      "else\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) else_stmts)
  | While (cond, body) ->
      "while " ^ pp_expr cond ^ " do\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | For (var, iter, body) ->
      "for " ^ var ^ " in " ^ pp_expr iter ^ " do\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | FunDef (name, params, body) ->
      "def " ^ name ^ "(" ^ String.concat ", " params ^ "):\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | DataDef (name, fields) ->
      "data " ^ name ^ ":\n" ^
      String.concat "\n" (List.map (fun (k, ts) -> "  " ^ k ^ ": " ^ String.concat ", " (List.map pp_type ts)) fields)
  | Import module_name -> "import " ^ module_name
  | Block stmts -> "{\n" ^ String.concat "\n" (List.map pp_stmt stmts) ^ "\n}"

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
  | Not -> "not "

(* Pretty printer for programs *)
let pp_program program =
  String.concat "\n" (List.map pp_stmt program)

let rec show_expr ?(indent=0) = function
  | Var x -> Printf.sprintf "%sVar(%s)" (String.make indent ' ') x
  | Int n -> Printf.sprintf "%sInt(%d)" (String.make indent ' ') n
  | Float f -> Printf.sprintf "%sFloat(%f)" (String.make indent ' ') f
  | String s -> Printf.sprintf "%sString(\"%s\")" (String.make indent ' ') s
  | Bool b -> Printf.sprintf "%sBool(%b)" (String.make indent ' ') b
  | Null -> Printf.sprintf "%sNull" (String.make indent ' ')
  | Let (x, e1, e2) ->
      Printf.sprintf "%sLet(%s,\n%s,\n%s)" (String.make indent ' ') x
        (show_expr ~indent:(indent+2) e1)
        (show_expr ~indent:(indent+2) e2)
  | Lambda (params, body) ->
      Printf.sprintf "%sLambda([%s],\n%s)" (String.make indent ' ') (String.concat ", " params)
        (show_expr ~indent:(indent+2) body)
  | App (f, args) ->
      Printf.sprintf "%sApp(\n%s,\n%s)" (String.make indent ' ')
        (show_expr ~indent:(indent+2) f)
        (String.concat ",\n" (List.map (show_expr ~indent:(indent+2)) args))
  | BinOp (_, _, _) | UnaryOp (_, _) -> Printf.sprintf "%s<binop/unop expr>" (String.make indent ' ')
  | If (c, t, e) ->
      Printf.sprintf "%sIf(\n%s,\n%s,\n%s)" (String.make indent ' ')
        (show_expr ~indent:(indent+2) c)
        (show_expr ~indent:(indent+2) t)
        (show_expr ~indent:(indent+2) e)
  | Match (e, cases) ->
      Printf.sprintf "%sMatch(\n%s,\n%s)" (String.make indent ' ')
        (show_expr ~indent:(indent+2) e)
        (String.concat ",\n" (List.map (fun (p, e) -> Printf.sprintf "%s-> %s" (show_pattern p) (show_expr ~indent:(indent+2) e)) cases))
  | Tuple es -> Printf.sprintf "%sTuple([%s])" (String.make indent ' ') (String.concat ", " (List.map (show_expr ~indent:(indent+2)) es))
  | Record fields -> Printf.sprintf "%sRecord([%s])" (String.make indent ' ') (String.concat ", " (List.map (fun (k, v) -> k ^ ": " ^ show_expr ~indent:(indent+2) v) fields))
  | FieldAccess (e, f) -> Printf.sprintf "%sFieldAccess(%s, %s)" (String.make indent ' ') (show_expr ~indent:(indent+2) e) f
  | Index (e, i) -> Printf.sprintf "%sIndex(%s, %s)" (String.make indent ' ') (show_expr ~indent:(indent+2) e) (show_expr ~indent:(indent+2) i)
  | Constructor (c, args) -> Printf.sprintf "%sConstructor(%s, [%s])" (String.make indent ' ') c (String.concat ", " (List.map (show_expr ~indent:(indent+2)) args))
  | Block stmts -> Printf.sprintf "%sBlock([\n%s\n%s])" (String.make indent ' ') (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) stmts)) (String.make indent ' ')
  
  and show_pattern = function
    | PVar x -> "PVar(" ^ x ^ ")"
    | PConstructor (c, ps) -> "PConstructor(" ^ c ^ ", [" ^ String.concat ", " (List.map show_pattern ps) ^ "] )"

and show_stmt ?(indent=0) = function
  | Expr e -> Printf.sprintf "%sExpr(\n%s\n%s)" (String.make indent ' ') (show_expr ~indent:(indent+2) e) (String.make indent ' ')
  | Let (x, e1, e2) ->
      Printf.sprintf "%sLetStmt(%s,\n%s,\n%s)" (String.make indent ' ') x
        (show_expr ~indent:(indent+2) e1)
        (show_expr ~indent:(indent+2) e2)
  | Assign (x, e) -> Printf.sprintf "%sAssign(%s, %s)" (String.make indent ' ') x (show_expr ~indent:(indent+2) e)
  | Return e -> Printf.sprintf "%sReturn(%s)" (String.make indent ' ') (show_expr ~indent:(indent+2) e)
  | If (cond, t, e) ->
      Printf.sprintf "%sIfStmt(\n%s,\n[%s],\n[%s])" (String.make indent ' ')
        (show_expr ~indent:(indent+2) cond)
        (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) t))
        (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) e))
  | While (cond, body) ->
      Printf.sprintf "%sWhile(\n%s,\n[%s])" (String.make indent ' ') (show_expr ~indent:(indent+2) cond) (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) body))
  | For (v, iter, body) ->
      Printf.sprintf "%sFor(%s, %s, [%s])" (String.make indent ' ') v (show_expr ~indent:(indent+2) iter) (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) body))
  | FunDef (name, params, body) ->
      Printf.sprintf "%sFunDef(%s, [%s], [%s])" (String.make indent ' ') name (String.concat ", " params) (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) body))
  | DataDef (name, fields) ->
      Printf.sprintf "%sDataDef(%s, [%s])" (String.make indent ' ') name (String.concat ", " (List.map (fun (k, _) -> k ^ ": ...") fields))
  | Import m -> Printf.sprintf "%sImport(%s)" (String.make indent ' ') m
  | Block stmts -> Printf.sprintf "%sBlock([\n%s\n%s])" (String.make indent ' ') (String.concat ";\n" (List.map (show_stmt ~indent:(indent+2)) stmts)) (String.make indent ' ')

let show_program prog =
  String.concat "\n" (List.map (show_stmt ~indent:0) prog)

