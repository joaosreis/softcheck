open Batteries

let cartesian_product xs ys =
  List.concat (List.map (fun x -> List.map (fun y -> (x, y)) ys) xs)

let fst3 (x, _, _) = x
let trd (_, _, x) = x

let (---) lower upper =
  let rec helper u i =
    if i > u then [] else i :: (helper u (i + 1))
  in helper upper lower

let (--) lower upper = lower --- (upper - 1)

module StringMap = Map.Make(String)

let dualize f (xs, ys) =
  f xs, f ys

let dual_map f (xs, ys) = dualize (List.map f) (xs, ys)

let dual_fold_left f acc (xs, ys) = dualize (List.fold_left f acc) (xs, ys)

let pair x y = (x,y)

let rev_pair x y = (y,x)

(* HACK inefficient *)
module ExtendedBatSet = struct
  include Set

  let find_prep prep s = List.find prep (to_list s)
end

module Set = ExtendedBatSet

let sprint_list ?(first = "[") ?(last = "]") ?(sep = "; ") to_string l =
  let strout = BatIO.output_string () in
  List.print ~first:first ~last:last ~sep:sep
    (fun outch x -> to_string x |> String.print outch) strout l;
  BatIO.close_out strout

let sprint_set to_string s =
  let strout = BatIO.output_string () in
  Set.print (fun outch x -> to_string x |> String.print outch) strout s;
  BatIO.close_out strout

let sprint_map k_to_string v_to_string m =
  let strout = BatIO.output_string () in
  Map.print (fun outch k -> k_to_string k |> String.print outch)
    (fun outch v -> v_to_string v |> String.print outch) strout m;
  BatIO.close_out strout

module MapWithDefault(D : sig type t val default : t end) = struct
  include Map

  let find x m = try find x m with Not_found -> D.default
end

module MultiPHashtbl = struct
  type ('a, 'b) t = ('a, 'b Set.t) Hashtbl.t

  let is_empty = Hashtbl.is_empty

  let add ht k v =
    let s = Hashtbl.find_default ht k Set.empty in
    Set.add v s |> Hashtbl.add ht k

  let find = Hashtbl.find

  let remove_all = Hashtbl.remove_all

  let remove = Hashtbl.remove

  let mem = Hashtbl.mem

  let iter = Hashtbl.iter

  let map = Hashtbl.map

  let map_inplace = Hashtbl.map_inplace

  let fold = Hashtbl.fold

  let modify = Hashtbl.modify

  let modify_def = Hashtbl.modify_def

  let modify_opt = Hashtbl.modify_opt

  let enum = Hashtbl.enum

  let of_enum = Hashtbl.enum
end
