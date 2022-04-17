open Core
open Program
open Utils
open Type

module Hashtbl = struct
  include Base.Hashtbl

  let pp pp_key pp_value ppf values =
    Hashtbl.iteri values ~f:(fun ~key ~data ->
        Format.fprintf ppf "@[<1>%a: %a@]@." pp_key key pp_value data)
end

type vs =
  | Union of int list
  | ApplySpace of int * int
  | AbstractSpace of int
  | IndexSpace of int
  | TerminalSpace of program
      [@printer fun fmt p -> Format.fprintf fmt "(TerminalSpace %s)" (string_of_program p)]
  | LetSpace of int * int
  | LetRevSpace of int * int * int * int
  | VarIndexSpace of int
  | Universe
  | Void
[@@deriving equal, show]

type vt = {
  universe : int;
  void : int;
  s2i : (vs, int) Hashtbl.t;
  i2s : vs ra;
  (* dynamic programming *)
  recursive_inversion_table : int option ra;
  n_step_table : (int * int, int) Hashtbl.t;
  substitution_table : (int * int, (int, int) Hashtbl.t) Hashtbl.t;
}
[@@deriving show]

let index_table t index = get_resizable t.i2s index
let version_table_size t = t.i2s.ra_occupancy

let clear_dynamic_programming_tables { n_step_table; substitution_table; _ } =
  Hashtbl.clear n_step_table;
  Hashtbl.clear substitution_table

let deallocate_versions v =
  clear_dynamic_programming_tables v;
  Hashtbl.clear v.s2i;
  clear_resizable v.i2s;
  clear_resizable v.recursive_inversion_table

let rec string_of_versions t j =
  match index_table t j with
  | Universe -> "U"
  | Void -> "Void"
  | ApplySpace (f, x) ->
      Printf.sprintf "@(%s, %s)" (string_of_versions t f) (string_of_versions t x)
  | AbstractSpace b -> Printf.sprintf "abs(%s)" (string_of_versions t b)
  | IndexSpace i -> Printf.sprintf "$%d" i
  | TerminalSpace p -> string_of_program p
  | Union u ->
      Printf.sprintf "{%s}" (u |> List.map ~f:(string_of_versions t) |> join ~separator:"; ")
  | LetSpace (d, b) ->
      Printf.sprintf "let %s in %s" (string_of_versions t d) (string_of_versions t b)
  | LetRevSpace (_, v, d, b) ->
      Printf.sprintf "let rev(%s = %s) in %s" (string_of_versions t v) (string_of_versions t d)
        (string_of_versions t b)
  | VarIndexSpace n -> Printf.sprintf "$v%d" n

let incorporate_space t v : int =
  match Hashtbl.find t.s2i v with
  | Some i -> i
  | None ->
      let i = t.i2s.ra_occupancy in
      Hashtbl.set t.s2i ~key:v ~data:i;
      push_resizable t.i2s v;
      push_resizable t.recursive_inversion_table None;
      (* push_resizable t.equivalence_class (union_find_node i); *)
      i

let new_version_table () : vt =
  let t =
    {
      void = 0;
      universe = 1;
      s2i = Hashtbl.Poly.create ();
      i2s = empty_resizable ();
      (* equivalence_class=empty_resizable(); *)
      substitution_table = Hashtbl.Poly.create ();
      n_step_table = Hashtbl.Poly.create ();
      recursive_inversion_table = empty_resizable ();
    }
  in
  assert (incorporate_space t Void = t.void);
  assert (incorporate_space t Universe = t.universe);
  t

let version_apply t f x =
  if f = t.void || x = t.void then t.void else incorporate_space t (ApplySpace (f, x))

let version_abstract t b = if b = t.void then t.void else incorporate_space t (AbstractSpace b)
let version_index t i = incorporate_space t (IndexSpace i)
let version_terminal t e = incorporate_space t (TerminalSpace e)

let version_let t d b =
  if d = t.void || b = t.void then t.void else incorporate_space t (LetSpace (d, b))

let version_let_rev t vc v d b =
  if d = t.void || b = t.void || v = t.void then t.void
  else incorporate_space t (LetRevSpace (vc, v, d, b))

let version_var t n = incorporate_space t (VarIndexSpace n)

let union t vs =
  if List.mem vs t.universe ~equal:( = ) then t.universe
  else
    let vs =
      vs
      |> List.concat_map ~f:(fun v ->
             match index_table t v with
             | Union stuff -> stuff
             | Void -> []
             | Universe -> assert false
             | _ -> [ v ])
      |> List.dedup_and_sort ~compare:( - )
    in
    match vs with [] -> t.void | [ v ] -> v | _ -> incorporate_space t (Union vs)

