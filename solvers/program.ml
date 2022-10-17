open Core
open Parser
open Utils
open Type

type program =
  | Index of int
  | Abstraction of program
  | Apply of program * program
  | Primitive of tp * string * unit ref
  | Invented of tp * program
  | LetClause of string * program * program
  | LetRevClause of string list * string * program * program
  | FreeVar of string
  | Const of tp * string
  | WrapEither of string list * string * string * program * program * program
[@@deriving equal]

let is_index = function Index _ -> true | _ -> false
let get_index_value = function Index n -> n | _ -> assert false
let is_primitive = function Primitive (_, _, _) -> true | Invented (_, _) -> true | _ -> false
let is_base_primitive = function Primitive (_, _, _) -> true | _ -> false
let is_abstraction = function Abstraction _ -> true | _ -> false

let rec recursively_get_abstraction_body = function
  | Abstraction b -> recursively_get_abstraction_body b
  | e -> e

let program_children = function Abstraction b -> [ b ] | Apply (m, n) -> [ m; n ] | _ -> []
let rec application_function = function Apply (f, _) -> application_function f | e -> e

let rec application_parse = function
  | Apply (f, x) ->
      let f, arguments = application_parse f in
      (f, arguments @ [ x ])
  | f -> (f, [])

let rec program_size = function
  | Apply (f, x) -> program_size f + program_size x
  | Abstraction b -> program_size b
  | Index _ | Invented (_, _) | Primitive (_, _, _) | Const _ -> 1
  | LetClause (_, d, b) -> program_size d + program_size b
  | LetRevClause (_, _, d, b) -> program_size d + program_size b
  | WrapEither (_, _, _, d, _, b) -> program_size d + program_size b
  | FreeVar _ -> 1

let rec program_subexpressions p =
  p :: (List.map (program_children p) ~f:program_subexpressions |> List.concat)

let rec show_program (is_function : bool) = function
  | Index j -> "$" ^ string_of_int j
  | Abstraction body -> "(lambda " ^ show_program false body ^ ")"
  | Apply (p, q) ->
      if is_function then show_program true p ^ " " ^ show_program false q
      else "(" ^ show_program true p ^ " " ^ show_program false q ^ ")"
  | Primitive (t, "FREE_VAR", _) -> "FREE_VAR(" ^ string_of_type t ^ ")"
  | Primitive (_, n, _) -> n
  | Invented (_, i) -> "#" ^ show_program false i
  | LetClause (var, def, body) ->
      "let $" ^ var ^ " = " ^ show_program false def ^ " in " ^ show_program false body
  | LetRevClause (vars, inp, def, body) ->
      "let "
      ^ String.concat ~sep:", " (List.map vars ~f:(fun var -> "$" ^ var))
      ^ " = rev($" ^ inp ^ " = " ^ show_program false def ^ ") in " ^ show_program false body
  | FreeVar n -> "$" ^ n
  | Const (t, n) -> "Const(" ^ string_of_type t ^ ", " ^ n ^ ")"
  | WrapEither (vars, inp, fixer, def, f, body) ->
      let var_list = String.concat ~sep:", " (List.map vars ~f:(fun var -> "$" ^ var)) in
      "let " ^ var_list ^ " = wrap(let " ^ var_list ^ " = rev($" ^ inp ^ " = "
      ^ show_program false def ^ "); let $" ^ fixer ^ " = " ^ show_program false f ^ ") in "
      ^ show_program false body

let string_of_program = show_program false

let primitive_name = function
  | Primitive (_, n, _) -> n
  | e -> raise (Failure ("primitive_name: " ^ string_of_program e ^ "not a primitive"))

let rec program_equal p1 p2 =
  match (p1, p2) with
  | Primitive (_, n1, _), Primitive (_, n2, _) -> String.( = ) n1 n2
  | Abstraction a, Abstraction b -> program_equal a b
  | Invented (_, a), Invented (_, b) -> program_equal a b
  | Index a, Index b -> a = b
  | Apply (a, b), Apply (x, y) -> program_equal a x && program_equal b y
  | LetClause (v1, d1, b1), LetClause (v2, d2, b2) ->
      String.( = ) v1 v2 && program_equal d1 d2 && program_equal b1 b2
  | LetRevClause (vns1, iv1, d1, b1), LetRevClause (vns2, iv2, d2, b2) ->
      List.equal String.( = ) vns1 vns2 && String.( = ) iv1 iv2 && program_equal d1 d2
      && program_equal b1 b2
  | FreeVar v1, FreeVar v2 -> String.( = ) v1 v2
  | Const (t1, c1), Const (t2, c2) -> tp_eq t1 t2 && String.( = ) c1 c2
  | ( WrapEither (vars1, inp1, fixer1, def1, f1, body1),
      WrapEither (vars2, inp2, fixer2, def2, f2, body2) ) ->
      List.equal String.( = ) vars1 vars2
      && String.( = ) inp1 inp2 && String.( = ) fixer1 fixer2 && program_equal def1 def2
      && program_equal f1 f2 && program_equal body1 body2
  | _ -> false

let rec compare_program p1 p2 =
  match (p1, p2) with
  (* Negative if p1 is smaller; 0 if they are equal; positive if p1 is bigger *)
  (* intuitively calculates (p1 - p2) *)
  | Index i, Index j -> i - j
  | Index _, _ -> -1
  | Abstraction b1, Abstraction b2 -> compare_program b1 b2
  | Abstraction _, _ -> -1
  | Apply (p, q), Apply (m, n) ->
      let c = compare_program p m in
      if c = 0 then compare_program q n else c
  | Apply (_, _), _ -> -1
  | Primitive (_, n1, _), Primitive (_, n2, _) -> String.compare n1 n2
  | Primitive (_, _, _), _ -> -1
  | Invented (_, b1), Invented (_, b2) -> compare_program b1 b2
  | Invented (_, _), _ -> -1
  | LetClause (_, b1, e1), LetClause (_, b2, e2) ->
      let c = compare_program b1 b2 in
      if c = 0 then compare_program e1 e2 else c
  | LetClause (_, _, _), _ -> -1
  | LetRevClause (_, inp1, def1, body1), LetRevClause (_, inp2, def2, body2) ->
      let c = compare_program def1 def2 in
      if c = 0 then
        let c1 = compare_program body1 body2 in
        if c1 = 0 then String.compare inp1 inp2 else c1
      else c
  | LetRevClause (_, _, _, _), _ -> -1
  | FreeVar n1, FreeVar n2 -> String.compare n1 n2
  | FreeVar _, _ -> -1
  | Const (_, n1), Const (_, n2) -> String.compare n1 n2
  | Const _, _ -> -1
  | WrapEither (_, inp1, fixer1, def1, f1, body1), WrapEither (_, inp2, fixer2, def2, f2, body2) ->
      let c = compare_program def1 def2 in
      if c = 0 then
        let c1 = compare_program body1 body2 in
        if c1 = 0 then
          let c2 = compare_program f1 f2 in
          if c2 = 0 then
            let c3 = String.compare inp1 inp2 in
            if c3 = 0 then String.compare fixer1 fixer2 else c3
          else c2
        else c1
      else c
  | WrapEither (_vars, _inp, _fixer, _def, _f, _body), _ -> -1

exception UnboundVariable

let rec infer_program_type context environment p : tContext * tp =
  match p with
  | Index j -> (
      match List.nth environment j with
      | None -> raise UnboundVariable
      | Some t -> applyContext context t)
  | Primitive (t, _, _) -> instantiate_type context t
  | Invented (t, _) -> instantiate_type context t
  | Abstraction b ->
      let xt, context = makeTID context in
      let context, rt = infer_program_type context (xt :: environment) b in
      applyContext context (xt @> rt)
  | Apply (f, x) ->
      let rt, context = makeTID context in
      let context, xt = infer_program_type context environment x in
      let context, ft = infer_program_type context environment f in
      let context = unify context ft (xt @> rt) in
      applyContext context rt
  | Const (t, _) -> instantiate_type context t
  | _ ->
      raise (Failure ("Inferring program type is currently not supported: " ^ string_of_program p))

let closed_inference = snd % infer_program_type empty_context []
let make_invention i = Invented (closed_inference i |> canonical_type, i)

exception UnknownPrimitive of string

let every_primitive : program String.Table.t = String.Table.create ()

let lookup_primitive n =
  try Hashtbl.find_exn every_primitive n with _ -> raise (UnknownPrimitive n)

