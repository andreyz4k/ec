open Core
open Parser

type tp =
  | TID of int
  | TCon of string * tp list * bool
  | TNCon of string * (string * tp) list * tp * bool
[@@deriving equal, show]

let is_polymorphic = function TID _ -> true | TCon (_, _, p) -> p | TNCon (_, _, _, p) -> p

let rec tp_eq a b =
  match (a, b) with
  | TID x, TID y -> x = y
  | TCon (k1, as1, _), TCon (k2, as2, _) -> String.( = ) k1 k2 && type_arguments_equal as1 as2
  | TNCon (k1, as1, o1, _), TNCon (k2, as2, o2, _) ->
      String.( = ) k1 k2 && type_named_arguments_equal as1 as2 && tp_eq o1 o2
  | _ -> false

and type_arguments_equal xs ys =
  match (xs, ys) with
  | a :: b, c :: d -> tp_eq a c && type_arguments_equal b d
  | [], [] -> true
  | _ -> false

and type_named_arguments_equal xs ys =
  match (xs, ys) with
  | (v1, t1) :: tail1, (v2, t2) :: tail2 ->
      String.( = ) v1 v2 && tp_eq t1 t2 && type_named_arguments_equal tail1 tail2
  | [], [] -> true
  | _ -> false

let kind n ts = TCon (n, ts, ts |> List.exists ~f:is_polymorphic)

let nkind n ts o =
  TNCon (n, ts, o, ts |> List.exists ~f:(fun (_, t) -> is_polymorphic t) || is_polymorphic o)

(* A context has a size (fst) as well as an array mapping indices to types (snd; the substitution)
   The substitution is stored in reverse order
*)
type tContext = int * tp option Funarray.funarray

let empty_context : tContext = (0, Funarray.empty)
let make_arrow t q = kind "->" [ t; q ]
let ( @> ) = make_arrow
let is_arrow = function TCon ("->", _, _) -> true | TNCon ("->", _, _, _) -> true | _ -> false

(* arguments_and_return_up_type (t1 @> t2 @> ... @> T) = ([t1;t2;...] T) *)
let rec arguments_and_return_of_type t =
  match t with
  | TCon ("->", [ p; q ], _) ->
      let arguments, return = arguments_and_return_of_type q in
      (p :: arguments, return)
  | TNCon ("->", _, _, _) -> raise (Failure "Not implemented")
  | _ -> ([], t)

(* return_of_type (t1 @> t2 @> ... @> T) = T *)
let rec return_of_type t =
  match t with
  | TCon ("->", [ _; q ], _) -> return_of_type q
  | TNCon ("->", _, q, _) -> return_of_type q
  | _ -> t

(* arguments_of_type (t1 @> t2 @> ... @> T) = [t1;t2;...] *)
let rec arguments_of_type t =
  match t with
  | TCon ("->", [ p; q ], _) -> p :: arguments_of_type q
  | TNCon ("->", _, _, _) -> raise (Failure "Not implemented")
  | _ -> []

let right_of_arrow t =
  match t with
  | TCon ("->", [ _; p ], _) -> p
  | TNCon ("->", _, p, _) -> p
  | _ -> raise (Failure "right_of_arrow")

let left_of_arrow t =
  match t with
  | TCon ("->", [ p; _ ], _) -> p
  | TNCon ("->", _, _, _) -> raise (Failure "Not implemented")
  | _ -> raise (Failure "left_of_arrow")

