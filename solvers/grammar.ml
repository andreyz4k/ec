open Core
open Utils
open Type
open Program
open FastType

type grammar = {
  logVariable : float;
  library : (program * tp * float * (tContext -> tp -> tContext * tp list) * bool) list;
  continuation_type : tp option;
}

let primitive_grammar ?(continuation_type = None) primitives =
  {
    library =
      List.map primitives ~f:(fun p ->
          match p with
          | Primitive (t, _, _) ->
              (p, t, 0.0 -. log (float_of_int (List.length primitives)), compile_unifier t, false)
          | _ -> raise (Failure "primitive_grammar: not primitive"));
    logVariable = log 0.5;
    continuation_type;
  }

exception DuplicatePrimitive

let uniform_grammar ?(continuation_type = None) primitives =
  if
    List.length primitives
    = List.length
        (List.dedup_and_sort
           ~compare:compare_program (* (fun p1 p2 -> String.compare (string_of_program p1) *)
           (*     (string_of_program p2)) *) (List.map primitives ~f:fst))
  then
    {
      library =
        List.map primitives ~f:(fun (p, r) ->
            match p with
            | Primitive (t, _, _) | Invented (t, _) ->
                (p, t, 0.0 -. log (float_of_int (List.length primitives)), compile_unifier t, r)
            | _ -> raise (Failure "primitive_grammar: not primitive"));
      logVariable = log 0.5;
      continuation_type;
    }
  else raise DuplicatePrimitive

let strip_grammar { logVariable; continuation_type; library } =
  {
    logVariable;
    continuation_type;
    library = library |> List.map ~f:(fun (p, t, l, u, r) -> (strip_primitives p, t, l, u, r));
  }

let grammar_primitives g = g.library |> List.map ~f:(fun (p, _, _, _, _) -> p)
let grammar_primitives_with_rev g = g.library |> List.map ~f:(fun (p, _, _, _, r) -> (p, r))

let string_of_grammar g =
  (match g.continuation_type with
  | None -> ""
  | Some ct -> Printf.sprintf "continuation : %s\n" (string_of_type ct))
  ^ string_of_float g.logVariable ^ "\tt0\t$_\n"
  ^ join ~separator:"\n"
      (g.library
      |> List.map ~f:(fun (p, t, l, _, r) ->
             Float.to_string l ^ "\t" ^ string_of_type t ^ "\t" ^ string_of_program p ^ "\t"
             ^ string_of_bool r))