let[@warning "-20"] rec evaluate (environment : 'b list) (workspace : (string, 'c) Hashtbl.t)
    (p : program) : 'a =
  match p with
  | Apply (Apply (Apply (Primitive (_, "if", _), branch), yes), no) ->
      if magical (evaluate environment workspace branch) then evaluate environment workspace yes
      else evaluate environment workspace no
  | Abstraction b -> magical @@ fun argument -> evaluate (argument :: environment) workspace b
  | Index j -> magical @@ List.nth_exn environment j
  | Apply (f, x) ->
      (magical @@ evaluate environment workspace f) (magical @@ evaluate environment workspace x)
  | Primitive (_, _, v) -> magical !v
  | Invented (_, i) -> evaluate [] workspace i
  | Const _ -> assert false (* There is no instantiation of const objects currently in OCaml *)
  | LetClause (v, d, b) ->
      let v_val = evaluate environment workspace d in
      let () = Hashtbl.add_exn workspace ~key:v ~data:v_val in
      evaluate environment workspace b
  | LetRevClause (_vns, _iv, _d, _b) ->
      assert false (* There are no reversed functions currently in OCaml *)
  | WrapEither (_vars, _inp, _fixer, _def, _f, _body) ->
      assert false (* There are no reversed functions currently in OCaml *)
  | FreeVar v -> magical (Hashtbl.find_exn workspace v)

let rec analyze_evaluation (p : program) : 'b list -> (string, 'c) Hashtbl.t -> 'a =
  match p with
  | Apply (Apply (Apply (Primitive (_, "if", _), branch), yes), no) ->
      let branch = analyze_evaluation branch
      and yes = analyze_evaluation yes
      and no = analyze_evaluation no in
      fun environment workspace ->
        if magical (branch environment workspace) then yes environment workspace
        else no environment workspace
  | Abstraction b ->
      let body = analyze_evaluation b in
      fun environment workspace -> magical (fun x -> body (x :: environment) workspace)
  | Index j -> fun environment _ -> List.nth_exn environment j |> magical
  | Apply (f, x) ->
      let analyzed_function = analyze_evaluation f and analyzed_argument = analyze_evaluation x in
      fun environment workspace ->
        magical
          ((analyzed_function environment workspace)
             (magical (analyzed_argument environment workspace)))
  | Primitive (_, _, v) -> fun _ _ -> magical !v
  | Invented (_, i) ->
      let analyzed_body = analyze_evaluation i in
      fun _ workspace -> analyzed_body [] workspace
  | Const _ -> assert false (* There is no instantiation of const objects currently in OCaml *)
  | LetClause (v, d, b) ->
      let analyzed_definition = analyze_evaluation d and analyzed_body = analyze_evaluation b in
      fun environment workspace ->
        let v_val = analyzed_definition environment workspace in
        let () = Hashtbl.add_exn workspace ~key:v ~data:v_val in
        analyzed_body environment workspace
  | LetRevClause (_vns, _iv, _d, _b) ->
      assert false (* There are no reversed functions currently in OCaml *)
  | WrapEither (_vars, _inp, _fixer, _def, _f, _body) ->
      assert false (* There are no reversed functions currently in OCaml *)
  | FreeVar v -> fun _ workspace -> magical (Hashtbl.find_exn workspace v)

let run_with_arguments (p : program) (arguments : 'a list) =
  let rec loop l xs = match xs with [] -> magical l | x :: xs -> loop (magical (l x)) xs in
  loop (evaluate [] (Hashtbl.create (module String)) p) arguments

let run_analyzed_with_arguments (p : 'b list -> (string, 'd) Hashtbl.t -> 'c) (arguments : 'a list)
    =
  let rec loop l xs = match xs with [] -> magical l | x :: xs -> loop (magical (l x)) xs in
  loop (p [] (Hashtbl.create (module String))) arguments

let[@warning "-20"] rec lazy_evaluate (environment : 'b Lazy.t list)
    (workspace : (string, 'c Lazy.t) Hashtbl.t) (p : program) : 'a Lazy.t =
  (* invariant: always return thunks *)
  match p with
  (* Notice that we do not need to special case conditionals. In lazy
     evaluation conditionals are function just like any other. *)
  | Abstraction b ->
      lazy
        (magical @@ fun argument -> Lazy.force (lazy_evaluate (argument :: environment) workspace b))
  | Index j -> magical @@ List.nth_exn environment j
  | Apply (f, x) ->
      lazy
        ((Lazy.force @@ magical @@ lazy_evaluate environment workspace f)
           (magical @@ lazy_evaluate environment workspace x))
  | Primitive (_, _, v) -> lazy (magical !v)
  | Invented (_, i) -> lazy_evaluate [] workspace i
  | Const _ -> assert false (* There is no instantiation of const objects currently in OCaml *)
  | FreeVar v -> magical (Hashtbl.find_exn workspace v)
  | LetClause (v, d, b) ->
      let v_val = lazy_evaluate environment workspace d in
      let () = Hashtbl.add_exn workspace ~key:v ~data:v_val in
      lazy_evaluate environment workspace b
  | LetRevClause (_vns, _iv, _d, _b) ->
      assert false (* There are no reversed functions currently in OCaml *)
  | WrapEither (_vars, _inp, _fixer, _def, _f, _body) ->
      assert false (* There are no reversed functions currently in OCaml *)

let[@warning "-20"] rec analyze_lazy_evaluation (p : program) : 'b Lazy.t list -> 'a Lazy.t =
  match p with
  (* Notice that we do not need to special case conditionals. In lazy
     evaluation conditionals are function just like any other. *)
  | Abstraction b ->
      let body = analyze_lazy_evaluation b in
      fun environment ->
        lazy (magical @@ fun argument -> Lazy.force (body (argument :: environment)))
  | Index j -> fun environment -> magical @@ List.nth_exn environment j
  | Apply (f, x) ->
      let analyzed_function = analyze_lazy_evaluation f
      and analyzed_argument = analyze_lazy_evaluation x in
      fun environment ->
        lazy
          ((Lazy.force @@ magical @@ analyzed_function environment)
             (magical @@ analyzed_argument environment))
  | Primitive (_, _, v) -> fun _ -> lazy (magical !v)
  | Invented (_, i) ->
      let analyzed_body = analyze_lazy_evaluation i in
      fun _ -> analyzed_body []
  | Const _
  | LetClause (_, _, _)
  | FreeVar _
  | LetRevClause (_, _, _, _)
  | WrapEither (_, _, _, _, _, _) ->
      assert false (* Let clauses are not supported for lazy evaluation *)

let[@warning "-20"] run_lazy_analyzed_with_arguments p arguments =
  let rec go l xs = match xs with [] -> l |> magical | x :: xs -> go (lazy x |> magical l) xs in
  go (p [] |> Lazy.force) arguments

let rec remove_abstractions (n : int) (q : program) : program =
  match (n, q) with
  | 0, q -> q
  | n, Abstraction body -> remove_abstractions (n - 1) body
  | _ -> raise (Failure "remove_abstractions")

let rec variable_is_bound ?(height = 0) (p : program) =
  match p with
  | Index j -> j = height
  | Apply (f, x) -> variable_is_bound ~height f || variable_is_bound ~height x
  | Invented (_, i) -> variable_is_bound ~height i
  | Primitive (_, _, _) -> false
  | Abstraction b -> variable_is_bound ~height:(height + 1) b
  | LetClause (_, _, _)
  | LetRevClause (_, _, _, _)
  | FreeVar _ | Const _
  | WrapEither (_, _, _, _, _, _) ->
      false

exception ShiftFailure

let rec shift_free_variables ?(height = 0) shift p =
  match p with
  | Index j ->
      if j < height then p else if j + shift < 0 then raise ShiftFailure else Index (j + shift)
  | Apply (f, x) ->
      Apply (shift_free_variables ~height shift f, shift_free_variables ~height shift x)
  | Invented (_, _) | Primitive (_, _, _) | Const _ | FreeVar _ -> p
  | Abstraction b -> Abstraction (shift_free_variables ~height:(height + 1) shift b)
  | LetClause (vnames, def, body) ->
      LetClause
        (vnames, shift_free_variables ~height shift def, shift_free_variables ~height shift body)
  | LetRevClause (vnames, inp_var_name, def, body) ->
      LetRevClause
        ( vnames,
          inp_var_name,
          shift_free_variables ~height shift def,
          shift_free_variables ~height shift body )
  | WrapEither (vars, inp, fixer, def, f, body) ->
      WrapEither
        ( vars,
          inp,
          fixer,
          shift_free_variables ~height shift def,
          f,
          shift_free_variables ~height shift body )

let rec free_variables ?(d = 0) e =
  match e with
  | Index j -> if j >= d then [ j - d ] else []
  | Apply (f, x) -> free_variables ~d f @ free_variables ~d x
  | Abstraction b -> free_variables ~d:(d + 1) b
  | _ -> []

let rec substitute i v e =
  match e with
  | Index j -> if i = j then v else e
  | Abstraction b -> Abstraction (substitute (i + 1) (shift_free_variables 1 v) b)
  | Apply (f, x) -> Apply (substitute i v f, substitute i v x)
  | _ -> e

let rec beta_normal_form ?(reduceInventions = false) e =
  let rec step = function
    | Abstraction b -> ( match step b with Some b' -> Some (Abstraction b') | None -> None)
    | Invented (_, b) when reduceInventions -> Some b
    | Apply (f, x) -> (
        match step f with
        | Some f' -> Some (Apply (f', x))
        | None -> (
            match step x with
            | Some x' -> Some (Apply (f, x'))
            | None -> (
                match f with
                | Abstraction body ->
                    Some
                      (shift_free_variables ~height:0 (-1)
                         (substitute 0 (shift_free_variables 1 x) body))
                | _ -> None)))
    | LetClause (vname, def, body) -> (
        match step def with
        | Some def' -> Some (LetClause (vname, def', body))
        | None -> (
            match step body with Some body' -> Some (LetClause (vname, def, body')) | None -> None))
    | LetRevClause (vnames, inp_var_name, def, body) -> (
        match step def with
        | Some def' -> Some (LetRevClause (vnames, inp_var_name, def', body))
        | None -> (
            match step body with
            | Some body' -> Some (LetRevClause (vnames, inp_var_name, def, body'))
            | None -> None))
    | WrapEither (vnames, inp_var_name, fixer, def, f, body) -> (
        match step def with
        | Some def' -> Some (WrapEither (vnames, inp_var_name, fixer, def', f, body))
        | None -> (
            match step body with
            | Some body' -> Some (WrapEither (vnames, inp_var_name, fixer, def, f, body'))
            | None -> None))
    | _ -> None
  in
  match step e with None -> e | Some e' -> beta_normal_form ~reduceInventions e'

