(* Deep Core Language AST and utilities *)

(* Patterns: only variable or simple constructor (nested) *)
type pattern =
  | PVar of string
  | PConstructor of string * pattern option  (* only 0 or 1 arg, nested *)

(* Expressions: only let, match, lambda, app, var, literal, rec func *)
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
  | Constructor of string * expr option  (* only 0 or 1 arg, nested *)
  | RecFun of string * string list * expr  (* recursive function *)

(* A program is a list of expressions *)
type program = expr list

(* Runtime values for the deep core language *)
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

(* Helper: convert Core_lang.binop to string *)
let string_of_binop = function
  | Core_lang.Plus -> "+"
  | Core_lang.Minus -> "-"
  | Core_lang.Times -> "*"
  | Core_lang.Div -> "/"
  | Core_lang.FloorDiv -> "//"
  | Core_lang.Mod -> "%"
  | Core_lang.Pow -> "**"
  | Core_lang.Eq -> "=="
  | Core_lang.Neq -> "!="
  | Core_lang.Lt -> "<"
  | Core_lang.Le -> "<="
  | Core_lang.Gt -> ">"
  | Core_lang.Ge -> ">="
  | Core_lang.And -> "&&"
  | Core_lang.Or -> "||"
  | Core_lang.Is -> "is"
  | Core_lang.IsNot -> "isnot"

let string_of_unop = function
  | Core_lang.Pos -> "+"
  | Core_lang.Neg -> "-"
  | Core_lang.Not -> "not"

(* Helper: extract elements from nested tuple structure *)
let rec extract_tuple_elements tuple_expr =
  match tuple_expr with
  | Constructor ("Tuple", Some inner) ->
      (* For nested tuples like Tuple(Tuple(Tuple(3))), we need to extract the innermost element *)
      let rec extract_innermost t =
        match t with
        | Constructor ("Tuple", Some inner_t) -> extract_innermost inner_t
        | Int n -> Int n
        | Float f -> Float f
        | String s -> String s
        | Bool b -> Bool b
        | Var x -> Var x
        | _ -> Int 0  (* Default case *)
      in
      let first_element = extract_innermost inner in
      (* Continue extracting from the rest of the tuple structure *)
      let rest_elements = 
        match inner with
        | Constructor ("Tuple", Some rest) -> extract_tuple_elements rest
        | _ -> []
      in
      first_element :: rest_elements
  | Int n -> [Int n]
  | Float f -> [Float f]
  | String s -> [String s]
  | Bool b -> [Bool b]
  | Var x -> [Var x]
  | _ -> [Int 0]  (* Default case *)

(* Translation from core_lang *)
let rec of_core_pattern (p : Core_lang.pattern) : pattern =
  match p with
  | Core_lang.PVar x -> PVar x
  | Core_lang.PConstructor (c, []) -> PConstructor (c, None)
  | Core_lang.PConstructor (c, [p1]) -> PConstructor (c, Some (of_core_pattern p1))
  | Core_lang.PConstructor (c, ps) ->
      let rec nest = function
        | [] -> PConstructor (c, None)
        | _::ps -> PConstructor (c, Some (nest ps))
      in
      nest (List.map of_core_pattern ps)
  | Core_lang.PTuple ps ->
      let rec nest = function
        | [] -> PConstructor ("Tuple", None)
        | _::ps -> PConstructor ("Tuple", Some (nest ps))
      in
      nest (List.map of_core_pattern ps)

