(* Core Language AST definitions *)

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

(* Type annotations for expressions *)
type typed_expr = expr * typ option

(* Environment for type inference *)
type env = (string * typ) list

(* Type substitution *)
type substitution = (string * typ) list

(* Error types *)
type error =
  | TypeError of string
  | ParseError of string
  | UnificationError of string

(* Result type for operations that can fail *)
type 'a result = Ok of 'a | Error of error 