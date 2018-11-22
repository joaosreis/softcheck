open Batteries
open Utils

(*module Make_fixpoint(Analysis : Sig.ANALYSIS) =
struct
  let chaotic_iteration f =
    let rec chaotic_iteration_aux acc_entry acc_exit =
      let new_entry, new_exit =
        Set.map (fun (l,_) -> (l, Analysis.entry f acc_exit l)) acc_entry,
        Set.map (fun (l,_) -> (l, Analysis.exit f acc_entry l)) acc_exit
      in if (new_entry, new_exit) = (acc_entry, acc_exit) then new_entry, new_exit
      else chaotic_iteration_aux new_entry new_exit
    in let labels = Analysis.Flow.labels f
    in let a = Set.map (fun l -> (l, Analysis.init f)) labels
    in let b = a
    in chaotic_iteration_aux a b
end
*)