let unit_reference = ref ()

let rec strip_primitives = function
  | Index n -> Index n
  | Invented (t, e) -> Invented (t, strip_primitives e)
  | Apply (f, x) -> Apply (strip_primitives f, strip_primitives x)
  | Abstraction b -> Abstraction (strip_primitives b)
  | Primitive (t, n, _) -> Primitive (t, n, unit_reference)
  | LetClause (n, d, b) -> LetClause (n, strip_primitives d, strip_primitives b)
  | LetRevClause (ns, ins, d, b) -> LetRevClause (ns, ins, strip_primitives d, strip_primitives b)
  | FreeVar n -> FreeVar n
  | Const (t, n) -> Const (t, n)
  | WrapEither (vars, inp, fixer, def, f, body) ->
      WrapEither (vars, inp, fixer, strip_primitives def, f, strip_primitives body)

(* PRIMITIVES *)
let[@warning "-20"] primitive ?(manualLaziness = false) (name : string) (t : tp) x =
  let number_of_arguments = arguments_of_type t |> List.length in
  (* Force the arguments *)
  let x =
    if manualLaziness then x
    else
      magical
      @@
      match number_of_arguments with
      | 0 -> magical x
      | 1 -> fun a -> (magical x) (Lazy.force a)
      | 2 -> fun a b -> (magical x) (Lazy.force a) (Lazy.force b)
      | 3 -> fun a b c -> (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c)
      | 4 -> fun a b c d -> (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c) (Lazy.force d)
      | 5 ->
          fun a b c d e ->
            (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c) (Lazy.force d) (Lazy.force e)
      | 6 ->
          fun a b c d e f ->
            (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c) (Lazy.force d) (Lazy.force e)
              (Lazy.force f)
      | 7 ->
          fun a b c d e f g ->
            (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c) (Lazy.force d) (Lazy.force e)
              (Lazy.force f) (Lazy.force g)
      | 8 ->
          fun a b c d e f g h ->
            (magical x) (Lazy.force a) (Lazy.force b) (Lazy.force c) (Lazy.force d) (Lazy.force e)
              (Lazy.force f) (Lazy.force g) (Lazy.force h)
      | _ ->
          raise
            (Failure
               (Printf.sprintf
                  "Primitive %s can not be lazy because it has %d arguments. Change `primitive` in \
                   program.ml if you want to enable laziness for %s.\n"
                  name number_of_arguments name))
  in
  let p = Primitive (t, name, ref (magical x)) in
  assert (not (Hashtbl.mem every_primitive name));
  ignore (Hashtbl.add every_primitive ~key:name ~data:p : [ `Duplicate | `Ok ]);
  p

(* let primitive_empty_string = primitive "emptyString" tstring "";; *)
let primitive_uppercase = primitive "caseUpper" (tcharacter @> tcharacter) Char.uppercase

(* let primitive_uppercase = primitive "strip" (tstring @> tstring) (fun s -> String.strip s);; *)
let primitive_lowercase = primitive "caseLower" (tcharacter @> tcharacter) Char.lowercase

let primitive_character_equal =
  primitive "char-eq?" (tcharacter @> tcharacter @> tboolean) Char.equal

let primitive_character_upper = primitive "char-upper?" (tcharacter @> tboolean) Char.is_uppercase

let primitive_string_equal =
  primitive "str-eq?" (tlist tcharacter @> tlist tcharacter @> tboolean) (fun x y -> x = y)

(* let primitive_capitalize = primitive "caseCapitalize" (tstring @> tstring) String.capitalize;;
 * let primitive_concatenate = primitive "concatenate" (tstring @> tstring @> tstring) ( ^ );; *)
let primitive_constant_strings =
  [
    primitive "','" tcharacter ',';
    primitive "'.'" tcharacter '.';
    primitive "'@'" tcharacter '@';
    primitive "SPACE" tcharacter ' ';
    primitive "'<'" tcharacter '<';
    primitive "'>'" tcharacter '>';
    primitive "'/'" tcharacter '/';
    primitive "'|'" tcharacter '|';
    primitive "'-'" tcharacter '-';
    primitive "LPAREN" tcharacter '(';
    primitive "RPAREN" tcharacter ')';
  ]

(* let primitive_slice_string = primitive "slice-string" (tint @> tint @> tstring @> tstring)
 *     (fun i j s ->
 *        let i = i + (if i < 0 then String.length s else 0) in
 *        let j = j + (if j < 0 then 1 + String.length s else 0) in
 *        String.sub s ~pos:i ~len:(j - i));;
 * let primitive_nth_string = primitive "nth" (tint @> tlist tstring @> tstring)
 *     (fun n words ->
 *        let n = n + (if n < 0 then List.length words else 0) in
 *        List.nth_exn words n);;
 * let primitive_map_string = primitive "map-string" ((tstring @> tstring) @> tlist tstring @> tlist tstring)
 *     (fun f l -> List.map ~f:f l);;
 * let primitive_string_split = primitive "split" (tcharacter @> tstring @> tlist tstring)
 *     (fun d x -> String.split ~on:d x);;
 * let primitive_string_join = primitive "join" (tstring @> tlist tstring @> tstring)
 *     (fun d xs -> join ~separator:d xs);;
 * let primitive_character_to_string = primitive "chr2str" (tcharacter @> tstring) (String.of_char);; *)

let primitive0 = primitive "0" tint 0
let primitive1 = primitive "1" tint 1
let primitiven1 = primitive "-1" tint (0 - 1)
let primitive2 = primitive "2" tint 2
let primitive3 = primitive "3" tint 3
let primitive4 = primitive "4" tint 4
let primitive5 = primitive "5" tint 5
let primitive6 = primitive "6" tint 6
let primitive7 = primitive "7" tint 7
let primitive8 = primitive "8" tint 8
let primitive9 = primitive "9" tint 9
let primitive20 = primitive "ifty" tint 20
let primitive_addition = primitive "+" (tint @> tint @> tint) (fun x y -> x + y)
let primitive_increment = primitive "incr" (tint @> tint) (fun x -> 1 + x)
let primitive_decrement = primitive "decr" (tint @> tint) (fun x -> x - 1)
let primitive_subtraction = primitive "-" (tint @> tint @> tint) ( - )
let primitive_negation = primitive "negate" (tint @> tint) (fun x -> 0 - x)
let primitive_multiplication = primitive "*" (tint @> tint @> tint) ( * )
let primitive_modulus = primitive "mod" (tint @> tint @> tint) (fun x y -> x mod y)
let primitive_apply = primitive "apply" (t1 @> (t1 @> t0) @> t0) (fun x f -> f x)
let primitive_true = primitive "true" tboolean true
let primitive_false = primitive "false" tboolean false

