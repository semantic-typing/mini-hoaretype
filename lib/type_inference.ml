(* Type Inference using Hoare Logic with Forward Verification *)

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
  | TVar of string  (* type variable for inference *)

(* Type environment *)
type ty_env = (string * ty) list

(* Type substitution *)
type substitution = (string * ty) list

(* Hoare triple: {P} C {Q} *)
type hoare_triple = {
  pre: ty_env;      (* precondition: type environment *)
  command: Deep_core_lang.expr;  (* command/expression *)
  post: ty_env      (* postcondition: type environment *)
}

(* Type inference state *)
type inference_state = {
  env: ty_env;
  constraints: (ty * ty) list;  (* type equality constraints *)
  fresh_var_counter: int
}

(* Fresh type variable generator *)
let fresh_var state =
  let var = "alpha" ^ string_of_int state.fresh_var_counter in
  (TVar var, {state with fresh_var_counter = state.fresh_var_counter + 1})

(* Type pretty printing *)
let rec show_type = function
  | TInt -> "int"
  | TFloat -> "float"
  | TString -> "string"
  | TBool -> "bool"
  | TUnit -> "unit"
  | TFun (t1, t2) -> "(" ^ show_type t1 ^ " -> " ^ show_type t2 ^ ")"
  | TTuple ts -> "(" ^ String.concat " * " (List.map show_type ts) ^ ")"
  | TConstructor (c, None) -> c
  | TConstructor (c, Some t) -> c ^ "(" ^ show_type t ^ ")"
  | TVar x -> x

(* Apply substitution to type *)
let rec apply_subst subst = function
  | TInt -> TInt
  | TFloat -> TFloat
  | TString -> TString
  | TBool -> TBool
  | TUnit -> TUnit
  | TFun (t1, t2) -> TFun (apply_subst subst t1, apply_subst subst t2)
  | TTuple ts -> TTuple (List.map (apply_subst subst) ts)
  | TConstructor (c, t_opt) -> TConstructor (c, Option.map (apply_subst subst) t_opt)
  | TVar x as t ->
      (try List.assoc x subst with Not_found -> t)

(* Apply substitution to environment *)
let apply_subst_env subst env =
  List.map (fun (x, t) -> (x, apply_subst subst t)) env

