(* Copyright(C) 2009 by G. and C. Tilt
 *
 * Convert the linear G program into blocks of statements for the Repeat and Do stmts.
 * Repeat implies sequential execution.
 * Do implies concurrent execution.
 *)
let rewrite(p:G.prog) : G.prog =
  let G.Prog(stmts) = p in
  let rec gather block stmts : G.stmt list =
    match stmts with
	[] -> block
      | G.Repeat(G.Block[],guard)::ss ->
	  G.Repeat(G.Block((List.rev block),guard))::(gather [] ss)
      | G.Do(G.Block[],guard)::ss ->
	  G.Do(G.Block(List.rev block))::(gather [] ss)
      | s::ss -> gather (s::block) ss in
  let stmts = gather [] stmts
  in
   G.Prog(stmts)