let primitive_if =
  primitive "if"
    (tboolean @> t0 @> t0 @> t0)
    ~manualLaziness:true
    (fun p x y -> if Lazy.force p then Lazy.force x else Lazy.force y)

let primitive_is_square =
  primitive "is-square" (tint @> tboolean) (fun x ->
      let y = Float.of_int x in
      let s = sqrt y |> Int.of_float in
      s * s = x)

let primitive_is_prime =
  primitive "is-prime" (tint @> tboolean) (fun x ->
      List.mem ~equal:( = )
        [
          2;
          3;
          5;
          7;
          11;
          13;
          17;
          19;
          23;
          29;
          31;
          37;
          41;
          43;
          47;
          53;
          59;
          61;
          67;
          71;
          73;
          79;
          83;
          89;
          97;
          101;
          103;
          107;
          109;
          113;
          127;
          131;
          137;
          139;
          149;
          151;
          157;
          163;
          167;
          173;
          179;
          181;
          191;
          193;
          197;
          199;
        ]
        x)

let primitive_cons = primitive "cons" (t0 @> tlist t0 @> tlist t0) (fun x xs -> x :: xs)
let primitive_car = primitive "car" (tlist t0 @> t0) (fun xs -> List.hd_exn xs)
let primitive_cdr = primitive "cdr" (tlist t0 @> tlist t0) (fun xs -> List.tl_exn xs)

let primitive_is_empty =
  primitive "empty?" (tlist t0 @> tboolean) (function [] -> true | _ -> false)

let primitive_string_constant = primitive "STRING" (tlist tcharacter) ()

