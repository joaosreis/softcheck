open Batteries
open Set.Infix
open Utils

module Make(Ast : Sig.Ast)(Cfg : Sig.Flow_graph with type stmt_label = Ast.label and type program = Ast.program)
    (S : sig
       include ReachingDefinitions.Language_component
       val ta : (ident, Taint_lattice.property) Map.t -> vertex ->
         (ident * Taint_lattice.property) list
     end with type ident = Cfg.ident and type stmt_label = Cfg.stmt_label and
    type vertex = Cfg.vertex) = struct
  module Solve(P : sig val p : Ast.program end) = struct
    let graph = Cfg.generate_from_program P.p
    let blocks = Cfg.get_blocks graph
    let vars = S.free_variables blocks

    module Var_tainting_lattice = Lattices.Map_lattice(struct
        type t = Ast.ident
        let to_string = identity
        let bottom_elems = vars
      end)(Taint_lattice)

    module Reaching_definitions_lattice = Lattices.Powerset_lattice(struct
        type t = S.definition_location
        let to_string (v,l) = Printf.sprintf "(%s,%s)" v (match l with
            None    -> "?"
          | Some l' -> string_of_int l')
      end)

    module L = Lattices.Pair_lattice(Reaching_definitions_lattice)(Var_tainting_lattice)

    module F = struct
      type label = Cfg.stmt_label
      type vertex = Cfg.vertex
      type state = L.property
      type ident = Cfg.ident

      let f _ l b s =
        let g = S.gen l b in
        let k = S.kill blocks b in
        let s1 = (fst s -. k) ||. g in
        let new_tv = S.ta (snd s) b in
        let s2 = List.fold_left (fun m (i,eval) -> Var_tainting_lattice.set m i eval) (snd s) new_tv in
        s1, s2

      let initial_state =
        Set.map (fun x -> x,None) vars,
        Set.fold (fun x acc -> Map.add x Taint_lattice.bottom acc) vars Map.empty
    end

    include Analysis.Forward.Make_solution(L)(Cfg)(F)(P)
  end
end