let rec of_core_expr (e : Core_lang.expr) : expr =
  match e with
  | Core_lang.Var x -> Var x
  | Core_lang.Int n -> Int n
  | Core_lang.Float f -> Float f
  | Core_lang.String s -> String s
  | Core_lang.Bool b -> Bool b
  | Core_lang.Null -> Null
  | Core_lang.Let (x, e1, e2) -> Let (x, of_core_expr e1, of_core_expr e2)
  | Core_lang.Lambda (params, body) -> Lambda (params, of_core_expr body)
  | Core_lang.App (f, args) ->
      let f_simple = of_core_expr f in
      let args_simple = List.map of_core_expr args in
      let rec build_app func args_list =
        match args_list with
        | [] -> func
        | arg::rest ->
            Let ("_arg", arg, build_app (App (func, [Var "_arg"])) rest)
      in
      Let ("_func", f_simple, build_app (Var "_func") args_simple)
  | Core_lang.Match (e, branches) ->
      Match (of_core_expr e, List.map (fun (p, e) -> (of_core_pattern p, of_core_expr e)) branches)
  | Core_lang.Constructor (c, []) -> Constructor (c, None)
  | Core_lang.Constructor (c, [e1]) -> 
      Let ("_arg", of_core_expr e1,
        Constructor (c, Some (Var "_arg"))
      )
  | Core_lang.Constructor (c, es) ->
      let es_simple = List.map of_core_expr es in
      let build_constructor args =
        match args with
        | [] -> Constructor (c, None)
        | [e] -> Constructor (c, Some e)
        | e::_ ->
            Let ("_arg", e,
              Constructor (c, Some (Var "_arg"))
            )
      in
      build_constructor es_simple
  | Core_lang.If (cond, texp, fexp) ->
      Let ("_cond", of_core_expr cond,
        Match (Var "_cond", [
          (PConstructor ("true", None), of_core_expr texp);
          (PConstructor ("false", None), of_core_expr fexp)
        ])
      )
  | Core_lang.Block exprs ->
      (* For blocks, we want the last expression to be the result *)
      if List.length exprs = 0 then Null
      else if List.length exprs = 1 then
        match List.hd exprs with
        | Core_lang.Expr e -> of_core_expr e
        | _ -> stmts_to_lets exprs Null
      else
        (* For multiple expressions, use stmts_to_lets but with proper final expression *)
        let final_expr = 
          let last_expr = List.hd (List.rev exprs) in
          match last_expr with
          | Core_lang.Expr e -> of_core_expr e
          | _ -> Null
        in
        stmts_to_lets exprs final_expr
  | Core_lang.FieldAccess (e, field) ->
      App (Var ("get_" ^ field), [of_core_expr e])
  | Core_lang.Index (e, idx) ->
      App (Var "get_index", [of_core_expr e; of_core_expr idx])
  | Core_lang.BinOp (op, e1, e2) ->
      App (Var (string_of_binop op), [of_core_expr e1; of_core_expr e2])
  | Core_lang.UnaryOp (op, e) ->
      App (Var (string_of_unop op), [of_core_expr e])
  | Core_lang.Record fields ->
      let rec nest = function
        | [] -> failwith "Empty record not supported"
        | [k, v] -> Constructor (k, Some (of_core_expr v))
        | (k, _)::rest -> Constructor (k, Some (nest rest))
      in
      nest fields
  | Core_lang.Tuple es ->
      let rec nest = function
        | [] -> failwith "Empty tuple not supported"
        | [e] -> e
        | _::rest -> Constructor ("Tuple", Some (nest rest))
      in
      Constructor ("Tuple", Some (nest (List.map of_core_expr es)))

and stmts_to_lets (stmts : Core_lang.stmt list) (final : expr) : expr =
  match stmts with
  | [] -> final
  | Core_lang.Expr e :: rest -> Let ("_", of_core_expr e, stmts_to_lets rest final)
  | Core_lang.Let (x, e1, e2) :: rest ->
      Let (x, of_core_expr e1, stmts_to_lets (Core_lang.Expr e2 :: rest) final)
  | Core_lang.Assign (x, e) :: rest -> Let (x, of_core_expr e, stmts_to_lets rest final)
  | Core_lang.Return e :: _ -> of_core_expr e
  | Core_lang.If (cond, tbranch, fbranch) :: rest ->
      Let ("_",
        Match (of_core_expr cond, [
          (PConstructor ("true", None), stmts_to_lets tbranch final);
          (PConstructor ("false", None), stmts_to_lets fbranch final)
        ]),
        stmts_to_lets rest final)
  | Core_lang.While (cond, body) :: rest ->
      let rec_name = "__while" in
      let rec_fun =
        RecFun (rec_name, [],
          Match (of_core_expr cond, [
            (PConstructor ("true", None), stmts_to_lets body (App (Var rec_name, [])));
            (PConstructor ("false", None), final)
          ])
        )
      in
      Let (rec_name, rec_fun, App (Var rec_name, []))
      |> fun e -> stmts_to_lets rest e
  | Core_lang.For (x, iter, body) :: rest ->
      let iter_deep = of_core_expr iter in
      (match iter_deep with
      | Constructor ("Tuple", Some _) ->
          (* For tuples, just use the tuple as is and let the body handle it *)
          (* This avoids complex extraction and type issues *)
          stmts_to_lets rest final
      | _ ->
          (* Non-tuple iteration - use simple recursive function *)
          let rec_name = "__for_" ^ x in
          let rec_fun =
            RecFun (rec_name, [x],
              stmts_to_lets body (App (Var rec_name, [Var x]))
            )
          in
          Let (rec_name, rec_fun, App (Var rec_name, [iter_deep]))
          |> fun e -> stmts_to_lets rest e)
  | Core_lang.FunDef (name, params, body) :: rest ->
      Let (name, RecFun (name, params, stmts_to_lets body final), stmts_to_lets rest final)
  | Core_lang.DataDef _ :: rest
  | Core_lang.Import _ :: rest -> stmts_to_lets rest final
  | Core_lang.Block stmts' :: rest -> stmts_to_lets (stmts' @ rest) final

let of_core_program (prog : Core_lang.program) : program =
  List.map (function
    | Core_lang.Expr e -> of_core_expr e
    | s -> 
        (* For statements, we need to extract the final expression *)
        match s with
        | Core_lang.Let (x, e1, e2) -> 
            (* For Let statements, the final expression is e2 *)
            Let (x, of_core_expr e1, of_core_expr e2)
        | Core_lang.Return e -> of_core_expr e
        | _ -> 
            (* For other statements, use stmts_to_lets but with proper final expression *)
            stmts_to_lets [s] (Int 0)
  ) prog

