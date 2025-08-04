(* Type Inference Interface *)

(* Type system for deep-core language *)
type ty =
  | TInt
  | TFloat  
  | TString
  | TBool
  | TUnit
  | TFun of ty * ty
  | TTuple of ty list
  | TConstructor of string * ty option
  | TVar of string

(* Type environment *)
type ty_env = (string * ty) list

(* Type substitution *)
type substitution = (string * ty) list

(* Hoare triple: {P} C {Q} *)
type hoare_triple = {
  pre: ty_env;
  command: Deep_core_lang.expr;
  post: ty_env
}

(* Main type inference function *)
val type_infer_program : Deep_core_lang.program -> ty list * substitution

(* Pretty print type inference result *)
val show_type_inference_result : ty list * substitution -> string

(* Type pretty printing *)
val show_type : ty -> string 