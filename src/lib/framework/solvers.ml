open Batteries

module ImperativeMap(K : sig type key end) = struct
  type key = K.key
  type 'data t = (key, 'data) Hashtbl.t

  let create ()  = Hashtbl.create 10
  let clear ht   = Hashtbl.clear ht
  let add k v ht = Hashtbl.replace ht k v
  let find k ht  = Hashtbl.find ht k
  let iter f ht  = Hashtbl.iter f ht
end

module MakeFix(L : Sig.Lattice)(Cfg : Sig.Flow_graph)
    (F : Sig.Transfer with
      type label = Cfg.stmt_label
                       and type vertex = Cfg.vertex
                       and type state = L.property)
    (D : Sig.Dependencies with type g_t = Cfg.t and type label = Cfg.stmt_label)
= struct
  type variable = Circ of Cfg.stmt_label | Bullet of Cfg.stmt_label
  module Fix = Fix.Make(ImperativeMap(struct type key = variable end))(L)

  let generate_equations graph var state =
    match var with
    | Circ l -> D.indep graph l |> List.map (fun l' -> state(Bullet l'))
                |> List.fold_left L.lub
                  (if D.is_extremal graph l then F.initial_state
                   else L.bottom)
    | Bullet l ->
        F.f (Cfg.get_func_id graph l) l (Cfg.get graph l) (state (Circ l))

  let solve graph = generate_equations graph |> Fix.lfp
end

module MakeFixInter(L : Sig.Lattice)(Cfg : Sig.Inter_flow_graph)
    (F : Sig.Inter_transfer with type label = Cfg.stmt_label and
    type vertex = Cfg.vertex and
    type state = L.property)
    (D : Sig.Dependencies with type g_t = Cfg.t and type label = Cfg.stmt_label)
= struct
  type variable = Circ of Cfg.stmt_label | Bullet of Cfg.stmt_label
  module Fix = Fix.Make(ImperativeMap(struct type key = variable end))(L)

  let generate_equations graph var state =
    match var with
    | Circ l -> D.indep graph l |> List.map (fun l' -> state (Bullet l'))
                |> List.fold_left L.lub
                  (if D.is_extremal graph l then F.initial_state
                   else L.bottom)
    | Bullet l -> let fid = Cfg.get_func_id graph l in
        if Cfg.inter_flow graph |> List.exists (fun (lc,_,_,_) -> lc = l) then
          F.f1 (Cfg.get_func_id graph l) l (Cfg.get graph l) (state (Circ l))
        else if Cfg.inter_flow graph |> List.exists (fun (_,_,_,lr) -> lr = l) then
          Cfg.inter_flow graph |> List.filter_map (fun (lc,_,_,lr) ->
            if lr = l then Some (Cfg.get_func_id graph lc,lc) else None) |>
          List.fold_left (fun acc (fid2,lc) ->
            F.f2 fid fid2 l (Cfg.get graph l) (state (Circ lc)) (state (Circ l))
            |> L.lub acc) L.bottom
        else
          F.f (Cfg.get_func_id graph l) l (Cfg.get graph l) (state (Circ l))

  let solve graph = generate_equations graph |> Fix.lfp
end
