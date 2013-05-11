(* file: g2c.ml *)
(* Assumes the parser file is "ggram.mly" and the lexer file is "glex.mll". *)
let main () =
  let args = Array.to_list(Sys.argv) in
  let infile =
    match List.length args with
	0
      | 1 -> failwith "missing an input file"
      | 2 ->
	  let progName,rest = (List.hd args),(List.tl args) in
	  let fname = List.hd rest
	  in (*Printf.printf "input file is %s\n" fname;*) fname
      | _ -> failwith "too many arguments to program" in
    (* open the input file and initialize the lexbuf with a position
       that includes the input file name. That way, we can generate
       file and line info for our original source program *)
  let inchan = open_in infile in
  let lexbuf = Lexing.from_channel inchan in
  let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <-
      { pos with Lexing.pos_fname = infile; };
    try
      let prog = Ggram.prog Glex.g_token lexbuf
	in
	  (* G.print prog; *)
	  Printc.print prog;
	  close_in inchan
      with Parsing.Parse_error ->
	Printf.printf
	  "syntax error at line %i column %i\n"
	  (Lexing.lexeme_start_p lexbuf).Lexing.pos_lnum
	  ((Lexing.lexeme_start_p lexbuf).Lexing.pos_cnum
	   - (Lexing.lexeme_start_p lexbuf).Lexing.pos_bol);
	close_in inchan;
	flush stdout

      
let _ = Printexc.print main ()