let rec substitute_string_constants (alternatives : char list list) e =
  match e with
  | Primitive (c, "STRING", _) ->
      alternatives |> List.map ~f:(fun a -> Primitive (c, "STRING", ref a |> magical))
  | Primitive (_, _, _) -> [ e ]
  | Invented (_, b) -> substitute_string_constants alternatives b
  | Apply (f, x) ->
      substitute_string_constants alternatives f
      |> List.map ~f:(fun f' ->
             substitute_string_constants alternatives x |> List.map ~f:(fun x' -> Apply (f', x')))
      |> List.concat
  | Abstraction b ->
      substitute_string_constants alternatives b |> List.map ~f:(fun b' -> Abstraction b')
  | Index _ -> [ e ]
  | Const _ -> [ e ]
  | FreeVar _ -> [ e ]
  | LetClause (v, d, b) ->
      substitute_string_constants alternatives d
      |> List.map ~f:(fun d' ->
             substitute_string_constants alternatives b
             |> List.map ~f:(fun b' -> LetClause (v, d', b')))
      |> List.concat
  | LetRevClause (vs, iv, d, b) ->
      substitute_string_constants alternatives d
      |> List.map ~f:(fun d' ->
             substitute_string_constants alternatives b
             |> List.map ~f:(fun b' -> LetRevClause (vs, iv, d', b')))
      |> List.concat
  | WrapEither (vars, inp, fixer, def, f, body) ->
      substitute_string_constants alternatives def
      |> List.map ~f:(fun d' ->
             substitute_string_constants alternatives body
             |> List.map ~f:(fun b' -> WrapEither (vars, inp, fixer, d', f, b')))
      |> List.concat

let rec number_of_string_constants = function
  | Primitive (_, "STRING", _) -> 1
  | Primitive (_, _, _) -> 0
  | Invented (_, b) | Abstraction b -> number_of_string_constants b
  | Apply (f, x) -> number_of_string_constants f + number_of_string_constants x
  | Index _ | FreeVar _ | Const _ -> 0
  | LetClause (_, d, b) | LetRevClause (_, _, d, b) | WrapEither (_, _, _, d, _, b) ->
      number_of_string_constants d + number_of_string_constants b

let rec string_constants_length = function
  | Primitive (_, "STRING", v) ->
      let v = magical v in
      List.length !v
  | Primitive (_, _, _) -> 0
  | Invented (_, b) | Abstraction b -> string_constants_length b
  | Apply (f, x) -> string_constants_length f + string_constants_length x
  | Index _ | FreeVar _ | Const _ -> 0
  | LetClause (_, d, b) | LetRevClause (_, _, d, b) | WrapEither (_, _, _, d, _, b) ->
      string_constants_length d + string_constants_length b

let rec number_of_real_constants = function
  | Primitive (_, "REAL", _) -> 1
  | Primitive (_, _, _) -> 0
  | Invented (_, b) | Abstraction b -> number_of_real_constants b
  | Apply (f, x) -> number_of_real_constants f + number_of_real_constants x
  | Index _ | FreeVar _ | Const _ -> 0
  | LetClause (_, d, b) | LetRevClause (_, _, d, b) | WrapEither (_, _, _, d, _, b) ->
      number_of_real_constants d + number_of_real_constants b

let rec number_of_free_parameters = function
  | Primitive (_, "REAL", _)
  | Primitive (_, "STRING", _)
  | Primitive (_, "r_const", _)
  | Primitive (_, "FREE_VAR", _) ->
      1
  | Primitive (_, _, _) -> 0
  | Invented (_, b) | Abstraction b -> number_of_free_parameters b
  | Apply (f, x) -> number_of_free_parameters f + number_of_free_parameters x
  | Index _ | FreeVar _ | Const _ -> 0
  | LetClause (_, d, b) | LetRevClause (_, _, d, b) | WrapEither (_, _, _, d, _, b) ->
      number_of_free_parameters d + number_of_free_parameters b

let primitive_empty = primitive "empty" (tlist t0) []
let primitive_range = primitive "range" (tint @> tlist tint) (fun x -> 0 -- (x - 1))

let primitive_sort =
  primitive "sort" (tlist tint @> tlist tint) (List.sort ~compare:(fun x y -> x - y))

let primitive_reverse = primitive "reverse" (tlist tint @> tlist tint) List.rev
let primitive_append = primitive "append" (tlist t0 @> tlist t0 @> tlist t0) ( @ )
let primitive_singleton = primitive "singleton" (tint @> tlist tint) (fun x -> [ x ])
let primitive_slice = primitive "slice" (tint @> tint @> tlist tint @> tlist tint) slice
let primitive_length = primitive "length" (tlist t0 @> tint) List.length
let primitive_map = primitive "map" ((t0 @> t1) @> tlist t0 @> tlist t1) (fun f l -> List.map ~f l)

let primitive_fold_right =
  primitive "fold_right"
    ((tint @> tint @> tint) @> tint @> tlist tint @> tint)
    (fun f x0 l -> List.fold_right ~f ~init:x0 l)

let primitive_mapi =
  primitive "mapi" ((tint @> t0 @> t1) @> tlist t0 @> tlist t1) (fun f l -> List.mapi l ~f)

let primitive_a2 = primitive "++" (tlist t0 @> tlist t0 @> tlist t0) ( @ )

let primitive_reducei =
  primitive "reducei"
    ((tint @> t1 @> t0 @> t1) @> t1 @> tlist t0 @> t1)
    (fun f x0 l -> List.foldi ~f ~init:x0 l)

let primitive_filter =
  primitive "filter" ((t0 @> tboolean) @> tlist t0 @> tlist t0) (fun f l -> List.filter ~f l)

let primitive_filter_int =
  primitive "filter_int"
    ((tint @> tboolean) @> tlist tint @> tlist tint)
    (fun f l -> List.filter ~f l)

let primitive_equal = primitive "eq?" (tint @> tint @> tboolean) (fun (a : int) (b : int) -> a = b)
let primitive_equal0 = primitive "eq0" (tint @> tboolean) (fun (a : int) -> a = 0)
let primitive_not = primitive "not" (tboolean @> tboolean) not
let primitive_and = primitive "and" (tboolean @> tboolean @> tboolean) (fun x y -> x && y)
let primitive_nand = primitive "nand" (tboolean @> tboolean @> tboolean) (fun x y -> not (x && y))
let primitive_or = primitive "or" (tboolean @> tboolean @> tboolean) (fun x y -> x || y)

let primitive_repeat =
  primitive "repeat" (t0 @> tint @> tlist t0) (fun x n -> List.init n ~f:(fun _ -> x))

let primitive_concat = primitive "concat" (tlist t0 @> tlist t0 @> tlist t0) (fun a b -> a @ b)

let primitive_greater_than =
  primitive "gt?" (tint @> tint @> tboolean) (fun (x : int) (y : int) -> x > y)

let (_ : unit) =
  ignore
    (primitive "take-word"
       (tcharacter @> tstring @> tstring)
       (fun c s -> List.take_while s ~f:(fun c' -> not (c = c')))
      : program);
  ignore
    (primitive "drop-word"
       (tcharacter @> tstring @> tstring)
       (fun c s -> List.drop_while s ~f:(fun c' -> not (c = c')) |> List.tl |> get_some)
      : program);
  ignore
    (primitive "abbreviate" (tstring @> tstring) (fun s ->
         let open Char in
         let rec f = function
           | [] -> []
           | ' ' :: cs -> f cs
           | c :: cs -> c :: f (List.drop_while cs ~f:(fun c' -> not (c' = ' ')))
         in
         f s)
      : program);
  ignore
    (primitive "last-word"
       (tcharacter @> tstring @> tstring)
       (fun c s -> List.rev s |> List.take_while ~f:(fun c' -> not (c = c')) |> List.rev)
      : program);
  ignore
    (primitive "replace-character"
       (tcharacter @> tcharacter @> tstring @> tstring)
       (fun c1 c2 s -> s |> List.map ~f:(fun c -> if c = c1 then c2 else c))
      : program)

let primitive_run =
  primitive "run" (tprogram @> tcanvas) (fun x -> GeomLib.Plumbing.relist (GeomLib.Plumbing.run x))

let primitive_just = primitive "just" (t0 @> tmaybe t0) (fun x -> Some x)
let primitive_nothing = primitive "nothing" (tmaybe t0) None
let primitive_nop = primitive "nop" tprogram GeomLib.Plumbing.nop
let primitive_nop2 = primitive "nop2" tprogram GeomLib.Plumbing.nop
let primitive_embed = primitive "embed" (tprogram @> tprogram) GeomLib.Plumbing.embed

(* let primitive_concat = primitive "concat" (tprogram @> tprogram @> tprogram) GeomLib.Plumbing.concat *)
let primitive_turn = primitive "turn" (tmaybe tvar @> tprogram) GeomLib.Plumbing.turn
let primitive_define = primitive "define" (tvar @> tprogram) GeomLib.Plumbing.define

(* let primitive_repeat =
   primitive "repeat" (tmaybe tvar @> tprogram @> tprogram) GeomLib.Plumbing.repeat *)

let primitive_line = primitive "basic_line" tprogram GeomLib.Plumbing.basic_line

let primitive_integrate =
  primitive "integrate"
    (tmaybe tvar @> tboolean (*tmaybe tvar @> tmaybe tvar  @>*) @> tmaybe tvar
    @> tmaybe tvar @> tprogram)
    GeomLib.Plumbing.integrate

let var_unit = primitive "var_unit" tvar GeomLib.Plumbing.var_unit
let var_two = primitive "var_two" tvar GeomLib.Plumbing.var_two
let var_three = primitive "var_three" tvar GeomLib.Plumbing.var_three
let var_double = primitive "var_double" (tvar @> tvar) GeomLib.Plumbing.var_double
let var_half = primitive "var_half" (tvar @> tvar) GeomLib.Plumbing.var_half
let var_next = primitive "var_next" (tvar @> tvar) GeomLib.Plumbing.var_next
let var_prev = primitive "var_prev" (tvar @> tvar) GeomLib.Plumbing.var_prev
let var_opposite = primitive "var_opposite" (tvar @> tvar) GeomLib.Plumbing.var_opposite
let var_divide = primitive "var_divide" (tvar @> tvar @> tvar) GeomLib.Plumbing.var_divide
let var_name = primitive "var_name" tvar GeomLib.Plumbing.var_name

(* LOGO *)
let logo_RT = primitive "logo_RT" (tangle @> turtle) LogoLib.LogoInterpreter.logo_RT
let logo_FW = primitive "logo_FW" (tlength @> turtle) LogoLib.LogoInterpreter.logo_FW
let logo_SEQ = primitive "logo_SEQ" (turtle @> turtle @> turtle) LogoLib.LogoInterpreter.logo_SEQ

let logo_FWRT =
  primitive "logo_FWRT"
    (tlength @> tangle @> turtle @> turtle)
    (fun x y z ->
      LogoLib.LogoInterpreter.logo_SEQ
        (LogoLib.LogoInterpreter.logo_SEQ
           (LogoLib.LogoInterpreter.logo_FW x)
           (LogoLib.LogoInterpreter.logo_RT y))
        z)

let logo_PU =
  primitive "logo_PU" (turtle @> turtle) (fun x ->
      LogoLib.LogoInterpreter.logo_SEQ LogoLib.LogoInterpreter.logo_PU x)

let logo_PD =
  primitive "logo_PD" (turtle @> turtle) (fun x ->
      LogoLib.LogoInterpreter.logo_SEQ LogoLib.LogoInterpreter.logo_PD x)

let logo_PT =
  primitive "logo_PT"
    ((turtle @> turtle) @> turtle @> turtle)
    (fun body continuation ->
      LogoLib.LogoInterpreter.logo_GET (fun state ->
          let original_state = state.p in
          LogoLib.LogoInterpreter.logo_SEQ LogoLib.LogoInterpreter.logo_PU
            (body
               (LogoLib.LogoInterpreter.logo_SEQ
                  (if original_state then LogoLib.LogoInterpreter.logo_PD
                  else LogoLib.LogoInterpreter.logo_PU)
                  continuation))))

let logo_GET =
  primitive "logo_GET" (tstate @> turtle @> turtle) (fun f -> LogoLib.LogoInterpreter.logo_GET f)

let logo_SET =
  primitive "logo_SET"
    (tstate @> turtle @> turtle)
    (fun s z -> LogoLib.LogoInterpreter.logo_SEQ (LogoLib.LogoInterpreter.logo_SET s) z)

let logo_GETSET =
  primitive "logo_GETSET"
    ((turtle @> turtle) @> turtle @> turtle)
    (fun t z ->
      LogoLib.LogoInterpreter.logo_GET (fun s ->
          t (LogoLib.LogoInterpreter.logo_SEQ (LogoLib.LogoInterpreter.logo_SET s) z)))

(* let logo_GETSET = primitive "logo_GETSET" *)
(*                             (turtle @> turtle @> turtle) *)
(*                             (fun t -> fun k -> *)
(*                               (LogoLib.LogoInterpreter.logo_GET *)
(*                                 (fun s -> *)
(*                                   (LogoLib.LogoInterpreter.logo_SEQ *)
(*                                     t *)
(*                                     (LogoLib.LogoInterpreter.logo_SEQ *)
(*                                       (LogoLib.LogoInterpreter.logo_SET s) *)
(*                                       k) *)
(*                                     ) *)
(*                                 ) *)
(*                               ) *)
(*                             ) *)

let logo_UA = primitive "logo_UA" tangle 1.
let logo_UL = primitive "logo_UL" tlength 1.
let logo_ZA = primitive "logo_ZA" tangle 0.
let logo_ZL = primitive "logo_ZL" tlength 0.
let logo_IFTY = primitive "logo_IFTY" tint 20
let logo_epsL = primitive "logo_epsL" tlength 0.05
let logo_epsA = primitive "logo_epsA" tangle 0.025

let line =
  primitive "line" (turtle @> turtle) (fun z ->
      LogoLib.LogoInterpreter.logo_SEQ
        (LogoLib.LogoInterpreter.logo_SEQ
           (LogoLib.LogoInterpreter.logo_FW 1.)
           (LogoLib.LogoInterpreter.logo_RT 0.))
        z)

let logo_DIVA = primitive "logo_DIVA" (tangle @> tint @> tangle) (fun a b -> a /. float_of_int b)
let logo_MULA = primitive "logo_MULA" (tangle @> tint @> tangle) (fun a b -> a *. float_of_int b)
let logo_DIVL = primitive "logo_DIVL" (tlength @> tint @> tlength) (fun a b -> a /. float_of_int b)
let logo_MULL = primitive "logo_MULL" (tlength @> tint @> tlength) (fun a b -> a *. float_of_int b)
let logo_ADDA = primitive "logo_ADDA" (tangle @> tangle @> tangle) ( +. )
let logo_SUBA = primitive "logo_SUBA" (tangle @> tangle @> tangle) ( -. )
let logo_ADDL = primitive "logo_ADDL" (tlength @> tlength @> tlength) ( +. )
let logo_SUBL = primitive "logo_SUBL" (tlength @> tlength @> tlength) ( -. )

let (_ : program) =
  primitive "logo_forLoop"
    (tint @> (tint @> turtle @> turtle) @> turtle @> turtle)
    (fun i f z -> List.fold_right (0 -- (i - 1)) ~f ~init:z)

let (_ : program) =
  primitive "logo_forLoopM"
    (tint @> (tint @> turtle) @> turtle @> turtle)
    (fun n body k0 ->
      List.map (0 -- (n - 1)) ~f:body
      |> List.fold_right ~f:LogoLib.LogoInterpreter.logo_SEQ ~init:k0)

(*let logo_CHEAT  = primitive "logo_CHEAT"             (ttvar @> turtle) LogoLib.LogoInterpreter.logo_CHEAT*)
(*let logo_CHEAT2  = primitive "logo_CHEAT2"             (ttvar @> turtle) LogoLib.LogoInterpreter.logo_CHEAT2*)
(*let logo_CHEAT3  = primitive "logo_CHEAT3"             (ttvar @> turtle) LogoLib.LogoInterpreter.logo_CHEAT3*)
(*let logo_CHEAT4  = primitive "logo_CHEAT4"             (ttvar @> turtle) LogoLib.LogoInterpreter.logo_CHEAT4*)

(* let default_recursion_limit = 20;; *)

let rec unfold x p h n = if p x then [] else h x :: unfold (n x) p h n

let primitive_unfold =
  primitive "unfold" (t0 @> (t0 @> tboolean) @> (t0 @> t1) @> (t0 @> t0) @> tlist t1) unfold

let primitive_index = primitive "index" (tint @> tlist t0 @> t0) (fun j l -> List.nth_exn l j)

let primitive_zip =
  primitive "zip"
    (tlist t0 @> tlist t1 @> (t0 @> t1 @> t2) @> tlist t2)
    (fun x y f -> List.map2_exn x y ~f)

let primitive_fold =
  primitive "fold"
    (tlist t0 @> t1 @> (t0 @> t1 @> t1) @> t1)
    (fun l x0 f -> List.fold_right ~f ~init:x0 l)

let default_recursion_limit = ref 50
let set_recursion_limit l = default_recursion_limit := l

exception RecursionDepthExceeded of int

let fixed_combinator argument body =
  (* strict with respect to body but lazy with respect argument *)
  (* body expects to be passed 2 thunks *)
  let body = Lazy.force body in
  let recursion_limit = ref !default_recursion_limit in

  let rec fix x =
    (* r is just a wrapper over fix that counts the number of
       recursions *)
    let r z =
      decr recursion_limit;
      if !recursion_limit > 0 then fix z
      else raise (RecursionDepthExceeded !default_recursion_limit)
    in
    body (lazy r) x
  in

  fix argument

let fixed_combinator2 argument1 argument2 body =
  let body = Lazy.force body in
  let recursion_limit = ref !default_recursion_limit in

  let rec fix x y =
    let r a b =
      decr recursion_limit;
      if !recursion_limit > 0 then fix a b
      else raise (RecursionDepthExceeded !default_recursion_limit)
    in
    body (lazy r) x y
  in

  fix argument1 argument2
(* (lazy argument1) (lazy argument2) *)

let primitive_recursion =
  primitive ~manualLaziness:true "fix1" (t0 @> ((t0 @> t1) @> t0 @> t1) @> t1) fixed_combinator

let primitive_recursion2 =
  primitive ~manualLaziness:true "fix2"
    (t0 @> t1 @> ((t0 @> t1 @> t2) @> t0 @> t1 @> t2) @> t2)
    fixed_combinator2

let is_recursion_of_arity a t =
  let open String in
  match t with Primitive (_, n, _) -> "fix" ^ Int.to_string a = n | _ -> false

let is_recursion_primitive = function
  | Primitive (_, "fix1", _) -> true
  | Primitive (_, "fix2", _) -> true
  | _ -> false

let program_parser : program parsing =
  let token =
    token_parser (fun c ->
        Char.is_alphanum c
        || List.mem ~equal:Char.( = )
             [ '_'; '-'; '?'; '/'; '.'; '*'; '\''; '+'; ','; '>'; '<'; '@'; '|' ]
             c)
  in
  let whitespace = token_parser ~can_be_empty:true Char.is_whitespace in
  let number = token_parser Char.is_digit in
  let primitive =
    token %% fun name ->
    try return_parse (lookup_primitive name)
    with _ ->
      (*         Printf.printf "Error finding type of primitive %s\n" name; *)
      parse_failure
  in
  let variable : program parsing =
    constant_parser "$" %% fun _ ->
    number %% fun n -> Index (Int.of_string n) |> return_parse
  in
  let var_name =
    constant_parser "$" %% fun _ ->
    token_parser Char.is_alphanum %% fun n ->
    try
      let (_ : int) = Int.of_string n in
      parse_failure
    with _ -> n |> return_parse
  in
  let free_variable : program parsing = var_name %% fun n -> FreeVar n |> return_parse in

  let fixed_real : program parsing =
    constant_parser "real" %% fun _ ->
    token %% fun v ->
    let v = v |> Float.of_string in
    Primitive (treal, "real", ref (v |> magical)) |> return_parse
  in

  let obj_parser : string parsing =
   fun (s, n) ->
    let rec check consumed depth =
      let k = n + consumed in
      if k >= String.length s then []
      else if depth = 0 && (Char.( = ) s.[k] ')' || Char.( = ) s.[k] ',') then []
      else if Char.( = ) s.[k] '(' then s.[k] :: check (consumed + 1) (depth + 1)
      else if Char.( = ) s.[k] ')' then s.[k] :: check (consumed + 1) (depth - 1)
      else s.[k] :: check (consumed + 1) depth
    in
    let token = check 0 0 in
    if List.length token = 0 then []
    else
      let token = String.concat ~sep:"" (token |> List.map ~f:(String.make 1)) in
      [ (token, n + String.length token) ]
  in

  let rec program_parser () : program parsing =
    application () <|> primitive <|> variable <|> free_variable <|> invented () <|> abstraction ()
    <|> fixed_real <|> let_clause () <|> let_rev_clause () <|> const_clause <|> wrap_either ()
  and invented () =
    constant_parser "#" %% fun _ ->
    program_parser () %% fun p ->
    let t =
      try infer_program_type empty_context [] p |> snd
      with UnificationFailure | UnboundVariable ->
        (* Printf.eprintf "WARNING: Could not type check invented %s\n" (string_of_program p); *)
        t0
    in
    return_parse (Invented (t, p))
  and abstraction () =
    let rec nabstractions n b = if n = 0 then b else nabstractions (n - 1) (Abstraction b) in
    constant_parser "(lambda" %% fun _ ->
    ( whitespace %% fun _ ->
      program_parser () %% fun b ->
      constant_parser ")" %% fun _ -> return_parse (Abstraction b) )
    <|> number %% fun n ->
        whitespace %% fun _ ->
        program_parser () %% fun b ->
        constant_parser ")" %% fun _ -> return_parse (nabstractions (Int.of_string n) b)
  and application_sequence (maybe_function : program option) : program parsing =
    whitespace %% fun _ ->
    match maybe_function with
    | None ->
        (* cannot terminate sequence because there is nothing before it *)
        program_parser () %% fun f -> application_sequence (Some f)
    | Some f ->
        return_parse f <|> program_parser () %% fun x -> application_sequence (Some (Apply (f, x)))
  and application () =
    constant_parser "(" %% fun _ ->
    application_sequence None %% fun a ->
    constant_parser ")" %% fun _ -> return_parse a
  and var_name_list () : string list parsing =
    var_name %% fun v ->
    ( constant_parser "," %% fun _ ->
      whitespace %% fun _ ->
      var_name_list () %% fun vs -> return_parse (v :: vs) )
    <|> whitespace %% fun _ ->
        constant_parser "=" %% fun _ -> return_parse [ v ]
  and let_clause () : program parsing =
    constant_parser "let" %% fun _ ->
    whitespace %% fun _ ->
    var_name %% fun v ->
    whitespace %% fun _ ->
    constant_parser "=" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun d ->
    whitespace %% fun _ ->
    constant_parser "in" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun b -> return_parse (LetClause (v, d, b))
  and let_rev_clause () : program parsing =
    constant_parser "let" %% fun _ ->
    whitespace %% fun _ ->
    var_name_list () %% fun vs ->
    whitespace %% fun _ ->
    constant_parser "rev(" %% fun _ ->
    var_name %% fun inp ->
    whitespace %% fun _ ->
    constant_parser "=" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun d ->
    constant_parser ")" %% fun _ ->
    whitespace %% fun _ ->
    constant_parser "in" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun b -> return_parse (LetRevClause (vs, inp, d, b))
  and const_clause =
    constant_parser "Const(" %% fun _ ->
    obj_parser %% fun t ->
    constant_parser "," %% fun _ ->
    whitespace %% fun _ ->
    obj_parser %% fun n ->
    constant_parser ")" %% fun _ -> return_parse (Const (get_some (type_of_string t), n))
  and wrap_either () : program parsing =
    constant_parser "let" %% fun _ ->
    whitespace %% fun _ ->
    var_name_list () %% fun vs ->
    whitespace %% fun _ ->
    constant_parser "wrap(let" %% fun _ ->
    whitespace %% fun _ ->
    var_name_list () %% fun _ ->
    whitespace %% fun _ ->
    constant_parser "rev(" %% fun _ ->
    var_name %% fun inp ->
    whitespace %% fun _ ->
    constant_parser "=" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun d ->
    constant_parser ");" %% fun _ ->
    whitespace %% fun _ ->
    constant_parser "let" %% fun _ ->
    whitespace %% fun _ ->
    var_name %% fun fixer ->
    whitespace %% fun _ ->
    constant_parser "=" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun f ->
    constant_parser ")" %% fun _ ->
    whitespace %% fun _ ->
    constant_parser "in" %% fun _ ->
    whitespace %% fun _ ->
    program_parser () %% fun b -> return_parse (WrapEither (vs, inp, fixer, d, f, b))
  in

  program_parser ()

let parse_program s = run_parser program_parser s

let test_program_inference program desired_type =
  let context, t = infer_program_type empty_context [] program in
  let _, t = applyContext context t in
  let t = canonical_type t in
  (* Printf.printf "%s : %s\n" (string_of_program program) (string_of_type t); *)
  tp_eq t (canonical_type desired_type)

let%test _ = test_program_inference (Abstraction (Index 0)) (t0 @> t0)

let%test _ =
  test_program_inference
    (Abstraction (Abstraction (Apply (Index 0, Index 1))))
    (t0 @> (t0 @> t1) @> t1)

let%test _ = test_program_inference (Abstraction (Abstraction (Index 1))) (t0 @> t1 @> t0)
let%test _ = test_program_inference (Abstraction (Abstraction (Index 0))) (t0 @> t1 @> t1)

let%test _ =
  evaluate [] (Hashtbl.create (module String)) (Apply (primitive_increment, primitive0)) = 1

let parsing_test_case s =
  let po = parse_program s in
  match po with None -> false | Some p -> String.( = ) s (string_of_program p)

let%test _ = parsing_test_case "(+ 1)"
let%test _ = parsing_test_case "($0 $1)"
let%test _ = parsing_test_case "(+ 1 $0 $2)"
let%test _ = parsing_test_case "(map (+ 1) $0 $1)"
let%test _ = parsing_test_case "(map (+ 1) ($0 (+ 1) (- 1) (+ -)) $1)"
let%test _ = parsing_test_case "(lambda $0)"
let%test _ = parsing_test_case "(lambda (+ 1 #(* 8 1)))"
let%test _ = parsing_test_case "(lambda (+ 1 #(* 8 map)))"
let%test _ = parsing_test_case "let $v1 = 1 in $v1"

let%test _ =
  parsing_test_case
    "(lambda let $v1 = (cdr $0) in let $v2 = (eq? $0 $v1) in let $v3 = (eq? $0 $0) in (eq? $v2 \
     $v3))"

let%test _ =
  parsing_test_case
    "let $v1 = Const(list(int), Any[]) in let $v2 = Const(list(int), Any[0]) in let $v3 = (concat \
     $v1 $v2) in (concat $inp0 $v3)"

let%test _ =
  parsing_test_case
    "let $v1 = Const(list(int), Any[5]) in let $v2 = Const(list(int), Any[]) in let $v3, $v4 = \
     wrap(let $v3, $v4 = rev($inp0 = (concat $v3 $v4)); let $v3 = $v2) in (concat $v1 $v4)"

(* let%test _ = parsing_test_case "(cons FREE_VAR FREE_VAR)"
   let%test _ = parsing_test_case "rev((cons FREE_VAR FREE_VAR), [$0])"
   let%test _ = parsing_test_case "rev((cons FREE_VAR FREE_VAR), [$v1])"
   let%test _ = parsing_test_case "(lambda let $v1, $v2 = rev($0 = (cons $v1 $v2)) in $v2)" *)

let[@warning "-20"] performance_test_case () =
  let e =
    parse_program
      "(lambda (fix1 $0 (lambda (lambda (if (empty? $0) $0 (cons (* 2 (car $0)) ($1 (cdr $0))))))))"
    |> get_some
  in
  let xs = [ 2; 1; 9; 3 ] in
  let n = 10000000 in
  time_it "evaluate program many times" (fun () ->
      0 -- n
      |> List.iter ~f:(fun j ->
             if j = n then
               Printf.printf "%s\n"
                 (evaluate [] (Hashtbl.create (module String)) e xs
                 |> List.map ~f:Int.to_string |> join ~separator:" ")
             else ignore (evaluate [] (Hashtbl.create (module String)) e xs : unit)));
  let c = analyze_evaluation e [] (Hashtbl.create (module String)) in
  time_it "evaluate analyzed program many times" (fun () ->
      0 -- n
      |> List.iter ~f:(fun j ->
             if j = n then
               Printf.printf "%s\n" (c xs |> List.map ~f:Int.to_string |> join ~separator:" ")
             else ignore (c xs : unit)))

(* performance_test_case();; *)

(* let recursion_test_case() =
 *   let f zs = fixed_combinator zs (fun r l ->
 *       match l with
 *       | [] -> []
 *       | x::xs -> x*2 :: r xs) in
 *   f (0--18) |> List.map ~f:Int.to_string |> join ~separator:" " |> Printf.printf "%s\n";
 *   f (0--10) |> List.map ~f:Int.to_string |> join ~separator:" " |> Printf.printf "%s\n";
 *   f (0--2) |> List.map ~f:Int.to_string |> join ~separator:" " |> Printf.printf "%s\n";
 *   let e = parse_program "(lambda (fix1 (lambda (lambda (if (empty? $0) $0 (cons (\* 2 (car $0)) ($1 (cdr $0)))))) $0))" |> get_some in
 *   Printf.printf "%s\n" (string_of_program e);
 *   evaluate [] e [1;2;3;4;] |> List.map ~f:Int.to_string |> join ~separator:" " |> Printf.printf "%s\n";
 *
 *   let e = parse_program "(lambda (lambda (fix2 (lambda (lambda (lambda (if (empty? $1) $0 (cons (car $1) ($2 (cdr $1) $0)))))) $0 $1)))" |> get_some in
 *   infer_program_type empty_context [] e |> snd |> string_of_type |> Printf.printf "%s\n";
 *   evaluate [] e (0--4) [9;42;1] |> List.map ~f:Int.to_string |> join ~separator:" " |> Printf.printf "%s\n" *)

(* recursion_test_case();; *)

(* let timeout_test_cases() = *)
(*   let list_of_numbers = [ *)
(*     "(lambda (fix (lambda (lambda (if (empty? $0) $0 (cons (\* 2 (car $0)) ($1 (cdr $0)))))) $0))"; *)

(*   ] in *)

(*   let list_of_numbers = list_of_numbers |> List.map ~f:(analyze_evaluation%get_some%parse_program) in *)

(*   let xs = [(0--10);(0--10);(0--10)] in *)

(*   time_it "evaluated all of the programs" (fun () -> *)

(* let () = *)
(*   let e = parse_program "(lambda (reducei (lambda (lambda (lambda (range $0)))) empty $0))" |> get_some in *)
(*   Printf.printf "tp = %s\n" (string_of_type @@ snd @@ infer_program_type empty_context [] e); *)
(*   let f = evaluate [] e in *)
(*   f [1;2]; *)
(*   List.foldi [1;3;2;]  ~init:[]  ~f:(fun x y z -> 0--z) |> List.iter ~f:(fun a -> *)
(*       Printf.printf "%d\n" a) *)

(* let () = *)
(*   let e = parse_program "(lambda (lambda (- $1 $0)))" |> get_some in *)
(*   Printf.printf "%d\n" (run_with_arguments e [1;9]) *)
let test_lazy_evaluation () =
  let ps =
    [
      "1";
      "0";
      "(+ 1 1)";
      "(lambda (+ $0 2))";
      "(+ 5)";
      "-";
      "(lambda2 (- $0 $1))";
      "((lambda 1) (car empty))";
      "((lambda $0) 9)";
      "((lambda ($0 ($0 ($0 1)))) (lambda (+ $0 $0)))";
      "((lambda (lambda (if (eq? $0 0) $1 (+ $1 $1)))) 5 1)";
      "((lambda2 (if (eq? $0 0) $1 (+ $1 $1))) 5 0)";
      "(car (cdr (cons 1 (cons 2 (cons 3 empty)))))";
      "(cdr (cons 1 (cons 2 (cons 3 empty))))";
      "(map (+ 1) (cons 1 (cons 2 (cons 3 empty))))";
      "(map (+ 1) (cons 1 (cons 2 (cons 3 empty))))";
      "(map (lambda (+ $0 $0)) (cons 1 (cons 2 (cons 3 empty))))";
      "(fold_right (lambda2 (+ $0 $1)) 0 (cons 1 (cons 2 (cons 3 empty))))";
      "(fix1 (cons 1 (cons 2 (cons 3 empty))) (lambda2 (if (empty? $0) 0 (+ 1 ($1 (cdr $0))))))";
      "(fix1 (cons 1 (cons 2 (cons 3 empty))) (lambda2 (if (empty? $0) 0 (+ (car $0) ($1 (cdr \
       $0))))))";
      "(fix2 5 7 (lambda (lambda (lambda (if (eq? $0 0) 0 (+ $1 ($2 $1 (- $0 1))))))))";
    ]
  in
  ps
  |> List.iter ~f:(fun p ->
         Printf.printf "About to evaluate the following program lazily: %s\n" p;
         flush_everything ();
         let p = parse_program p |> get_some in
         let t = infer_program_type empty_context [] p |> snd in
         let a = analyze_lazy_evaluation p in
         let arguments =
           match List.length (arguments_of_type t) with
           | 0 -> []
           | 1 -> [ 42 ]
           | 2 -> [ 0; 1 ]
           | _ -> failwith "I can't handle this number of arguments (?)."
         in
         Printf.printf "\t(arguments: %s)\n"
           (arguments |> List.map ~f:Int.to_string |> join ~separator:"; ");
         flush_everything ();
         let v = run_lazy_analyzed_with_arguments a arguments in
         (match string_of_type (return_of_type t) with
         | "int" -> Printf.printf "value = %d\n" (v |> magical)
         | "list<int>" ->
             Printf.printf "value = %s\n"
               (v |> magical |> List.map ~f:Int.to_string |> join ~separator:",")
         | _ -> failwith "I am not prepared to handle other types");
         flush_everything ())

let test_string () =
  let p =
    parse_program "(lambda (fold $0 $0 (lambda (lambda (cdr (if (char-eq? $1 SPACE) $2 $0))))))"
    |> get_some
  in
  let p = analyze_lazy_evaluation p in
  let x = String.to_list "this is a rigorous" in
  let y = run_lazy_analyzed_with_arguments p [ x ] |> String.of_char_list in
  Printf.printf "%s\n" y

let test_zip_recursion () =
  let p =
    parse_program
      "(lambda (lambda (#(lambda (lambda (#(lambda (lambda (lambda (fix1 $2 (lambda (lambda (if \
       (empty? $0) $2 ($3 ($1 (cdr $0)) (car $0))))))))) $0 (lambda (lambda (cons ($3 $0) $1))) \
       empty))) (lambda (+ (#(lambda (lambda (car (#(lambda (lambda (lambda (fix1 $2 (lambda \
       (lambda (if (empty? $0) $2 ($3 ($1 (cdr $0)) (car $0))))))))) (#(#(lambda (lambda (lambda \
       (#(lambda (lambda (lambda (lambda (fix1 $3 (lambda (lambda (if ($2 $0) empty (cons ($3 $0) \
       ($1 ($4 $0))))))))))) $1 (lambda ($3 $0 1)) (lambda $0) (lambda (eq? $0 $1)))))) (lambda \
       (lambda (+ $1 $0))) 0) $1) (lambda (lambda (cdr $1))) $0)))) $0 $2) (#(lambda (lambda (car \
       (#(lambda (lambda (lambda (fix1 $2 (lambda (lambda (if (empty? $0) $2 ($3 ($1 (cdr $0)) \
       (car $0))))))))) (#(#(lambda (lambda (lambda (#(lambda (lambda (lambda (lambda (fix1 $3 \
       (lambda (lambda (if ($2 $0) empty (cons ($3 $0) ($1 ($4 $0))))))))))) $1 (lambda ($3 $0 1)) \
       (lambda $0) (lambda (eq? $0 $1)))))) (lambda (lambda (+ $1 $0))) 0) $1) (lambda (lambda \
       (cdr $1))) $0)))) $0 $1))) (#(#(lambda (lambda (lambda (#(lambda (lambda (lambda (lambda \
       (fix1 $3 (lambda (lambda (if ($2 $0) empty (cons ($3 $0) ($1 ($4 $0))))))))))) $1 (lambda \
       ($3 $0 1)) (lambda $0) (lambda (eq? $0 $1)))))) (lambda (lambda (+ $1 $0))) 0) (#(lambda \
       (#(lambda (lambda (lambda (fix1 $2 (lambda (lambda (if (empty? $0) $2 ($3 ($1 (cdr $0)) \
       (car $0))))))))) $0 (lambda (lambda (+ 1 $1))) 0)) $0)))))"
    |> get_some
  in
  let p = analyze_lazy_evaluation p in
  run_lazy_analyzed_with_arguments p [ [ 1; 2; 3 ]; [ 0; 4; 6 ] ]
  |> List.map ~f:Int.to_string |> String.concat ~sep:"; " |> Printf.printf "%s\n"

(* test_zip_recursion();; *)

(* Puddleworld primitive and type definitions for compression namespace purposes. Function definitions are irrelevant.*)
(* Puddleworld Type Definitions *)
let t_object_p = make_ground "t_object_p"
let t_boolean_p = make_ground "t_boolean_p"
let t_action_p = make_ground "t_action_p"
let t_direction_p = make_ground "t_direction_p"
let t_int_p = make_ground "t_int_p"
let t_model_p = make_ground "t_model_p"

(* Puddleworld Primitive Definitions *)

let (_ : unit) =
  ignore (primitive "true_p" t_boolean_p (fun x -> x) : program);
  ignore (primitive "left_p" t_direction_p (fun x -> x) : program);
  ignore (primitive "right_p" t_direction_p (fun x -> x) : program);
  ignore (primitive "up_p" t_direction_p (fun x -> x) : program);
  ignore (primitive "down_p" t_direction_p (fun x -> x) : program);
  ignore (primitive "1_p" t_int_p (fun x -> x) : program);
  ignore (primitive "2_p" t_int_p (fun x -> x) : program);
  ignore (primitive "move_p" (t_object_p @> t_action_p) (fun x -> x) : program);
  ignore
    (primitive "relate_p" (t_object_p @> t_object_p @> t_direction_p @> t_boolean_p) (fun x -> x)
      : program);
  ignore
    (primitive "relate_n_p"
       (t_object_p @> t_object_p @> t_direction_p @> t_int_p @> t_boolean_p)
       (fun x -> x)
      : program);
  ignore (primitive "in_half_p" (t_object_p @> t_direction_p @> t_boolean_p) (fun x -> x) : program);
  ignore
    (primitive "apply_p" ((t_object_p @> t_boolean_p) @> t_object_p @> t_boolean_p) (fun x -> x)
      : program);
  ignore (primitive "and__p" (t_boolean_p @> t_boolean_p @> t_boolean_p) (fun x -> x) : program);
  ignore
    (primitive "max_in_dir_p" (t_object_p @> t_direction_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "is_edge_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "grass_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "puddle_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "star_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "circle_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "triangle_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "heart_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "spade_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "diamond_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "rock_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "tree_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "house_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore (primitive "horse_p" (t_object_p @> t_boolean_p) (fun x -> x) : program);
  ignore
    (primitive "ec_unique_p" (t_model_p @> (t_object_p @> t_boolean_p) @> t_object_p) (fun x -> x)
      : program)