let rec show_type (is_return : bool) (t : tp) : string =
  let open String in
  match t with
  | TID i -> "t" ^ string_of_int i
  | TCon (k, [], _) -> k
  | TCon (k, [ p; q ], _) when k = "->" ->
      if is_return then show_type false p ^ " -> " ^ show_type true q
      else "(" ^ show_type false p ^ " -> " ^ show_type true q ^ ")"
  | TCon (k, a, _) -> k ^ "(" ^ String.concat ~sep:", " (List.map a ~f:(show_type true)) ^ ")"
  | TNCon (k, args, o, _) when k = "->" ->
      let args_str =
        String.concat ~sep:" -> " (List.map args ~f:(fun (v, t) -> v ^ ":" ^ (show_type false) t))
      in
      if is_return then args_str ^ " -> " ^ show_type true o
      else "(" ^ args_str ^ " -> " ^ show_type true o ^ ")"
  | TNCon (k, [], o, _) -> k ^ "(" ^ show_type true o ^ ")"
  | TNCon (k, args, o, _) ->
      let args_str =
        String.concat ~sep:", " (List.map args ~f:(fun (v, t) -> v ^ ":" ^ (show_type false) t))
      in
      k ^ "(" ^ args_str ^ ", " ^ show_type true o ^ ")"

let string_of_type = show_type true
let makeTID (next, substitution) = (TID next, (next + 1, Funarray.cons None substitution))

let rec makeTIDs (n : int) (k : tContext) : tContext =
  if n = 0 then k else makeTIDs (n - 1) (makeTID k |> snd)

let bindTID i t (next, bindings) : tContext =
  (next, Funarray.update bindings (next - i - 1) (Some t))

let lookupTID (next, bindings) j =
  assert (j < next);
  Funarray.lookup bindings (next - j - 1)

(* let rec chaseType (context : tContext) (t : tp) : tp*tContext =  *)
(*   match t with *)
(*   | TCon(s, ts) -> *)
(*     let (ts_, context_) = *)
(*       List.fold_right ts  *)
(* 	~f:(fun t (tz, k) -> *)
(* 	    let (t_, k_) = chaseType k t in *)
(* 	    (t_ :: tz, k_)) ~init:([], context) *)
(*     in (TCon(s, ts_), context_) *)
(*   | TID(i) ->  *)
(*     match TypeMap.find (snd context) i with *)
(*     | Some(hit) ->  *)
(*       let (t_, context_) = chaseType context hit in *)
(*       let substitution = TypeMap.add (snd context_) i t_ in *)
(*       (t_, (fst context_, substitution)) *)
(*     | None -> (t,context) *)