(* Unification algorithm *)
let rec unify t1 t2 =
  match t1, t2 with
  | TVar x, TVar y when x = y -> []
  | TVar x, t | t, TVar x -> [(x, t)]
  | TInt, TInt | TFloat, TFloat | TString, TString | TBool, TBool | TUnit, TUnit -> []
  | TFun (t1, t2), TFun (t1', t2') ->
      let s1 = unify t1 t1' in
      let s2 = unify (apply_subst s1 t2) (apply_subst s1 t2') in
      s1 @ s2
  | TTuple ts1, TTuple ts2 when List.length ts1 = List.length ts2 ->
      List.fold_left2 (fun acc t1 t2 -> acc @ unify t1 t2) [] ts1 ts2
  | TConstructor (c1, t1_opt), TConstructor (c2, t2_opt) when c1 = c2 ->
      (match t1_opt, t2_opt with
      | None, None -> []
      | Some t1, Some t2 -> unify t1 t2
      | _ -> failwith "Constructor type mismatch")
  | _ -> failwith ("Cannot unify types: " ^ show_type t1 ^ " and " ^ show_type t2)

(* Forward verification: infer types using Hoare logic *)
let rec type_infer_expr state expr =
  match expr with
  | Deep_core_lang.Var x ->
      let (t, new_state) = try 
        let t = List.assoc x state.env in
        (t, state)
      with Not_found -> 
        let (t, new_state) = fresh_var state in
        (t, {new_state with env = (x, t) :: new_state.env})
      in
      (t, new_state)
      
  | Deep_core_lang.Int _ -> (TInt, state)
  | Deep_core_lang.Float _ -> (TFloat, state)
  | Deep_core_lang.String _ -> (TString, state)
  | Deep_core_lang.Bool _ -> (TBool, state)
  | Deep_core_lang.Null -> (TUnit, state)
  
  | Deep_core_lang.Let (x, e1, e2) ->
      (* Forward verification: {P} let x = e1 in e2 {Q} *)
      let (t1, state1) = type_infer_expr state e1 in
      let state2 = {state1 with env = (x, t1) :: state1.env} in
      let (t2, state3) = type_infer_expr state2 e2 in
      (t2, state3)
      
  | Deep_core_lang.Lambda (params, body) ->
      (* Generate fresh types for parameters *)
      let rec add_params state = function
        | [] -> state
        | p :: ps ->
            let (t, new_state) = fresh_var state in
            add_params {new_state with env = (p, t) :: new_state.env} ps
      in
      let state_with_params = add_params state params in
      let (body_type, final_state) = type_infer_expr state_with_params body in
      
      (* Build function type *)
      let rec build_fun_type = function
        | [] -> body_type
        | t :: ts -> TFun (t, build_fun_type ts)
      in
      let param_types = List.map (fun p -> List.assoc p final_state.env) params in
      let fun_type = build_fun_type param_types in
      (fun_type, final_state)
      
  | Deep_core_lang.App (f, args) ->
      (* Forward verification: {P} f(args) {Q} *)
      let (f_type, state1) = type_infer_expr state f in
      let (arg_types, state2) = type_infer_args state1 args in
      
      (* For binary operators, expect specific types *)
      (match f, args with
      | Deep_core_lang.Var op, [e1; e2] when List.mem op ["+"; "-"; "*"; "/"; "=="; "!="; "<"; ">"; "<="; ">="; "&&"; "||"] ->
          (* Binary operators: expect int -> int -> int or similar *)
          let (t1, state3) = type_infer_expr state2 e1 in
          let (t2, state4) = type_infer_expr state3 e2 in
          let substitution = unify t1 t2 in
          let result_type = apply_subst substitution t1 in
          (result_type, {state4 with env = apply_subst_env substitution state4.env})
      | Deep_core_lang.Var op, [e] when List.mem op ["!"; "-"] ->
          (* Unary operators *)
          let (t, state3) = type_infer_expr state2 e in
          (t, state3)
      | Deep_core_lang.Var func_name, [index] when String.length func_name > 12 && String.sub func_name 0 12 = "__tuple_iter_" ->
          (* Tuple iterator function - expect index and return tuple element type *)
          let (_, state3) = type_infer_expr state2 index in
          (* For now, assume tuple elements are int *)
          (TInt, state3)
      | _ ->
          (* General function application *)
          let (result_type, state3) = fresh_var state2 in
          let expected_fun_type = List.fold_right (fun arg_type acc -> TFun (arg_type, acc)) arg_types result_type in
          let substitution = unify f_type expected_fun_type in
          let final_result_type = apply_subst substitution result_type in
          (final_result_type, {state3 with env = apply_subst_env substitution state3.env}))
      
  | Deep_core_lang.Match (e, branches) ->
      (* Forward verification: {P} match e with branches {Q} *)
      let (e_type, state1) = type_infer_expr state e in
      let (branch_types, state2) = type_infer_branches state1 e_type branches in
      
      (* All branches must have same type *)
      let rec unify_branches = function
        | [] -> []
        | [_] -> []
        | t1 :: t2 :: rest ->
            let s = unify t1 t2 in
            s @ unify_branches (apply_subst s t2 :: rest)
      in
      
      let substitution = unify_branches branch_types in
      let result_type = apply_subst substitution (List.hd branch_types) in
      (result_type, {state2 with constraints = state2.constraints @ List.map (fun (t1, t2) -> (apply_subst substitution t1, apply_subst substitution t2)) state2.constraints})
      
  | Deep_core_lang.Constructor (c, None) ->
      (TConstructor (c, None), state)
      
  | Deep_core_lang.Constructor (c, Some e) ->
      let (e_type, state1) = type_infer_expr state e in
      (TConstructor (c, Some e_type), state1)
      
  | Deep_core_lang.RecFun (name, params, body) ->
      (* Recursive function: create circular reference *)
      let (fun_type, state1) = fresh_var state in
      let state2 = {state1 with env = (name, fun_type) :: state1.env} in
      
      (* Add parameters to environment *)
      let rec add_params state = function
        | [] -> state
        | p :: ps ->
            let (t, new_state) = fresh_var state in
            add_params {new_state with env = (p, t) :: new_state.env} ps
      in
      let state3 = add_params state2 params in
      let (body_type, state4) = type_infer_expr state3 body in
      
      (* Build function type and unify with recursive reference *)
      let param_types = List.map (fun p -> List.assoc p state4.env) params in
      let expected_fun_type = List.fold_right (fun t acc -> TFun (t, acc)) param_types body_type in
      let substitution = unify fun_type expected_fun_type in
      
      (apply_subst substitution fun_type, {state4 with constraints = state4.constraints @ List.map (fun (t1, t2) -> (apply_subst substitution t1, apply_subst substitution t2)) state4.constraints})

(* Helper functions *)
and type_infer_args state = function
  | [] -> ([], state)
  | arg :: args ->
      let (arg_type, state1) = type_infer_expr state arg in
      let (rest_types, state2) = type_infer_args state1 args in
      (arg_type :: rest_types, state2)

and type_infer_branches state scrutinee_type = function
  | [] -> ([], state)
  | (_, expr) :: branches ->
      let (expr_type, state1) = type_infer_expr state expr in
      let (rest_types, state2) = type_infer_branches state1 scrutinee_type branches in
      (expr_type :: rest_types, state2)

(* Main type inference function *)
let type_infer_program prog =
  let initial_state = {
    env = [];
    constraints = [];
    fresh_var_counter = 0
  } in
  
  let rec infer_all state = function
    | [] -> ([], state)
    | expr :: rest ->
        let (expr_type, state1) = type_infer_expr state expr in
        let (rest_types, state2) = infer_all state1 rest in
        (expr_type :: rest_types, state2)
  in
  
  let (types, final_state) = infer_all initial_state prog in
  
  (* Solve constraints *)
  let rec solve_constraints constraints =
    match constraints with
    | [] -> []
    | (t1, t2) :: rest ->
        let s = unify t1 t2 in
        s @ solve_constraints (List.map (fun (t1', t2') -> (apply_subst s t1', apply_subst s t2')) rest)
  in
  
  let substitution = solve_constraints final_state.constraints in
  let final_types = List.map (apply_subst substitution) types in
  
  (* Try to resolve any remaining type variables to concrete types *)
  let resolved_types = List.map (fun t ->
    match t with
    | TVar x -> 
        (* If it's still a type variable, try to infer from context *)
        (match x with
        | "result" -> TInt  (* Default to int for result *)
        | _ -> t)
    | _ -> t
  ) final_types in
  
  (resolved_types, substitution)

(* Pretty print type inference result *)
let show_type_inference_result (types, substitution) =
  "Type Inference Result:\n" ^
  "Types: " ^ String.concat ", " (List.map show_type types) ^ "\n" ^
  "Substitution: " ^ String.concat ", " (List.map (fun (x, t) -> x ^ " -> " ^ show_type t) substitution) 