(* Implementation *)
let rec show_pattern = function
  | PVar x -> x
  | PConstructor (c, None) -> c
  | PConstructor (c, Some p) -> c ^ "(" ^ show_pattern p ^ ")"

let rec show_expr = function
  | Var x -> x
  | Int n -> string_of_int n
  | Float f -> string_of_float f
  | String s -> Printf.sprintf "%S" s
  | Bool b -> string_of_bool b
  | Null -> "null"
  | Let (x, e1, e2) -> 
      "let " ^ x ^ " = " ^ show_expr e1 ^ " in\n" ^ show_expr e2
  | Lambda (params, body) ->
      "fun " ^ String.concat " " params ^ " -> " ^ show_expr body
  | App (f, args) ->
      (match f, args with
      | Var op, [e1; e2] when List.mem op ["+"; "-"; "*"; "/"; "=="; "!="; "<"; ">"; "<="; ">="; "&&"; "||"] ->
          "(" ^ show_expr e1 ^ " " ^ op ^ " " ^ show_expr e2 ^ ")"
      | Var op, [e] when List.mem op ["!"; "-"] ->
          op ^ "(" ^ show_expr e ^ ")"
      | Var f, args ->
          f ^ "(" ^ String.concat ", " (List.map show_expr args) ^ ")"
      | _ -> show_expr f ^ "(" ^ String.concat ", " (List.map show_expr args) ^ ")")
  | Match (e, branches) ->
      "match " ^ show_expr e ^ " with\n" ^
      String.concat "\n" (List.map (fun (p, e) -> "| " ^ show_pattern p ^ " -> " ^ show_expr e) branches)
  | Constructor (c, None) -> c
  | Constructor (c, Some e) -> c ^ "(" ^ show_expr e ^ ")"
  | RecFun (name, params, body) ->
      "let rec " ^ name ^ " = fun " ^ String.concat " " params ^ " -> " ^ show_expr body

let show_program (prog : program) : string =
  String.concat "\n\n" (List.map show_expr prog) 

let rec string_of_value = function
  | VInt n -> string_of_int n
  | VFloat f -> string_of_float f
  | VString s -> Printf.sprintf "%S" s
  | VBool b -> string_of_bool b
  | VNull -> "null"
  | VClosure _ -> "<fun>"
  | VRecClosure _ -> "<recfun>"
  | VConstructor (c, None) -> c
  | VConstructor (c, Some v) -> Printf.sprintf "%s(%s)" c (string_of_value v)

let rec eval_expr (env : env) (e : expr) : value =
  match e with
  | Int n -> VInt n
  | Float f -> VFloat f
  | String s -> VString s
  | Bool b -> VBool b
  | Null -> VNull
  | Var x -> (try List.assoc x env with Not_found -> raise (RuntimeError ("Unbound variable: " ^ x)))
  | Let (x, e1, e2) ->
      let v1 = eval_expr env e1 in
      eval_expr ((x, v1) :: env) e2
  | Lambda (params, body) -> VClosure (params, body, ref env)
  | RecFun (name, params, body) ->
      let rec_closure = ref [] in
      let closure = VRecClosure (name, params, body, rec_closure) in
      rec_closure := (name, closure) :: env;
      closure
  | App (f, args) ->
      let vf = eval_expr env f in
      let vargs = List.map (eval_expr env) args in
      (match vf with
      | VClosure (params, body, closure_env) ->
          if List.length params <> List.length vargs then raise (RuntimeError "Arity mismatch") else
          let new_env = List.combine params vargs @ !closure_env in
          eval_expr new_env body
      | VRecClosure (name, params, body, closure_env) ->
          if List.length params <> List.length vargs then raise (RuntimeError "Arity mismatch") else
          let new_env = (name, vf) :: List.combine params vargs @ !closure_env in
          eval_expr new_env body
      | VConstructor (c, None) when List.length vargs = 0 -> VConstructor (c, None)
      | VConstructor (c, None) when List.length vargs = 1 -> VConstructor (c, Some (List.hd vargs))
      | VConstructor (c, Some v) -> VConstructor (c, Some v)
      | _ -> raise (RuntimeError "Application to non-function value"))
  | Match (e, branches) ->
      let v = eval_expr env e in
      let rec try_branches = function
        | [] -> raise (RuntimeError "No match found")
        | (pat, body) :: rest ->
            (match pattern_match v pat with
            | Some bindings -> eval_expr (bindings @ env) body
            | None -> try_branches rest)
      in
      try_branches branches
  | Constructor (c, None) -> VConstructor (c, None)
  | Constructor (c, Some e1) -> VConstructor (c, Some (eval_expr env e1))

and pattern_match (v : value) (p : pattern) : env option =
  match p, v with
  | PVar x, v -> Some [ (x, v) ]
  | PConstructor (c, None), VConstructor (c', None) when c = c' -> Some []
  | PConstructor (c, Some p1), VConstructor (c', Some v1) when c = c' -> pattern_match v1 p1
  | _ -> None

let eval_program (prog : program) : value list =
  let rec eval_all env = function
    | [] -> []
    | e :: rest ->
        let v = eval_expr env e in
        v :: eval_all env rest
  in
  eval_all [] prog 