let rec applyContext k t =
  if not (is_polymorphic t) then (k, t)
  else
    match t with
    | TCon (c, xs, _) ->
        let k, xs =
          List.fold_right xs ~init:(k, []) ~f:(fun x (k, xs) ->
              let k, x = applyContext k x in
              (k, x :: xs))
        in
        (k, kind c xs)
    | TNCon (c, xs, o, _) ->
        let k, nxs =
          List.fold_right xs ~init:(k, []) ~f:(fun (v, x) (k, xs) ->
              let k, x = applyContext k x in
              (k, (v, x) :: xs))
        in
        let k, no = applyContext k o in
        (k, nkind c nxs no)
    | TID j -> (
        match lookupTID k j with
        | None -> (k, t)
        | Some tp ->
            let k, tp' = applyContext k tp in
            let k = if tp_eq tp tp' then k else bindTID j tp' k in
            (k, tp'))

let rec occurs (i : int) (t : tp) : bool =
  if not (is_polymorphic t) then false
  else
    match t with
    | TID j -> j = i
    | TCon (_, ts, _) -> List.exists ts ~f:(occurs i)
    | TNCon (_, xs, o, _) -> occurs i o || List.exists xs ~f:(fun (_, x) -> (occurs i) x)

let occursCheck = true

exception UnificationFailure

let rec might_unify t1 t2 =
  let open String in
  match (t1, t2) with
  | TCon (k1, as1, _), TCon (k2, as2, _) when k1 = k2 -> List.for_all2_exn as1 as2 ~f:might_unify
  | TNCon (k1, as1, o1, _), TNCon (k2, as2, o2, _) when k1 = k2 ->
      List.for_all2_exn as1 as2 ~f:(fun (v1, t1) (v2, t2) -> v1 = v2 && might_unify t1 t2)
      && might_unify o1 o2
  | TID _, _ -> true
  | _, TID _ -> true
  | _ -> false

let rec unify context t1 t2 : tContext =
  let context, t1 = applyContext context t1 in
  let context, t2 = applyContext context t2 in
  if (not (is_polymorphic t1)) && not (is_polymorphic t2) then
    if tp_eq t1 t2 then context else raise UnificationFailure
  else
    match (t1, t2) with
    | TID j, t ->
        if tp_eq t1 t2 then context
        else if occurs j t then raise UnificationFailure
        else bindTID j t context
    | t, TID j ->
        if equal_tp t1 t2 then context
        else if occurs j t then raise UnificationFailure
        else bindTID j t context
    | TCon (k1, as1, _), TCon (k2, as2, _) when String.( = ) k1 k2 ->
        List.fold2_exn ~init:context as1 as2 ~f:unify
    | TNCon (k1, as1, o1, _), TNCon (k2, as2, o2, _) when String.( = ) k1 k2 ->
        let context =
          List.fold2_exn ~init:context as1 as2 ~f:(fun context (v1, t1) (v2, t2) ->
              if String.( = ) v1 v2 then unify context t1 t2 else raise UnificationFailure)
        in
        unify context o1 o2
    | _ -> raise UnificationFailure

let instantiate_type k t =
  let substitution = ref [] in
  let k = ref k in
  let rec instantiate j =
    if not (is_polymorphic j) then j
    else
      match j with
      | TID i -> (
          try List.Assoc.find_exn ~equal:(fun a b -> a = b) !substitution i
          with Not_found_s _ ->
            let t, k' = makeTID !k in
            k := k';
            substitution := (i, t) :: !substitution;
            t)
      | TCon (k, js, _) -> kind k (List.map ~f:instantiate js)
      | TNCon (k, js, o, _) ->
          nkind k (List.map ~f:(fun (v, t) -> (v, instantiate t)) js) (instantiate o)
  in
  let q = instantiate t in
  (!k, q)

let applyContext' k t =
  let new_context, t' = applyContext !k t in
  k := new_context;
  t'

let unify' context_reference t1 t2 = context_reference := unify !context_reference t1 t2

let instantiate_type' context_reference t =
  let new_context, t' = instantiate_type !context_reference t in
  context_reference := new_context;
  t'

(* puts a type into normal form *)
let canonical_type t =
  let next = ref 0 in
  let substitution = ref [] in
  let rec canon q =
    match q with
    | TID i -> (
        try TID (List.Assoc.find_exn ~equal:( = ) !substitution i)
        with Not_found_s _ ->
          substitution := (i, !next) :: !substitution;
          next := 1 + !next;
          TID (!next - 1))
    | TCon (k, a, _) -> kind k (List.map ~f:canon a)
    | TNCon (k, a, o, _) -> nkind k (List.map ~f:(fun (v, t) -> (v, canon t)) a) (canon o)
  in
  canon t

let rec next_type_variable t =
  match t with
  | TID i -> i + 1
  | TCon (_, [], _) -> 0
  | TCon (_, is, _) -> List.fold_left ~f:max ~init:0 (List.map is ~f:next_type_variable)
  | TNCon (_, [], o, _) -> next_type_variable o
  | TNCon (_, is, o, _) ->
      max
        (List.fold_left ~f:max ~init:0 (List.map ~f:(fun (_, t) -> next_type_variable t) is))
        (next_type_variable o)

(* tries to instantiate a universally quantified type with a given request *)
(* let instantiated_type universal_type requested_type =
 *   try
 *     let (universal_type,c) = instantiate_type empty_context universal_type in
 *     let (requested_type,c) = instantiate_type c requested_type in
 *     let c = unify c universal_type requested_type in
 *     Some(canonical_type (applyContext c universal_type |> snd))
 *   with _ -> None *)

(* let compile_unifier t =
 *   let t = canonical_type t in
 *   let (xs,r) = arguments_and_return_of_type t in
 *   let free_variables = next_type_variable  in
 *
 *
 *   fun (target, context) ->
 *     if not (might_unify target r) then raise UnificationFailure else
 *       let bindings = Array.make free_variables None in
 *
 *       let rec u k template original =
 *         match (template, original) with
 *         | (TID(templateVariable), v) -> begin
 *             match bindings.(templateVariable) with
 *             | Some(bound) -> unify k bound v
 *             | None -> begin
 *                 bindings.(templateVariable) <- v;
 *                 context
 *               end
 *           end
 *         | () *)

let rec get_arity t =
  let open String in
  match t with
  | TCon (a, [ _; r ], _) when a = "->" -> 1 + get_arity r
  | TNCon (_, args, o, _) -> List.length args + get_arity o
  | _ -> 0

let rec pad_type_with_arguments context n t =
  if n = 0 then (context, t)
  else
    let a, context = makeTID context in
    let context, suffix = pad_type_with_arguments context (n - 1) t in
    (context, a @> suffix)

let make_ground g = TCon (g, [], false)
let tint = make_ground "int"
let tcharacter = make_ground "char"
let treal = make_ground "real"
let tboolean = make_ground "bool"
let turtle = make_ground "turtle"
let ttower = make_ground "tower"
let tstate = make_ground "tstate"
let tscalar = make_ground "tscalar"
let tangle = make_ground "tangle"
let tlength = make_ground "tlength"
let t0 = TID 0
let t1 = TID 1
let t2 = TID 2
let t3 = TID 3
let t4 = TID 4
let tlist t = kind "list" [ t ]
let tstring = tlist tcharacter
let tvar = make_ground "var"
let tprogram = make_ground "program"
let tmaybe t = kind "maybe" [ t ]
let tcanvas = tlist tint

let unify_many_types ts =
  let k = empty_context in
  let t, k = makeTID k in
  let k = ref k in
  ts
  |> List.iter ~f:(fun t' ->
         let k', t' = instantiate_type !k t' in
         k := unify k' t' t);
  applyContext !k t |> snd

let type_parser : tp parsing =
  let token = token_parser Char.is_alphanum in
  let whitespace = token_parser ~can_be_empty:true Char.is_whitespace in
  let number = token_parser Char.is_digit in

  let rec type_parser () : tp parsing = t_simple () <|> t_func ()
  and t_simple () = tcon_simple <|> tcon () <|> tid_parser <|> tncon ()
  and t_func () = tcon_arrow () <|> tncon_arrow ()
  and t_param () =
    t_simple ()
    <|> constant_parser "(" %% fun _ ->
        t_func () %% fun f ->
        constant_parser ")" %% fun _ -> return_parse f
  and tid_parser : tp parsing =
    constant_parser "t" %% fun _ ->
    number %% fun n -> return_parse (TID (Int.of_string n))
  and tcon_simple : tp parsing = token %% fun name -> return_parse (kind name [])
  and args_seq maybe_args =
    match maybe_args with
    | None -> type_parser () %% fun t -> args_seq (Some [ t ])
    | Some seq ->
        return_parse (List.rev seq)
        <|> constant_parser "," %% fun _ ->
            whitespace %% fun _ ->
            type_parser () %% fun t -> args_seq (Some (t :: seq))
  and tcon () : tp parsing =
    token %% fun name ->
    constant_parser "(" %% fun _ ->
    args_seq None %% fun args ->
    constant_parser ")" %% fun _ -> return_parse (kind name args)
  and tcon_arrow () : tp parsing =
    t_param () %% fun p ->
    return_parse p
    <|> whitespace %% fun _ ->
        constant_parser "->" %% fun _ ->
        whitespace %% fun _ ->
        tcon_arrow () %% fun q -> return_parse (make_arrow p q)
  and named_arg () =
    token %% fun n ->
    constant_parser ":" %% fun _ ->
    t_param () %% fun t -> return_parse (n, t)
  and tncon_arrow_seq maybe_args =
    whitespace %% fun _ ->
    match maybe_args with
    | None ->
        named_arg () %% fun a ->
        whitespace %% fun _ ->
        constant_parser "->" %% fun _ -> tncon_arrow_seq (Some [ a ])
    | Some seq ->
        (t_simple () %% fun t -> return_parse (nkind "->" (List.rev seq) t))
        <|> named_arg () %% fun a ->
            whitespace %% fun _ ->
            constant_parser "->" %% fun _ -> tncon_arrow_seq (Some (a :: seq))
  and tncon_arrow () : tp parsing = tncon_arrow_seq None %% fun a -> return_parse a
  and nargs_seq maybe_args =
    match maybe_args with
    | None ->
        named_arg () %% fun a ->
        constant_parser "," %% fun _ ->
        whitespace %% fun _ -> nargs_seq (Some [ a ])
    | Some seq ->
        (t_simple () %% fun t -> return_parse (List.rev seq, t))
        <|> named_arg () %% fun a ->
            constant_parser "," %% fun _ ->
            whitespace %% fun _ -> nargs_seq (Some (a :: seq))
  and tncon () : tp parsing =
    token %% fun name ->
    constant_parser "(" %% fun _ ->
    nargs_seq None %% fun (args, out) ->
    constant_parser ")" %% fun _ -> return_parse (nkind name args out)
  in

  type_parser ()

let type_of_string (s : string) : tp option = run_parser type_parser s

let type_parsing_test_case s =
  let top = type_of_string s in
  match top with None -> false | Some t -> String.( = ) s (string_of_type t)

let%test _ =
  let t = type_of_string "t0" in
  match t with Some (TID x) when x = 0 -> true | _ -> false

let%test _ = type_parsing_test_case "t0"
let%test _ = type_parsing_test_case "t1"
let%test _ = type_parsing_test_case "int"
let%test _ = type_parsing_test_case "list(int)"
let%test _ = type_parsing_test_case "tuple(int, int)"
let%test _ = type_parsing_test_case "int -> int"
let%test _ = type_parsing_test_case "int -> int -> int"
let%test _ = type_parsing_test_case "list(int) -> list(int)"
let%test _ = type_parsing_test_case "list(int) -> list(int) -> list(int)"
let%test _ = type_parsing_test_case "list(int) -> (int -> bool) -> list(bool)"
let%test _ = type_parsing_test_case "inp0:list(int) -> list(int)"
let%test _ = type_parsing_test_case "inp0:list(int) -> inp1:list(int) -> list(int)"
let%test _ = type_parsing_test_case "f:(list(int) -> int) -> inp1:list(int) -> list(int)"
let%test _ = type_parsing_test_case "obj(cells:list(tuple(int, int)), kind)"
let%test _ = type_parsing_test_case "obj(cells:list(tuple(int, int)), pivot:bool, kind)"
let%test _ = type_parsing_test_case "obj(f:(int -> int), cells:list(tuple(int, int)), kind)"
let%test _ = type_parsing_test_case "obj(int -> int, list(tuple(int, int)), kind)"

let rec deserialize_type j =
  let open Yojson.Basic.Util in
  try
    let o = j |> member "output" |> deserialize_type in
    let k = j |> member "constructor" |> to_string in
    let a =
      j |> member "arguments" |> to_assoc |> List.map ~f:(fun (v, t) -> (v, deserialize_type t))
    in
    nkind k a o
  with _ -> (
    try
      let k = j |> member "constructor" |> to_string in
      let a = j |> member "arguments" |> to_list |> List.map ~f:deserialize_type in
      kind k a
    with _ ->
      let i = j |> member "index" |> to_int in
      TID i)

let rec serialize_type t =
  let j : Yojson.Basic.t =
    match t with
    | TID i -> `Assoc [ ("index", `Int i) ]
    | TCon (k, a, _) ->
        `Assoc
          [ ("constructor", `String k); ("arguments", `List (a |> List.map ~f:serialize_type)) ]
    | TNCon (k, args, o, _) ->
        `Assoc
          [
            ("constructor", `String k);
            ("arguments", `Assoc (args |> List.map ~f:(fun (v, t) -> (v, serialize_type t))));
            ("output", serialize_type o);
          ]
  in
  j
