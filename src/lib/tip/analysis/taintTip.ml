open Batteries
open Utils

open Tip

include Taint.Make(Ast)(Cfg)(struct
    include ReachingDefinitionsTip.S

    let rec eval s = let open Ast in
      let open Taint_lattice in function
          Ecallf _
        | Ecallfptr _ -> Taint_lattice.bottom
        | Eident i -> Map.find i s
        | Eunop (uop,e) -> eval s e
        | Ecst c -> Taint_lattice.Element false
        | Einput -> Taint_lattice.Element true
        | Emalloc -> Taint_lattice.Element false
        | Enull -> Taint_lattice.Element false
        | Ebinop (bop,e1,e2) ->
            let eval_e1 = eval s e1 in
            let eval_e2 = eval s e2 in
            match eval_e1, eval_e2 with
              Top, _
            | _, Top -> Top
            | Element true, _
            | _, Element true -> Element true
            |   Bottom, _
            | _, Bottom -> Bottom
            | _ -> Element false

    let ta s = let open Flow in function
        Sassign (Ast.Eident i,rv) ->
          let eval_rv = eval s rv in [i, eval_rv]
      | Sassign _
      | Sif _
      | Soutput _
      | Swhile _ -> []
  end)