let rec incorporate' t vars e =
  match e with
  | Index i -> version_index t i
  | Abstraction b -> version_abstract t (incorporate' t vars b)
  | Apply (f, x) -> version_apply t (incorporate' t vars f) (incorporate' t vars x)
  | Primitive (_, _, _) | Invented (_, _) | Const _ -> version_terminal t (strip_primitives e)
  | LetClause (var_name, d, b) ->
      version_let t (incorporate' t vars d) (incorporate' t (var_name :: vars) b)
  | LetRevClause (var_names, inp_var_name, d, b) ->
      version_let_rev t (List.length var_names)
        (incorporate' t vars (FreeVar inp_var_name))
        (incorporate' t (List.append (List.rev var_names) vars) d)
        (incorporate' t (List.append (List.rev var_names) vars) b)
  | FreeVar n -> version_var t (fst (get_some (List.findi vars ~f:(fun _ x -> String.( = ) x n))))

let incorporate t r e =
  match r with
  | TCon (_, _, _) -> incorporate' t [] e
  | TNCon (_, args, _, _) -> incorporate' t (List.rev_map args ~f:fst) e
  | TID _ -> incorporate' t [] e

let%test "test variables renaming" =
  let t = new_version_table () in
  let v1 =
    incorporate t
      (TNCon ("->", [ ("inp1", tint) ], tint, false))
      (get_some (parse_program "let $v1 = $inp1 in $v1"))
  in
  let v2 =
    incorporate t
      (TNCon ("->", [ ("inp1", tint) ], tint, false))
      (get_some (parse_program "let $v2 = $inp1 in $v2"))
  in
  v1 = v2

let%test _ =
  let t = new_version_table () in
  let v1 =
    incorporate t
      (TNCon ("->", [ ("inp0", tint) ], tint, false))
      (get_some (parse_program "(cdr $inp0)"))
  in
  v1 = 4

let%test _ =
  let t = new_version_table () in
  let v1 =
    incorporate t
      (TNCon ("->", [ ("inp0", tint) ], tint, false))
      (get_some (parse_program "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in $v2"))
  in
  v1 = 7

let%test _ =
  let t = new_version_table () in
  let v1 =
    incorporate t
      (TNCon ("->", [ ("inp0", tint) ], tint, false))
      (get_some (parse_program "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in $v2"))
  in
  let v2 =
    incorporate t
      (TNCon ("->", [ ("inp1", tint) ], tint, false))
      (get_some (parse_program "let $v3, $v2 = rev($inp1 = (cons $v3 $v2)) in $v2"))
  in
  v1 = v2

let rec extract t j =
  match index_table t j with
  | Union u -> List.concat_map u ~f:(extract t)
  | ApplySpace (f, x) ->
      extract t f
      |> List.concat_map ~f:(fun f' -> extract t x |> List.map ~f:(fun x' -> Apply (f', x')))
  | IndexSpace i -> [ Index i ]
  | Void -> []
  | TerminalSpace p -> [ p ]
  | AbstractSpace b -> extract t b |> List.map ~f:(fun b' -> Abstraction b')
  | Universe -> [ primitive "UNIVERSE" t0 () ]

let rec child_spaces t j =
  j
  ::
  (match index_table t j with
  | Union u -> List.map u ~f:(child_spaces t) |> List.concat
  | ApplySpace (f, x) -> child_spaces t f @ child_spaces t x
  | AbstractSpace b -> child_spaces t b
  | _ -> [])
  |> List.dedup_and_sort ~compare:( - )

let rec shift_free ?(c = 0) t ~n ~index =
  if n = 0 then index
  else
    match index_table t index with
    | Union indices -> union t (indices |> List.map ~f:(fun i -> shift_free ~c t ~n ~index:i))
    | IndexSpace i when i < c -> index (* below cut off - bound variable *)
    | IndexSpace i when i >= n + c -> version_index t (i - n) (* free variable *)
    | IndexSpace _ -> t.void
    | ApplySpace (f, x) ->
        version_apply t (shift_free ~c t ~n ~index:f) (shift_free ~c t ~n ~index:x)
    | AbstractSpace b -> version_abstract t (shift_free ~c:(c + 1) t ~n ~index:b)
    | TerminalSpace _ | Universe | Void -> index

let rec shift_versions ?(c = 0) t ~n ~index =
  (* shift_free_variables, lifted to vs *)
  if n = 0 then index
  else
    match index_table t index with
    | Union indices -> union t (indices |> List.map ~f:(fun i -> shift_versions ~c t ~n ~index:i))
    | IndexSpace i when i < c -> index (* below cut off - bound variable *)
    | IndexSpace i when i + n >= 0 -> version_index t (i + n) (* free variable *)
    | IndexSpace _ -> t.void
    | ApplySpace (f, x) ->
        version_apply t (shift_versions ~c t ~n ~index:f) (shift_versions ~c t ~n ~index:x)
    | AbstractSpace b -> version_abstract t (shift_versions ~c:(c + 1) t ~n ~index:b)
    | TerminalSpace _ | Universe | Void -> index

let rec subtract t a b =
  match (index_table t a, index_table t b) with
  | Universe, _ -> assert false
  | _, Universe -> assert false
  | Void, _ -> t.void
  | _, Void -> a
  | Union xs, _ -> xs |> List.map ~f:(fun x -> subtract t x b) |> union t
  | _, Union xs ->
      List.fold_right xs ~init:a ~f:(fun to_remove current -> subtract t current to_remove)
  | AbstractSpace b1, AbstractSpace b2 -> version_abstract t (subtract t b1 b2)
  | AbstractSpace _, _ -> a
  | ApplySpace (f1, x1), ApplySpace (f2, x2) ->
      union t [ version_apply t (subtract t f1 f2) x1; version_apply t f1 (subtract t x1 x2) ]
  | ApplySpace (_, _), _ -> a
  | IndexSpace i1, IndexSpace i2 when i1 = i2 -> t.void
  | IndexSpace _, _ -> a
  | TerminalSpace t1, TerminalSpace t2 when equal_program t1 t2 -> t.void
  | TerminalSpace _, _ -> a

let rec unique_space t a =
  match index_table t a with
  | Universe | Void | IndexSpace _ | TerminalSpace _ -> a
  | AbstractSpace b -> version_abstract t (unique_space t b)
  | ApplySpace (f, x) -> version_apply t (unique_space t f) (unique_space t x)
  | Union u ->
      List.fold_right u ~init:t.void ~f:(fun u' total ->
          union t [ total; subtract t (unique_space t u') total ])

let rec intersection t a b =
  match (index_table t a, index_table t b) with
  | Universe, _ -> b
  | _, Universe -> a
  | Void, _ | _, Void -> t.void
  | Union xs, Union ys ->
      xs |> List.concat_map ~f:(fun x -> ys |> List.map ~f:(fun y -> intersection t x y)) |> union t
  | Union xs, _ -> xs |> List.map ~f:(fun x -> intersection t x b) |> union t
  | _, Union xs -> xs |> List.map ~f:(fun x -> intersection t x a) |> union t
  | AbstractSpace b1, AbstractSpace b2 -> version_abstract t (intersection t b1 b2)
  | ApplySpace (f1, x1), ApplySpace (f2, x2) ->
      version_apply t (intersection t f1 f2) (intersection t x1 x2)
  | IndexSpace i1, IndexSpace i2 when i1 = i2 -> a
  | TerminalSpace t1, TerminalSpace t2 when equal_program t1 t2 -> a
  | _ -> t.void

let inline t j =
  (* Replaces (#(\ \... B) a1 a2 ... x y z) w/ B[n > a1][n - 1 > a2]... x y z *)
  (* Only performs this operation at the top level *)
  let rec il (arguments : int list) (j : int) : int =
    match index_table t j with
    | ApplySpace (f, x) -> il (x :: arguments) f
    | AbstractSpace _ | IndexSpace _ | TerminalSpace (Primitive (_, _, _)) -> t.void
    | Union vs -> vs |> List.map ~f:(il arguments) |> union t
    | TerminalSpace (Invented (_, body)) -> (
        let rec make_substitution used_arguments unused_arguments body =
          match (unused_arguments, body) with
          | [], Abstraction _ -> None
          | [], _ -> Some (used_arguments, body)
          | x :: xs, Abstraction b -> make_substitution (x :: used_arguments) xs b
          | _ :: _, _ -> Some (used_arguments, body)
        in
        let rec apply_substitution ~k arguments expression =
          match expression with
          | Index i when i < k -> version_index t i
          (* i >= k *)
          | Index i when i - k < List.length arguments ->
              shift_versions t ~n:k ~index:(List.nth_exn arguments (i - k))
          (* i >= k + |arguments| *)
          | Index i -> version_index t (i - List.length arguments)
          | Apply (f, x) ->
              version_apply t
                (apply_substitution ~k arguments f)
                (apply_substitution ~k arguments x)
          | Abstraction b -> version_abstract t (apply_substitution ~k:(k + 1) arguments b)
          | Primitive (_, _, _) | Invented (_, _) -> incorporate' t [] expression
        in
        match make_substitution [] arguments body with
        | None -> t.void
        | Some (used_arguments, body) ->
            let f = apply_substitution ~k:0 used_arguments body in
            let remaining_arguments = List.drop arguments (List.length used_arguments) in
            remaining_arguments |> List.fold_left ~init:f ~f:(version_apply t))
    | Void | Universe | TerminalSpace _
    | LetSpace (_, _)
    | LetRevSpace (_, _, _, _)
    | VarIndexSpace _ ->
        t.void
  in
  il [] j

let%expect_test _ =
  let t = new_version_table () in
  let p = "(#(lambda (lambda (* $2 (+ (lambda $2) $0)))) $0 2)" |> parse_program |> get_some in
  p |> incorporate' t [] |> inline t |> extract t
  |> List.iter ~f:(fun p' -> Printf.printf "%s\n" (string_of_program p'));
  [%expect {| (* $0 (+ (lambda $1) 2)) |}]

let rec recursive_inlining t j =
  (* Constructs vs of all programs that are 1 inlining step away from a program in provided vs *)
  match index_table t j with
  | Union u -> u |> List.map ~f:(recursive_inlining t) |> union t
  | AbstractSpace b -> version_abstract t (recursive_inlining t b)
  | IndexSpace _ | Void | Universe | TerminalSpace (Primitive _) -> t.void
  (* Must either be an application or an invented leaf *)
  | _ ->
      let top_linings = inline t j in
      let rec inline_arguments j =
        match index_table t j with
        | ApplySpace (f, x) -> version_apply t f (recursive_inlining t x)
        | Union u -> u |> List.map ~f:inline_arguments |> union t
        | AbstractSpace _ | TerminalSpace _ | Universe | Void | IndexSpace _ -> t.void
      in
      let argument_linings = inline_arguments j in
      union t [ top_linings; argument_linings ]

let rec have_intersection ?(table = None) t a b =
  if a = b then true
  else
    let a, b = if a > b then (b, a) else (a, b) in

    let intersect a b =
      match (index_table t a, index_table t b) with
      | Void, _ | _, Void -> false
      | Universe, _ -> true
      | _, Universe -> true
      | Union xs, Union ys ->
          xs
          |> List.exists ~f:(fun x ->
                 ys |> List.exists ~f:(fun y -> have_intersection ~table t x y))
      | Union xs, _ -> xs |> List.exists ~f:(fun x -> have_intersection ~table t x b)
      | _, Union xs -> xs |> List.exists ~f:(fun x -> have_intersection ~table t x a)
      | AbstractSpace b1, AbstractSpace b2 -> have_intersection ~table t b1 b2
      | ApplySpace (f1, x1), ApplySpace (f2, x2) ->
          have_intersection ~table t f1 f2 && have_intersection ~table t x1 x2
      | IndexSpace i1, IndexSpace i2 when i1 = i2 -> true
      | TerminalSpace t1, TerminalSpace t2 when equal_program t1 t2 -> true
      | _ -> false
    in

    match table with
    | None -> intersect a b
    | Some table' -> (
        match Hashtbl.find table' (a, b) with
        | Some i -> i
        | None ->
            let i = intersect a b in
            Hashtbl.set table' ~key:(a, b) ~data:i;
            i)

let factored_substitution = ref false

let rec substitutions t ?(n = 0) index =
  match Hashtbl.find t.substitution_table (index, n) with
  | Some s -> s
  | None ->
      let s = shift_free t ~n ~index in
      let m = Hashtbl.Poly.create () in
      if s <> t.void then
        ignore (Hashtbl.add m ~key:s ~data:(version_index t n) : [ `Duplicate | `Ok ]);

      (match index_table t index with
      | TerminalSpace _ -> ignore (Hashtbl.add m ~key:t.universe ~data:index : [ `Duplicate | `Ok ])
      | IndexSpace i ->
          ignore
            (Hashtbl.add m ~key:t.universe ~data:(if i < n then index else version_index t (1 + i))
              : [ `Duplicate | `Ok ])
      | AbstractSpace b ->
          substitutions t ~n:(n + 1) b
          |> Hashtbl.iteri ~f:(fun ~key ~data ->
                 Hashtbl.add_exn m ~key ~data:(version_abstract t data))
      | Union u ->
          let new_mapping = Hashtbl.Poly.create () in
          u
          |> List.iter ~f:(fun x ->
                 substitutions t ~n x
                 |> Hashtbl.iteri ~f:(fun ~key:v ~data:b ->
                        match Hashtbl.find new_mapping v with
                        | Some stuff -> Hashtbl.set new_mapping ~key:v ~data:(b :: stuff)
                        | None -> Hashtbl.set new_mapping ~key:v ~data:[ b ]));
          new_mapping
          |> Hashtbl.iteri ~f:(fun ~key ~data -> Hashtbl.set m ~key ~data:(union t data))
      | ApplySpace (f, x) when !factored_substitution ->
          let new_mapping = Hashtbl.Poly.create () in
          let fm = substitutions t ~n f in
          let xm = substitutions t ~n x in

          fm
          |> Hashtbl.iteri ~f:(fun ~key:v1 ~data:f ->
                 xm
                 |> Hashtbl.iteri ~f:(fun ~key:v2 ~data:x ->
                        if have_intersection t v1 v2 then
                          Hashtbl.update new_mapping (intersection t v1 v2) ~f:(function
                            | None -> ([ f ], [ x ])
                            | Some (fs, xs) -> (f :: fs, x :: xs))));
          new_mapping
          |> Hashtbl.iteri ~f:(fun ~key ~data:(fs, xs) ->
                 let fs = union t fs in
                 let xs = union t xs in
                 Hashtbl.set m ~key ~data:(version_apply t fs xs))
      | ApplySpace (f, x) ->
          let new_mapping = Hashtbl.Poly.create () in
          let fm = substitutions t ~n f in
          let xm = substitutions t ~n x in

          fm
          |> Hashtbl.iteri ~f:(fun ~key:v1 ~data:f ->
                 xm
                 |> Hashtbl.iteri ~f:(fun ~key:v2 ~data:x ->
                        if have_intersection t v1 v2 then
                          let v = intersection t v1 v2 in
                          let a = version_apply t f x in
                          match Hashtbl.find new_mapping v with
                          | Some stuff -> Hashtbl.set new_mapping ~key:v ~data:(a :: stuff)
                          | None -> Hashtbl.set new_mapping ~key:v ~data:[ a ]));

          new_mapping
          |> Hashtbl.iteri ~f:(fun ~key ~data -> Hashtbl.set m ~key ~data:(union t data))
      | _ -> ());
      Hashtbl.set t.substitution_table ~key:(index, n) ~data:m;
      m

let inversion t j =
  substitutions t j |> Hashtbl.to_alist
  |> List.filter_map ~f:(fun (v, b) ->
         if v = t.universe || equal_vs (index_table t b) (IndexSpace 0) then None
         else Some (version_apply t (version_abstract t b) v))
  |> union t

let rec recursive_inversion t j =
  match get_resizable t.recursive_inversion_table j with
  | Some ri -> ri
  | None ->
      let ri =
        match index_table t j with
        | Union u -> union t (u |> List.map ~f:(recursive_inversion t))
        | _ ->
            let top_inversions =
              substitutions t j |> Hashtbl.to_alist
              |> List.filter_map ~f:(fun (v, b) ->
                     if v = t.universe || equal_vs (index_table t b) (IndexSpace 0) then None
                     else Some (version_apply t (version_abstract t b) v))
            in
            let child_inversions =
              match index_table t j with
              | ApplySpace (f, x) ->
                  [
                    version_apply t (recursive_inversion t f) x;
                    version_apply t f (recursive_inversion t x);
                  ]
              | AbstractSpace b -> [ version_abstract t (recursive_inversion t b) ]
              | _ -> []
            in
            union t (child_inversions @ top_inversions)
      in
      set_resizable t.recursive_inversion_table j (Some ri);
      ri

let beta_pruning t j =
  let rec beta_pruning' ?(isApplied = false) ?(canBeta = true) t j =
    match index_table t j with
    | ApplySpace (f, x) ->
        let f' = beta_pruning' ~canBeta ~isApplied:true t f in
        let x' = beta_pruning' ~canBeta ~isApplied:false t x in
        version_apply t f' x'
    | AbstractSpace _ when isApplied && not canBeta -> t.void
    | AbstractSpace b when isApplied && canBeta ->
        let b' = beta_pruning' ~isApplied:false ~canBeta:false t b in
        version_abstract t b'
    | AbstractSpace b ->
        let b' = beta_pruning' ~isApplied:false ~canBeta t b in
        version_abstract t b'
    | Union u -> u |> List.map ~f:(beta_pruning' ~isApplied ~canBeta t) |> union t
    | LetSpace (d, b) ->
        let d' = beta_pruning' ~isApplied ~canBeta t d in
        let b' = beta_pruning' ~isApplied ~canBeta t b in
        version_let t d' b'
    | LetRevSpace (vc, v, d, b) ->
        let d' = beta_pruning' ~isApplied ~canBeta t d in
        let b' = beta_pruning' ~isApplied ~canBeta t b in
        version_let_rev t vc v d' b'
    | IndexSpace _ | VarIndexSpace _ | TerminalSpace _ | Universe | Void -> j
  in
  beta_pruning' t j

let rec log_version_size t j =
  match index_table t j with
  | ApplySpace (f, x) -> log_version_size t f +. log_version_size t x
  | AbstractSpace b -> log_version_size t b
  | Union u -> u |> List.map ~f:(log_version_size t) |> lse_list
  | _ -> 0.

let rec beta_substitution t i d j =
  match index_table t j with
  | IndexSpace _ | TerminalSpace _ | Universe | Void -> j
  | Union u -> u |> List.map ~f:(beta_substitution t i d) |> union t
  | VarIndexSpace k -> if i = k then d else if k > i then version_var t (k - 1) else j
  | ApplySpace (f, x) ->
      let f' = beta_substitution t i d f in
      let x' = beta_substitution t i d x in
      version_apply t f' x'
  | AbstractSpace b ->
      let b' = beta_substitution t i d b in
      version_abstract t b'
  | LetSpace (dd, b) ->
      let dd' = beta_substitution t i d dd in
      let b' = beta_substitution t (i + 1) d b in
      version_let t dd' b'
  | LetRevSpace (vc, v, dd, b) ->
      let dd' = beta_substitution t i d dd in
      let b' = beta_substitution t (i + vc) d b in
      version_let_rev t vc v dd' b'

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1 = (car $inp0) in (cons $v1 $inp0)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  let p' =
    match index_table t p with LetSpace (d, b) -> beta_substitution t 0 d b | _ -> assert false
  in
  Printf.printf "%s\n" (string_of_versions t p');
  [%expect {| @(@(cons, @(car, $v0)), $v0) |}]

let rec substitute_rev_var t j r_is i : (int * int * int) option =
  let open Option in
  match (r_is, index_table t j) with
  | _, LetRevSpace (vc, v, d, b) when version_var t i = v ->
      substitute_rev_var t b (Some (0, vc)) (i + vc) >>= fun (_, _, b') -> Some (vc, d, b')
  | Some (r_off, r_vc), LetRevSpace (vc, v, d, b) ->
      substitute_rev_var t b (Some (r_off + vc, r_vc)) (i + vc) >>= fun (_, _, b') ->
      substitute_rev_var t v r_is i >>= fun (_, _, v') ->
      Some (0, t.void, version_let_rev t vc v' d b')
  | None, LetRevSpace (vc, v, d, b) ->
      substitute_rev_var t b r_is (i + vc) >>= fun (r_vc, r_d, b') ->
      substitute_rev_var t v (Some (-1, r_vc)) i >>= fun (_, _, v') ->
      Some (r_vc, r_d, version_let_rev t vc v' d b')
  | Some (r_off, r_vc), LetSpace (d, b) ->
      substitute_rev_var t d r_is i >>= fun (_, _, d') ->
      substitute_rev_var t b (Some (r_off + 1, r_vc)) (i + 1) >>= fun (_, _, b') ->
      Some (0, t.void, version_let t d' b')
  | None, LetSpace (d, b) ->
      substitute_rev_var t b r_is (i + 1) >>= fun (r_vc, r_d, b') ->
      substitute_rev_var t d (Some (-1, r_vc)) i >>= fun (_, _, d') ->
      Some (r_vc, r_d, version_let t d' b')
  | _, Union _u ->
      raise
        (Failure (Printf.sprintf "Got Union for replacing a variable %s" (string_of_versions t j)))
      (* let u' =
           u
           |> List.filter_map ~f:(fun j' -> substitute_rev_var t j' r_is i)
           |> List.map ~f:(fun (_, _, k) -> k)
         in
         Some (0, t.void, union t u') *)
  | None, _ -> None
  | _, VarIndexSpace k when i = k -> None
  | Some (-1, _), VarIndexSpace k when k < i -> Some (0, t.void, j)
  | Some (-1, r_vc), VarIndexSpace k when k > i -> Some (0, t.void, version_var t (k - 1 + r_vc))
  | Some (r_off, _), VarIndexSpace k when k < r_off -> Some (0, t.void, j)
  | Some (r_off, r_vc), VarIndexSpace k when k < r_off + r_vc ->
      Some (0, t.void, version_var t (i - r_vc + k - r_off))
  | Some (_r_off, r_vc), VarIndexSpace k when k < i -> Some (0, t.void, version_var t (k - r_vc))
  | _, VarIndexSpace k when k > i -> Some (0, t.void, version_var t (k - 1))
  | _, VarIndexSpace _ -> raise (Failure "Unexpected VarIndexSpace")
  | _, ApplySpace (f, x) ->
      substitute_rev_var t f r_is i >>= fun (_, _, f') ->
      substitute_rev_var t x r_is i >>= fun (_, _, x') -> Some (0, t.void, version_apply t f' x')
  | _, AbstractSpace b ->
      substitute_rev_var t b r_is i >>= fun (_, _, b') -> Some (0, t.void, version_abstract t b')
  | _, (TerminalSpace _ | IndexSpace _ | Universe | Void) -> Some (0, t.void, j)

let rec update_rev_var_def_indices t j i =
  match index_table t j with
  | VarIndexSpace k -> version_var t (k + i)
  | ApplySpace (f, x) ->
      let f' = update_rev_var_def_indices t f i in
      let x' = update_rev_var_def_indices t x i in
      version_apply t f' x'
  | AbstractSpace b ->
      let b' = update_rev_var_def_indices t b i in
      version_abstract t b'
  | _ -> j

let rec substitute_rev_var_def t j d i vc =
  match index_table t j with
  | VarIndexSpace k -> if i = k then d else if k > i then version_var t (k - 1 + vc) else j
  | ApplySpace (f, x) ->
      let f' = substitute_rev_var_def t f d i vc in
      let x' = substitute_rev_var_def t x d i vc in
      version_apply t f' x'
  | AbstractSpace b -> version_abstract t (substitute_rev_var_def t b d i vc)
  | _ -> j

let beta_rev_substitution t j =
  match index_table t j with
  | LetRevSpace (vc, v, d, b) ->
      List.range 0 vc
      |> List.filter_map ~f:(fun i ->
             let open Option in
             substitute_rev_var t b None i >>= fun (vc', d', b') ->
             let d'' = update_rev_var_def_indices t d' i in
             let j' =
               version_let_rev t (vc - 1 + vc') v (substitute_rev_var_def t d d'' i vc') b'
             in
             Some j')
  | _ -> []

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3, $v4 = rev($v2 = (cons $v3 $v4)) in \
     (cons $v1 $v4)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with
    | LetRevSpace (_, _, _, _) -> beta_rev_substitution t p
    | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in @(@(cons, $v3), $v0)
    let rev($v0 = @(@(cons, $v2), @(@(cons, $v1), $v0))) in @(@(cons, $v2), $v0) |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3, $v4 = rev($v2 = (cons $v3 $v4)) in let \
     $v5, $v6 = rev($v4 = (cons $v5 $v6)) in let $v7 = (cons $v3 $v6) in (cons $v1 $v7)"
    |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with
    | LetRevSpace (_, _, _, _) -> beta_rev_substitution t p
    | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let @(@(cons, $v3), $v0) in @(@(cons, $v6), $v0)
    let rev($v0 = @(@(cons, $v2), @(@(cons, $v1), $v0))) in let rev($v0 = @(@(cons, $v1), $v0)) in let @(@(cons, $v3), $v0) in @(@(cons, $v5), $v0) |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3, $v4 = rev($v2 = (cons $v3 $v4)) in let \
     $v5, $v6 = rev($v1 = (cons $v5 $v6)) in (cons $v3 $v6)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with
    | LetRevSpace (_, _, _, _) -> beta_rev_substitution t p
    | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v3 = @(@(cons, $v1), $v0)) in @(@(cons, $v3), $v0)
    let rev($v0 = @(@(cons, $v2), @(@(cons, $v1), $v0))) in let rev($v2 = @(@(cons, $v1), $v0)) in @(@(cons, $v3), $v0)
    let rev($v0 = @(@(cons, @(@(cons, $v2), $v1)), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in @(@(cons, $v1), $v3) |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3 = (car $v2) in let $v4, $v5 = rev($v2 = \
     (cons $v4 $v5)) in let $v6, $v7 = rev($v5 = (cons $v6 $v7)) in let $v8 = Const(Any[]) in let \
     $v9 = (cons $v6 $v8) in (cons $v3 $v9)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with
    | LetRevSpace (_, _, _, _) -> beta_rev_substitution t p
    | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let @(car, $v0) in let rev($v1 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let Const(Any[]) in let @(@(cons, $v2), $v0) in @(@(cons, $v6), $v0)
     |}]

let rec min_var_index t j =
  match index_table t j with
  | VarIndexSpace k -> k
  | AbstractSpace b -> min_var_index t b
  | ApplySpace (f, x) -> min (min_var_index t f) (min_var_index t x)
  | TerminalSpace _ | IndexSpace _ -> Int.max_value
  | _ -> assert false

let rec shift_var_indices t j s =
  match index_table t j with
  | VarIndexSpace k -> version_var t (k + s)
  | AbstractSpace b -> version_abstract t (shift_var_indices t b s)
  | ApplySpace (f, x) -> version_apply t (shift_var_indices t f s) (shift_var_indices t x s)
  | _ -> j

let rec replace_var_indices t j depth min_repl max_repl =
  match index_table t j with
  | VarIndexSpace k ->
      if k < min_repl then j
      else if min_repl < 0 && k < depth then j
      else if min_repl < 0 && k >= depth then version_var t (k + max_repl - min_repl)
      else if k <= max_repl then version_var t (depth - (max_repl - k + 1))
      else if k < depth then version_var t (k - (max_repl - min_repl + 1))
      else j
  | AbstractSpace b -> version_abstract t (replace_var_indices t b depth min_repl max_repl)
  | ApplySpace (f, x) ->
      version_apply t
        (replace_var_indices t f depth min_repl max_repl)
        (replace_var_indices t x depth min_repl max_repl)
  | _ -> j

let rec reorder_lets' t j depth replacements =
  let replacements' =
    match index_table t j with
    | LetSpace (d, _b) when depth - 1 < min_var_index t d ->
        let replacement = (depth, 0) in
        replacement :: replacements
    | LetRevSpace (vc, v, _d, _b) when depth - 1 < min_var_index t v ->
        let replacement = (depth, vc - 1) in
        replacement :: replacements
    | _ -> replacements
  in
  match index_table t j with
  | LetSpace (d, b) ->
      reorder_lets' t b (depth + 1) replacements'
      |> List.map ~f:(fun (depth', vc', v', d', b') ->
             if depth' = depth then (depth, 1, t.void, d, b')
             else
               let min_repl = depth - depth' - vc' - 1 in
               let max_repl = depth - depth' - 1 in
               let j' = version_let t (replace_var_indices t d depth min_repl max_repl) b' in
               (depth', vc', v', d', j'))
  | LetRevSpace (vc, v, d, b) ->
      reorder_lets' t b (depth + vc) replacements'
      |> List.map ~f:(fun (depth', vc', v', d', b') ->
             if depth' = depth then (depth, vc, v, d, b')
             else
               let min_repl = depth - depth' - vc' - 1 in
               let max_repl = depth - depth' - 1 in
               let j' =
                 version_let_rev t vc (replace_var_indices t v depth min_repl max_repl) d b'
               in
               (depth', vc', v', d', j'))
  | _ ->
      List.map replacements ~f:(fun (repl_d, repl_vc) ->
          let min_repl = depth - repl_d - repl_vc - 1 in
          let max_repl = depth - repl_d - 1 in
          let j' = replace_var_indices t j depth min_repl max_repl in
          (repl_d, repl_vc, t.void, t.void, j'))

let reorder_lets t j =
  match index_table t j with
  | LetSpace (d, b) ->
      reorder_lets' t b 1 []
      |> List.map ~f:(fun (depth, vc', v', d', b') ->
             let b'' = version_let t (shift_var_indices t d vc') b' in
             match vc' with
             | 1 -> version_let t (shift_var_indices t d' (-depth)) b''
             | _ -> version_let_rev t vc' (shift_var_indices t v' (-depth)) d' b'')
  | LetRevSpace (vc, v, d, b) ->
      reorder_lets' t b vc []
      |> List.map ~f:(fun (depth, vc', v', d', b') ->
             let b'' = version_let_rev t vc (shift_var_indices t v vc') d b' in
             match vc' with
             | 1 -> version_let t (shift_var_indices t d' (-depth)) b''
             | _ -> version_let_rev t vc' (shift_var_indices t v' (-depth)) d' b'')
  | _ -> []

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1 = (car $inp0) in let $v2 = Const(Any[]) in (cons $v1 $v2)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' = match index_table t p with LetSpace (_, _) -> reorder_lets t p | _ -> assert false in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let @(car, $v0) in let Const(Any[]) in @(@(cons, $v1), $v0)
    let Const(Any[]) in let @(car, $v1) in @(@(cons, $v0), $v1)
    |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1 = Const(4) in let $v2, $v3 = rev($inp0 = (cons $v2 $v3)) in let $v4 = (cons $v2 $v3) \
     in (cons $v1 $v4)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' = match index_table t p with LetSpace (_, _) -> reorder_lets t p | _ -> assert false in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let Const(4) in let rev($v1 = @(@(cons, $v1), $v0)) in let @(@(cons, $v1), $v0) in @(@(cons, $v3), $v0)
    let rev($v0 = @(@(cons, $v1), $v0)) in let Const(4) in let @(@(cons, $v2), $v1) in @(@(cons, $v1), $v0)
    |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3, $v4 = rev($v2 = (cons $v3 $v4)) in let \
     $v5 = Const(Any[]) in let $v6 = (cons $v3 $v5) in (cons $v1 $v6)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with LetRevSpace (_, _, _, _) -> reorder_lets t p | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let Const(Any[]) in let @(@(cons, $v2), $v0) in @(@(cons, $v5), $v0)
    let Const(Any[]) in let rev($v1 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let @(@(cons, $v1), $v4) in @(@(cons, $v4), $v0)
    |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3, $v4 = rev($v2 = (cons $v3 $v4)) in let \
     $v5, $v6 = rev($v4 = (cons $v5 $v6)) in let $v7, $v8 = rev($v6 = (cons $v7 $v8)) in let $v9 = \
     (car $v8) in (cons $v9 $inp0)" |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' =
    match index_table t p with LetRevSpace (_, _, _, _) -> reorder_lets t p | _ -> assert false
  in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let @(car, $v0) in @(@(cons, $v0), $v9) |}]

let%expect_test _ =
  let t = new_version_table () in
  let p =
    "let $v1 = (car $inp0) in let $v2, $v3 = rev($inp0 = (cons $v2 $v3)) in let $v4, $v5 = rev($v3 \
     = (cons $v4 $v5)) in let $v6 = Const(Any[]) in let $v7 = (cons $v4 $v6) in (cons $v1 $v7)"
    |> parse_program |> get_some
    |> incorporate t (TNCon ("->", [ ("inp0", tint) ], tint, false))
  in
  Printf.printf "%s\n" (string_of_versions t p);
  let p' = match index_table t p with LetSpace (_, _) -> reorder_lets t p | _ -> assert false in
  List.iter p' ~f:(fun p'' -> Printf.printf "%s\n" (string_of_versions t p''));
  [%expect
    {|
    let @(car, $v0) in let rev($v1 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let Const(Any[]) in let @(@(cons, $v2), $v0) in @(@(cons, $v6), $v0)
    let Const(Any[]) in let @(car, $v1) in let rev($v2 = @(@(cons, $v1), $v0)) in let rev($v0 = @(@(cons, $v1), $v0)) in let @(@(cons, $v1), $v5) in @(@(cons, $v5), $v0)
    let rev($v0 = @(@(cons, $v1), $v0)) in let @(car, $v2) in let rev($v1 = @(@(cons, $v1), $v0)) in let Const(Any[]) in let @(@(cons, $v2), $v0) in @(@(cons, $v4), $v0)
     |}]

let n_step_inversion ?inline:(il = false) t ~n j =
  let key = (n, j) in
  match Hashtbl.find t.n_step_table key with
  | Some ns -> ns
  | None ->
      (* list of length (n+1), corresponding to 0 steps, 1, ..., n *)
      (* Each "step" is the union of an inverse inlining step and optionally an inlining step *)
      let rec n_step ?(completed = 0) current : int list =
        let step v =
          if il then
            let i = inline t v in
            (* if completed = 0 && v = j then *)
            (*   extract t i |> List.iter ~f:(fun expansion -> *)
            (*       Printf.eprintf "%s\t%s\n" *)
            (*         (extract t current |> List.hd_exn |> string_of_program) (string_of_program expansion)); *)
            union t [ recursive_inversion t v; i ]
          else recursive_inversion t v
        in
        let rest = if completed = n then [] else n_step ~completed:(completed + 1) (step current) in
        beta_pruning t current :: rest
      in

      let rec visit j =
        let children' j =
          match index_table t j with
          | LetSpace (d, b) ->
              [ version_let t (visit d) (visit b); visit (beta_substitution t 0 d b) ]
          | LetRevSpace (vc, v, d, b) ->
              version_let_rev t vc v (visit d) (visit b)
              :: List.map ~f:visit (beta_rev_substitution t j)
          | _ -> assert false
        in
        let children =
          match index_table t j with
          | Union _ | Void | Universe -> assert false
          | ApplySpace (f, x) -> version_apply t (visit f) (visit x)
          | AbstractSpace b -> version_abstract t (visit b)
          | IndexSpace _ | TerminalSpace _ -> j
          | LetSpace (_, _) | LetRevSpace (_, _, _, _) ->
              j :: reorder_lets t j |> List.map ~f:children' |> List.concat |> union t
          | VarIndexSpace _n -> j
        in
        union t (children :: n_step j)
      in

      let ns = visit j |> beta_pruning t in
      Hashtbl.set t.n_step_table ~key ~data:ns;
      ns

(* let n_step_inversion ?inline:(il=false) t ~n j = *)
(*   let clear_all_caches() =  *)
(*     clear_dynamic_programming_tables t; *)
(*     for j = 0 to (t.recursive_inversion_table.ra_occupancy - 1) do *)
(*       set_resizable t.recursive_inversion_table j None *)
(*     done *)
(*   in *)
(*   clear_all_caches(); *)

(*   factored_substitution := false; *)

(*   let ground_truth = n_step_inversion ~inline:il t ~n j in *)

(*   clear_all_caches(); *)
(*   factored_substitution := true; *)

(*   let faster = n_step_inversion ~inline:il t ~n j in *)

(*   clear_all_caches(); *)
(*   factored_substitution := false; *)

(*   let correct = extract t ground_truth |> List.map ~f:string_of_program |> String.Set.of_list in *)
(*   let hopeful = extract t faster |> List.map ~f:string_of_program |> String.Set.of_list in *)

(*   let missing = Set.diff correct hopeful in *)
(*   let extraneous = Set.diff hopeful correct in *)

(*   if Set.length missing > 0 || Set.length extraneous > 0 then begin *)
(*     let target_of_inversion = extract t j |> List.hd_exn in *)
(*     (\* False alarms *\) *)
(*     if Set.length missing = 0 && Set.for_all extraneous  ~f:(fun p -> *)
(*         let p = parse_program p |> get_some |> beta_normal_form in *)
(*         program_equal p target_of_inversion) then () *)
(*     else begin  *)
(*       Printf.eprintf "FATAL: When inverting %s\n" (target_of_inversion |> string_of_program); *)
(*       Printf.eprintf "The following programs are correct inversions that were not in the fast versions:\n"; *)
(*       missing |> Set.iter ~f:(Printf.eprintf "%s\n"); *)
(*       Printf.eprintf "The following programs are incorrect inversions that were nonetheless generated:\n"; *)
(*       extraneous |> Set.iter ~f:(fun p -> Printf.eprintf "%s\n" p; *)
(*                                   let p = parse_program p |> get_some |> beta_normal_form in *)
(*                                   Printf.eprintf "\t--> %s\n" (string_of_program p)); *)
(*       assert (false) *)
(*     end *)
(*   end; *)

(*   ground_truth *)

let reachable_versions t indices : int list =
  let visited = Hash_set.Poly.create () in

  let rec visit j =
    if Hash_set.mem visited j then ()
    else (
      Hash_set.add visited j;
      match index_table t j with
      | Universe | Void | IndexSpace _ | TerminalSpace _ -> ()
      | AbstractSpace b -> visit b
      | ApplySpace (f, x) ->
          visit f;
          visit x
      | Union u -> u |> List.iter ~f:visit)
  in
  indices |> List.iter ~f:visit;
  Hash_set.fold visited ~f:(fun a x -> x :: a) ~init:[]

(* garbage collection *)

let garbage_collect_versions ?(verbose = false) t indices =
  let nt = new_version_table () in
  let rec reincorporate i =
    match index_table t i with
    | Union u -> union nt (u |> List.map ~f:reincorporate)
    | ApplySpace (f, x) -> version_apply nt (reincorporate f) (reincorporate x)
    | AbstractSpace b -> version_abstract nt (reincorporate b)
    | IndexSpace i -> version_index nt i
    | TerminalSpace p -> version_terminal nt p
    | Universe -> nt.universe
    | Void -> nt.void
  in
  let indices = indices |> List.map ~f:(List.map ~f:reincorporate) in
  if verbose then
    Printf.eprintf "Garbage collection reduced table to %d%% of previous size\n"
      (100 * nt.i2s.ra_occupancy / t.i2s.ra_occupancy);
  (nt, indices)

(* cost calculations *)
let epsilon_cost = 0.01

(* Holds the minimum cost of each version space *)
type cost_table = {
  function_cost : (float * int list) option ra;
  argument_cost : (float * int list) option ra;
  cost_table_parent : vt;
}

let empty_cost_table t =
  { function_cost = empty_resizable (); argument_cost = empty_resizable (); cost_table_parent = t }

let rec minimum_cost_inhabitants ?(given = None) ?(canBeLambda = true) t j : float * int list =
  let caching_table = if canBeLambda then t.argument_cost else t.function_cost in
  ensure_resizable_length caching_table (j + 1) None;

  match get_resizable caching_table j with
  | Some c -> c
  | None ->
      let c =
        match given with
        | Some invention when have_intersection t.cost_table_parent invention j ->
            (1., [ invention ])
        | _ -> (
            match index_table t.cost_table_parent j with
            | Universe | Void -> assert false
            | IndexSpace _ | TerminalSpace _ -> (1., [ j ])
            | Union u ->
                let children = u |> List.map ~f:(minimum_cost_inhabitants ~given ~canBeLambda t) in
                let c = children |> List.map ~f:fst |> fold1 Float.min in
                if is_invalid c then (c, [])
                else
                  let open Float in
                  let children = children |> List.filter ~f:(fun (cost, _) -> cost = c) in
                  (c, children |> List.concat_map ~f:snd)
            | AbstractSpace b when canBeLambda ->
                let cost, children = minimum_cost_inhabitants ~given ~canBeLambda:true t b in
                ( cost +. epsilon_cost,
                  children |> List.map ~f:(version_abstract t.cost_table_parent) )
            | AbstractSpace _ -> (Float.infinity, [])
            | ApplySpace (f, x) ->
                let fc, fs = minimum_cost_inhabitants ~given ~canBeLambda:false t f in
                let xc, xs = minimum_cost_inhabitants ~given ~canBeLambda:true t x in
                if is_invalid fc || is_invalid xc then (Float.infinity, [])
                else
                  ( fc +. xc +. epsilon_cost,
                    fs
                    |> List.map ~f:(fun f' ->
                           xs |> List.map ~f:(fun x' -> version_apply t.cost_table_parent f' x'))
                    |> List.concat ))
      in
      let cost, indices = c in
      let indices = indices |> List.dedup_and_sort ~compare:( - ) in
      let c = (cost, indices) in
      set_resizable caching_table j (Some c);
      c

(* Holds the minimum cost of each version space, WITHOUT actually holding the programs *)
type cheap_cost_table = {
  function_cost : float option ra;
  argument_cost : float option ra;
  cost_table_parent : vt;
}

let empty_cheap_cost_table t =
  { function_cost = empty_resizable (); argument_cost = empty_resizable (); cost_table_parent = t }

let rec minimal_inhabitant_cost ?(intersectionTable = None) ?(given = None) ?(canBeLambda = true) t
    j : float =
  let caching_table = if canBeLambda then t.argument_cost else t.function_cost in
  ensure_resizable_length caching_table (j + 1) None;

  match get_resizable caching_table j with
  | Some c -> c
  | None ->
      let c =
        match given with
        | Some invention
          when have_intersection ~table:intersectionTable t.cost_table_parent invention j ->
            1.
        | _ -> (
            match index_table t.cost_table_parent j with
            | Universe | Void -> assert false
            | IndexSpace _ | TerminalSpace _ -> 1.
            | Union u ->
                u
                |> List.map ~f:(minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda t)
                |> fold1 Float.min
            | AbstractSpace b when canBeLambda ->
                epsilon_cost
                +. minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda:true t b
            | AbstractSpace _ -> Float.infinity
            | ApplySpace (f, x) ->
                epsilon_cost
                +. minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda:false t f
                +. minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda:true t x)
      in
      set_resizable caching_table j (Some c);
      c

let rec minimal_inhabitant ?(intersectionTable = None) ?(given = None) ?(canBeLambda = true) t j :
    program option =
  let c = minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda t j in
  if is_invalid c then None
  else
    let vs = index_table t.cost_table_parent j in
    let p =
      match (c, given) with
      | 1., Some invention
        when have_intersection ~table:intersectionTable t.cost_table_parent invention j ->
          extract t.cost_table_parent invention |> singleton_head
      | _ -> (
          match vs with
          | Universe | Void -> assert false
          | IndexSpace _ | TerminalSpace _ -> extract t.cost_table_parent j |> singleton_head
          | Union u ->
              u
              |> minimum_by (minimal_inhabitant_cost ~intersectionTable ~given ~canBeLambda t)
              |> minimal_inhabitant ~intersectionTable ~given ~canBeLambda t
              |> get_some
          | AbstractSpace b ->
              Abstraction
                (minimal_inhabitant ~intersectionTable ~given ~canBeLambda:true t b |> get_some)
          | ApplySpace (f, x) ->
              Apply
                ( minimal_inhabitant ~intersectionTable ~given ~canBeLambda:false t f |> get_some,
                  minimal_inhabitant ~intersectionTable ~given ~canBeLambda:true t x |> get_some ))
    in
    Some p

type beam = {
  default_function_cost : float;
  default_argument_cost : float;
  mutable relative_function : (int, float) Hashtbl.t;
  mutable relative_argument : (int, float) Hashtbl.t;
}

let narrow ~bs b =
  let narrow bm =
    if Hashtbl.length bm > bs then
      let sorted =
        Hashtbl.to_alist bm |> List.sort ~compare:(fun (_, c1) (_, c2) -> Float.compare c1 c2)
      in
      Hashtbl.Poly.of_alist_exn (List.take sorted bs)
    else bm
  in
  b.relative_function <- narrow b.relative_function;
  b.relative_argument <- narrow b.relative_argument

let relax table key data =
  match Hashtbl.find table key with
  | None -> Hashtbl.set table ~key ~data
  | Some old when Float.( > ) old data -> Hashtbl.set table ~key ~data
  | Some _ -> ()

let relative_function b i =
  match Hashtbl.find b.relative_function i with None -> b.default_function_cost | Some c -> c

let relative_argument b i =
  match Hashtbl.find b.relative_argument i with None -> b.default_argument_cost | Some c -> c

(* calculate the number of free variables for each candidate  *)
(* if a candidate has free variables and whenever we use it we have to apply it to those variables *)
(* thus using these candidates is more expensive *)
let calculate_candidate_costs v candidates =
  let candidate_cost = Hashtbl.Poly.create () in
  candidates
  |> List.iter ~f:(fun k ->
         let cost =
           extract v k |> singleton_head |> free_variables ~d:0
           |> List.dedup_and_sort ~compare:( - )
           |> List.length |> Float.of_int
         in
         Hashtbl.set candidate_cost ~key:k ~data:(1. +. cost));
  candidate_cost

let beam_costs'' ~ct ~bs (candidates : int list) (frontier_indices : int list list) : beam option ra
    =
  let ct : cost_table = ct in
  let candidates' = candidates in
  let candidates = Hash_set.Poly.of_list candidates in
  let caching_table = empty_resizable () in
  let v = ct.cost_table_parent in

  let candidate_cost = calculate_candidate_costs v candidates' in

  let rec calculate_costs j =
    ensure_resizable_length caching_table (j + 1) None;
    match get_resizable caching_table j with
    | Some bm -> bm
    | None ->
        let default_argument_cost, inhabitants = minimum_cost_inhabitants ~canBeLambda:true ct j in
        let default_function_cost, _ = minimum_cost_inhabitants ~canBeLambda:false ct j in
        let bm =
          {
            default_argument_cost;
            default_function_cost;
            relative_function = Hashtbl.Poly.create ();
            relative_argument = Hashtbl.Poly.create ();
          }
        in
        inhabitants
        |> List.filter ~f:(Hash_set.mem candidates)
        |> List.iter ~f:(fun candidate ->
               let cost = Hashtbl.find_exn candidate_cost candidate in
               Hashtbl.set bm.relative_function ~key:candidate ~data:cost;
               Hashtbl.set bm.relative_argument ~key:candidate ~data:cost);
        (match index_table v j with
        | AbstractSpace b ->
            let child = calculate_costs b in
            child.relative_argument
            |> Hashtbl.iteri ~f:(fun ~key ~data ->
                   relax bm.relative_argument key (data +. epsilon_cost))
        | ApplySpace (f, x) ->
            let fb = calculate_costs f in
            let xb = calculate_costs x in
            let domain = Hashtbl.keys fb.relative_function @ Hashtbl.keys xb.relative_argument in
            domain
            |> List.iter ~f:(fun i ->
                   let c = epsilon_cost +. relative_function fb i +. relative_argument xb i in
                   relax bm.relative_function i c;
                   relax bm.relative_argument i c)
        | Union u ->
            u
            |> List.iter ~f:(fun u ->
                   let child = calculate_costs u in
                   child.relative_function
                   |> Hashtbl.iteri ~f:(fun ~key ~data -> relax bm.relative_function key data);
                   child.relative_argument
                   |> Hashtbl.iteri ~f:(fun ~key ~data -> relax bm.relative_argument key data))
        | IndexSpace _ | Universe | Void | TerminalSpace _ -> ());
        narrow ~bs bm;
        set_resizable caching_table j (Some bm);
        bm
  in

  frontier_indices |> List.iter ~f:(List.iter ~f:(fun j -> ignore (calculate_costs j : beam)));
  caching_table

(* For each of the candidates returns the minimum description length of the frontiers *)
let beam_costs' ~ct ~bs (candidates : int list) (frontier_indices : int list list) : float list =
  let caching_table = beam_costs'' ~ct ~bs candidates frontier_indices in
  let frontier_beams =
    frontier_indices
    |> List.map ~f:(List.map ~f:(fun j -> get_resizable caching_table j |> get_some))
  in

  let score i =
    let corpus_size =
      frontier_beams
      |> List.map ~f:(fun bs ->
             bs
             |> List.map ~f:(fun b -> Float.min (relative_argument b i) (relative_function b i))
             |> fold1 Float.min)
      |> fold1 ( +. )
    in
    corpus_size
  in

  candidates |> List.map ~f:score

let beam_costs ~ct ~bs (candidates : int list) (frontier_indices : int list list) =
  let scored = List.zip_exn (beam_costs' ~ct ~bs candidates frontier_indices) candidates in
  scored |> List.sort ~compare:(fun (s1, _) (s2, _) -> Float.compare s1 s2)

let batched_refactor ~ct (candidates : int list) (frontier_indices : int list list) =
  let caching_table = beam_costs'' ~ct ~bs:(List.length candidates) candidates frontier_indices in

  let v = ct.cost_table_parent in

  let rec refactor ~canBeLambda i j =
    let inhabitants = minimum_cost_inhabitants ~canBeLambda:true ct j |> snd in

    if List.mem ~equal:( = ) inhabitants i then i |> extract v |> singleton_head
    else
      match index_table v j with
      | AbstractSpace b ->
          assert canBeLambda;
          Abstraction (refactor ~canBeLambda:true i b)
      | ApplySpace (f, x) -> Apply (refactor ~canBeLambda:false i f, refactor ~canBeLambda:true i x)
      | Union u ->
          u
          |> minimum_by (fun u' ->
                 let bm' = get_resizable caching_table u' |> get_some in
                 (if canBeLambda then relative_argument else relative_function) bm' i)
          |> refactor ~canBeLambda i
      | IndexSpace j -> Index j
      | TerminalSpace e -> e
      | Universe | Void -> assert false
  in

  candidates
  |> List.map ~f:(fun i ->
         frontier_indices
         |> List.map ~f:(fun f -> f |> List.map ~f:(fun j -> refactor ~canBeLambda:true i j)))