let grammar_log_weight g p =
  if is_index p then g.logVariable
  else
    match
      g.library
      |> List.filter_map ~f:(fun (p', _, l, _, _) -> if program_equal p p' then Some l else None)
    with
    | [ l ] -> l
    | _ :: _ ->
        raise
          (Failure
             (Printf.sprintf "Grammar contains duplicate primitive %s\n%s\n" (string_of_program p)
                (string_of_grammar g)))
    | [] ->
        raise
          (Failure
             (Printf.sprintf
                "Could not find the following primitive:\n\t%s\n\tinside the DSL:\n%s\n"
                (string_of_program p) (string_of_grammar g)))

let rec is_reversible g p =
  match p with
  | Primitive _ ->
      List.filter_map g.library ~f:(fun (p', _, _, _, r) ->
          if program_equal p p' then Some r else None)
      |> List.hd_exn
  | Invented (_, b) -> is_reversible g b
  | Apply (f, x) -> (
      is_reversible g f
      && match x with Index _ -> true | Abstraction _ | Apply _ -> is_reversible g x | _ -> false)
  | Abstraction b -> is_reversible g b
  | _ -> false

let unifying_expressions ?(reversible_only = false) g environment request context :
    (program * tp list * tContext * float) list =
  (* given a grammar environment requested type and typing context,
     what are all of the possible leaves that we might use?
     These could be productions in the grammar or they could be variables.
     Yields a sequence of:
     (leaf, argument types, context with leaf return type unified with requested type, normalized log likelihood)
  *)
  let variable_candidates =
    environment
    |> List.mapi ~f:(fun j t -> (Index j, t, g.logVariable))
    |> List.filter_map ~f:(fun (p, t, ll) ->
           let context, t = applyContext context t in
           let return = return_of_type t in
           if might_unify return request then
             try
               let context = unify context return request in
               let context, t = applyContext context t in
               Some (p, arguments_of_type t, context, ll)
             with UnificationFailure -> None
           else None)
  in
  let variable_candidates =
    match (variable_candidates, g.continuation_type) with
    | _ :: _, Some t when equal_tp t request ->
        let terminal_indices =
          List.filter_map variable_candidates ~f:(fun (p, t, _, _) ->
              if List.is_empty t then Some (get_index_value p) else None)
        in
        if List.is_empty terminal_indices then variable_candidates
        else
          let smallest_terminal_index = fold1 min terminal_indices in
          variable_candidates
          |> List.filter ~f:(fun (p, t, _, _) ->
                 let okay =
                   (not (is_index p))
                   || (not (List.is_empty t))
                   || get_index_value p = smallest_terminal_index
                 in
                 (* if not okay then *)
                 (*   Printf.eprintf "Pruning imperative index %s with request %s; environment=%s; smallest=%i\n" *)
                 (*     (string_of_program p) *)
                 (*     (string_of_type request) *)
                 (*     (environment |> List.map ~f:string_of_type |> join ~separator:";") *)
                 (*     smallest_terminal_index; *)
                 okay)
    | _ -> variable_candidates
  in
  let nv = List.length variable_candidates |> Float.of_int |> log in
  let variable_candidates =
    variable_candidates |> List.map ~f:(fun (p, t, k, ll) -> (p, t, k, ll -. nv))
  in

  let grammar_candidates =
    g.library
    |> List.filter_map ~f:(fun (p, t, ll, u, r) ->
           try
             if reversible_only && not r then None
             else
               let return_type = return_of_type t in
               if not (might_unify return_type request) then None
               else
                 let context, arguments = u context request in
                 Some (p, arguments, context, ll)
           with UnificationFailure -> None)
  in

  let candidates = variable_candidates @ grammar_candidates in
  let z = List.map ~f:(fun (_, _, _, ll) -> ll) candidates |> lse_list in
  let candidates = List.map ~f:(fun (p, t, k, ll) -> (p, t, k, ll -. z)) candidates in
  candidates

type likelihood_summary = {
  normalizer_frequency : (program list, float) Hashtbl.t;
  use_frequency : (program, float) Hashtbl.t;
  mutable likelihood_constant : float;
}

let show_summary s =
  join ~separator:"\n"
    ([ Printf.sprintf "{likelihood_constant = %f;" s.likelihood_constant ]
    @ (Hashtbl.to_alist s.use_frequency
      |> List.map ~f:(fun (p, f) ->
             Printf.sprintf "use_frequency[%s] = %f;" (string_of_program p) f))
    @ (Hashtbl.to_alist s.normalizer_frequency
      |> List.map ~f:(fun (n, f) ->
             let n = n |> List.map ~f:string_of_program |> join ~separator:"," in
             Printf.sprintf "normalizer_frequency[%s] = %f;" n f))
    @ [ "}" ])

let empty_likelihood_summary () =
  {
    normalizer_frequency = Hashtbl.Poly.create ();
    use_frequency = Hashtbl.Poly.create ();
    likelihood_constant = 0.;
  }

let mix_summaries weighted_summaries =
  let s = empty_likelihood_summary () in
  weighted_summaries
  |> List.iter ~f:(fun (w, s') ->
         Hashtbl.iteri s'.use_frequency ~f:(fun ~key ~data ->
             Hashtbl.update s.use_frequency key ~f:(function
               | None -> data *. w
               | Some k -> k +. (data *. w)));
         Hashtbl.iteri s'.normalizer_frequency ~f:(fun ~key ~data ->
             Hashtbl.update s.normalizer_frequency key ~f:(function
               | None -> data *. w
               | Some k -> k +. (data *. w))));
  s

let record_likelihood_event likelihood_summary actual possibles =
  let constant =
    if is_index actual then
      -.(possibles |> List.filter ~f:is_index |> List.length |> Float.of_int |> log)
    else 0.
  in

  let actual = if is_index actual then Index 0 else actual in
  let variable_possible = possibles |> List.exists ~f:is_index in
  let possibles = possibles |> List.filter ~f:(compose not is_index) in
  let possibles = if variable_possible then Index 0 :: possibles else possibles in
  let possibles = possibles |> List.dedup_and_sort ~compare:compare_program in

  likelihood_summary.likelihood_constant <- likelihood_summary.likelihood_constant +. constant;
  Hashtbl.set likelihood_summary.use_frequency ~key:actual
    ~data:
      (match Hashtbl.find likelihood_summary.use_frequency actual with
      | None -> 1.
      | Some f -> f +. 1.);
  Hashtbl.set likelihood_summary.normalizer_frequency ~key:possibles
    ~data:
      (match Hashtbl.find likelihood_summary.normalizer_frequency possibles with
      | None -> 1.
      | Some f -> f +. 1.)

let summary_likelihood (g : grammar) (s : likelihood_summary) =
  s.likelihood_constant
  +. Hashtbl.fold s.use_frequency ~init:0. ~f:(fun ~key ~data a ->
         a +. (data *. grammar_log_weight g key))
  -. Hashtbl.fold s.normalizer_frequency ~init:0. ~f:(fun ~key ~data a ->
         a +. (data *. (key |> List.map ~f:(grammar_log_weight g) |> lse_list)))

let merge_workspaces context ws1 ws2 =
  Hashtbl.merge ws1 ws2 ~f:(fun ~key:_ -> function
    | `Both (a, b) ->
        let new_context, a = instantiate_type !context a in
        let new_context, b = instantiate_type new_context b in
        let new_context = unify new_context a b in
        context := new_context;
        Some (applyContext new_context a |> snd)
    | `Left a -> Some a
    | `Right b -> Some b)

let make_likelihood_summary g request expression =
  let rec walk_application_tree tree =
    match tree with Apply (f, x) -> walk_application_tree f @ [ x ] | _ -> [ tree ]
  in

  let s = empty_likelihood_summary () in
  let context = ref empty_context in

  let rec summarize ?(reversible_only = false) (r : tp) (environment : tp list)
      (workspace : (string, tp) Hashtbl.t) (p : program) : (string, tp) Hashtbl.t =
    match r with
    (* a function - must start out with a sequence of lambdas *)
    | TNCon ("->", arguments, return_type, _) ->
        let new_workspace =
          merge_workspaces context workspace (Hashtbl.of_alist_exn (module String) arguments)
        in
        let var_requests = summarize ~reversible_only return_type environment new_workspace p in
        var_requests
    | TCon ("->", [ argument; return_type ], _) ->
        let newEnvironment = argument :: environment in
        let body = remove_abstractions 1 p in
        summarize ~reversible_only return_type newEnvironment workspace body
    | _ -> (
        (* not a function - must be an application instead of a lambda *)
        match p with
        | LetClause (name, t, def, body) ->
            let merged_workspace =
              merge_workspaces context workspace
                (Hashtbl.of_alist_exn (module String) [ (name, t) ])
            in
            let var_requests = summarize ~reversible_only r environment merged_workspace body in
            let var_def_requests = summarize ~reversible_only t environment workspace def in
            let out_var_requests = merge_workspaces context var_requests var_def_requests in
            Hashtbl.remove out_var_requests name;
            out_var_requests
        | LetRevClause (_var_names, inp_name, def, body) ->
            let inp_name_request = Hashtbl.find_exn workspace inp_name in
            let var_requests =
              summarize ~reversible_only:true inp_name_request environment workspace def
            in
            let merged_workspace = merge_workspaces context workspace var_requests in
            let var_body_requests =
              summarize ~reversible_only r environment merged_workspace body
            in
            Hashtbl.set var_body_requests ~key:inp_name ~data:inp_name_request;
            var_body_requests
        | FreeVar name -> Hashtbl.of_alist_exn (module String) [ (name, r) ]
        | Const _ -> Hashtbl.create (module String)
        | _ -> (
            let candidates = unifying_expressions ~reversible_only g environment r !context in
            match walk_application_tree p with
            | [] -> raise (Failure "walking the application tree")
            | f :: xs -> (
                match
                  List.find candidates ~f:(fun (candidate, _, _, _) -> program_equal candidate f)
                with
                | None ->
                    s.likelihood_constant <- Float.neg_infinity;
                    Hashtbl.create (module String)
                | Some (_, argument_types, newContext, _functionLikelihood) ->
                    context := newContext;
                    record_likelihood_event s f
                      (candidates |> List.map ~f:(fun (candidate, _, _, _) -> candidate));
                    List.map (List.zip_exn xs argument_types) ~f:(fun (x, x_t) ->
                        summarize ~reversible_only x_t environment workspace x)
                    |> List.fold
                         ~init:(Hashtbl.create (module String))
                         ~f:(merge_workspaces context))))
  in

  ignore (summarize request [] (Hashtbl.create (module String)) expression : (string, tp) Hashtbl.t);
  s

let likelihood_under_grammar g request program =
  make_likelihood_summary g request program |> summary_likelihood g

let grammar_has_recursion a g =
  g.library |> List.exists ~f:(fun (p, _, _, _, _) -> is_recursion_of_arity a p)

(*  *)
type contextual_grammar = {
  no_context : grammar;
  variable_context : grammar;
  contextual_library : (program * grammar list) list;
}

let show_contextual_grammar cg =
  let ls =
    [
      "No context grammar:";
      string_of_grammar cg.no_context;
      "";
      "Variable context grammar:";
      string_of_grammar cg.variable_context;
      "";
    ]
    @ (cg.contextual_library
      |> List.map ~f:(fun (e, gs) ->
             gs
             |> List.mapi ~f:(fun i g ->
                    [
                      Printf.sprintf "Parent %s, argument index %i:" (string_of_program e) i;
                      string_of_grammar g;
                      "";
                    ])
             |> List.concat)
      |> List.concat)
  in
  join ~separator:"\n" ls

let prune_contextual_grammar (g : contextual_grammar) =
  let prune e gs =
    let t = closed_inference e in
    let argument_types = arguments_of_type t in
    List.map2_exn argument_types gs ~f:(fun argument_type g ->
        let argument_type = return_of_type argument_type in
        {
          logVariable = g.logVariable;
          continuation_type = g.continuation_type;
          library =
            g.library
            |> List.filter ~f:(fun (_, child_type, _, _, _) ->
                   let child_type = return_of_type child_type in
                   try
                     let k, child_type = instantiate_type empty_context child_type in
                     let k, argument_type = instantiate_type k argument_type in
                     let (_ : tContext) = unify k child_type argument_type in
                     true
                   with UnificationFailure -> false);
        })
  in
  {
    no_context = g.no_context;
    variable_context = g.variable_context;
    contextual_library = g.contextual_library |> List.map ~f:(fun (e, gs) -> (e, prune e gs));
  }

let make_dummy_contextual g =
  {
    no_context = g;
    variable_context = g;
    contextual_library =
      g.library
      |> List.map ~f:(fun (e, t, _, _, _) -> (e, arguments_of_type t |> List.map ~f:(fun _ -> g)));
  }
  |> prune_contextual_grammar

let deserialize_grammar g =
  let open Yojson.Basic.Util in
  let logVariable = g |> member "logVariable" |> to_number in
  let productions =
    g |> member "productions" |> to_list
    |> List.map ~f:(fun p ->
           let source = p |> member "expression" |> to_string in
           let e =
             match parse_program source with
             | Some ex -> ex
             | None ->
                 let t = p |> member "type" |> to_string |> type_of_string |> get_some in
                 primitive source t unit_reference
           in
           let t =
             try infer_program_type empty_context [] e |> snd
             with UnificationFailure -> raise (Failure ("Could not type " ^ source))
           in
           let logProbability = p |> member "logProbability" |> to_number in
           let r = p |> member "is_reversible" |> to_bool in

           (e, t, logProbability, compile_unifier t, r))
  in
  let continuation_type =
    try Some (g |> member "continuationType" |> deserialize_type) with _ -> None
  in
  (* Successfully parsed the grammar *)
  let g = { continuation_type; logVariable; library = productions } in
  g

let serialize_grammar { logVariable; continuation_type; library } =
  let j : Yojson.Basic.t =
    `Assoc
      ([
         ("logVariable", `Float logVariable);
         ( "productions",
           `List
             (library
             |> List.map ~f:(fun (e, t, l, _, r) ->
                    `Assoc
                      [
                        ("expression", `String (string_of_program e));
                        ("logProbability", `Float l);
                        ("type", `String (string_of_type t));
                        ("is_reversible", `Bool r);
                      ])) );
       ]
      @
      match continuation_type with
      | None -> []
      | Some it -> [ ("continuationType", serialize_type it) ])
  in
  j

let deserialize_contextual_grammar j =
  let open Yojson.Basic.Util in
  {
    no_context = j |> member "noParent" |> deserialize_grammar;
    variable_context = j |> member "variableParent" |> deserialize_grammar;
    contextual_library =
      j |> member "productions" |> to_list
      |> List.map ~f:(fun production ->
             let e = production |> member "program" |> to_string in
             let e =
               try e |> parse_program |> get_some
               with _ ->
                 Printf.eprintf "Could not parse `%s'\n" e;
                 assert false
             in
             let children =
               production |> member "arguments" |> to_list |> List.map ~f:deserialize_grammar
             in
             (e, children));
  }
  |> prune_contextual_grammar

let deserialize_contextual_grammar g =
  try deserialize_grammar g |> make_dummy_contextual with _ -> deserialize_contextual_grammar g
