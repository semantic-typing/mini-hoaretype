type pattern =
  | PVar of string
  | PConstructor of string * pattern option

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
  | Match of expr * (pattern * expr) list
  | Constructor of string * expr option
  | RecFun of string * string list * expr

type program = expr list

type value =
  | VInt of int
  | VFloat of float
  | VString of string
  | VBool of bool
  | VNull
  | VClosure of string list * expr * env ref
  | VRecClosure of string * string list * expr * env ref
  | VConstructor of string * value option
and env = (string * value) list

exception RuntimeError of string

val of_core_pattern : Core_lang.pattern -> pattern
val of_core_expr : Core_lang.expr -> expr
val of_core_program : Core_lang.program -> program
val eval_expr : env -> expr -> value
val eval_program : program -> value list
val string_of_value : value -> string
val show_pattern : pattern -> string
val show_expr : expr -> string
val show_program : program -> string 