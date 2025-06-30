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

(* Core language expressions *)
type expr =
  | Var of string                    (* Variable *)
  | Int of int                       (* Integer literal *)
  | Float of float                   (* Float literal *)
  | String of string                 (* String literal *)
  | Constructor of string * expr list (* Constructor application *)
  | App of expr * expr list          (* Function application *)
  | Let of string * expr * expr      (* Let binding: let x = e1 in e2 *)
  | Lambda of string list * expr     (* Lambda abstraction *)
  | Match of expr * (pattern * expr) list (* Pattern matching *)
  | BinOp of binop * expr * expr     (* Binary operation *)
  | UnaryOp of unop * expr           (* Unary operation *)
  | FieldAccess of expr * string     (* Field access: e.field *)
  | Index of expr * expr             (* Index access: e[i] *)
  | Tuple of expr list               (* Tuple construction *)

(* Patterns for pattern matching *)
and pattern =
  | PVar of string                   (* Variable pattern *)
  | PConstructor of string * pattern list (* Constructor pattern *)

(* Core language statements *)
type stmt =
  | Expr of expr                     (* Expression statement *)
  | Let of string * expr * expr      (* Let binding *)
  | Return of expr                   (* Return statement *)
  | If of expr * stmt list * stmt list (* If statement: if e then s1 else s2 *)
  | While of expr * stmt list        (* While loop *)
  | For of string * expr * stmt list (* For loop *)
  | FunDef of string * string list * stmt list (* Function definition *)
  | ClassDef of string * stmt list   (* Class definition *)
  | Import of string                 (* Import statement *)
  | ImportFrom of string * string    (* From import statement *)

(* Core language program *)
type program = stmt list

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

(* Pretty printer for expressions *)
let rec pp_expr = function
  | Var x -> x
  | Int n -> string_of_int n
  | Float f -> string_of_float f
  | String s -> "\"" ^ s ^ "\""
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
  | FieldAccess (e, field) -> pp_expr e ^ "." ^ field
  | Index (e, i) -> pp_expr e ^ "[" ^ pp_expr i ^ "]"
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
  | Not -> "not "

(* Pretty printer for statements *)
let rec pp_stmt = function
  | Expr e -> pp_expr e
  | Let (x, e1, e2) -> "let " ^ x ^ " = " ^ pp_expr e1 ^ " in " ^ pp_stmt e2
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
  | ClassDef (name, body) ->
      "class " ^ name ^ ":\n" ^
      String.concat "\n" (List.map (fun s -> "  " ^ pp_stmt s) body)
  | Import module_name -> "import " ^ module_name
  | ImportFrom (module_name, item) -> "from " ^ module_name ^ " import " ^ item

(* Pretty printer for programs *)
let pp_program program =
  String.concat "\n" (List.map pp_stmt program)

(* Pretty printer for types *)
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