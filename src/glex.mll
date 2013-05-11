(* OCaml lexical scanner for G language
 * Copyright(C) 2009 Geordie and Chris Tilt
 * Free for use and distribution. Please leave credits in source code.
 *)

{
  open Printf
  open Ggram

  let update_position lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <- { pos with
      Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
      Lexing.pos_bol = pos.Lexing.pos_cnum;
      Lexing.pos_fname = pos.Lexing.pos_fname;
    }
}

let digit = ['0'-'9']
let id = ['a'-'z'] ['a'-'z']*

rule g_token = parse
  | digit+ as inum  	       { INT (int_of_string inum) }
  | digit+ '.' digit* as fnum  { FLOAT (float_of_string fnum) }

  | "pin" (digit+ as pin_num) { PIN (int_of_string pin_num) }
  | "PIN" (digit+ as pin_num) { PIN (int_of_string pin_num) }

  | "blink"  | "BLINK"   { BLINK }
  | "wait"   | "WAIT"    { WAIT }
  | "fast"   | "FAST"    { FAST }
  | "slow"   | "SLOW"    { SLOW }
  | "med"    | "MED"
  | "medium" | "MEDIUM"  { MEDIUM }
  | "times"  | "TIMES"   { TIMES }
  | "sec"    | "SEC"
  | "secs"   | "SECS"
  | "seconds" | "SECONDS" { SECS }
  | "msec"   | "MSEC"
  | "msecs"  | "MSECS"   { MSECS }
  | "repeat" | "REPEAT"  { REPEAT }
  | "line"   | "LINE"    { LINE }
  | "lines"  | "LINES"   { LINES }
  | "turn"   | "TURN"    { TURN }
  | "on"     | "ON"      { ON }
  | "high"   | "HIGH"    { ON }
  | "off"    | "OFF"     { OFF }
  | "low"    | "LOW"     { OFF }
  | "and"    | "AND"     { AND }
  | "if"     | "IF"      { IF }
  | "is"     | "IS"      { IS }
  | "for"    | "FOR"     { FOR }
  | "do"     | "DO"      { DO }
  | "all"    | "ALL"     { ALL }
  | "last"   | "LAST"    { LAST }
  | "forever"| "FOREVER" { FOREVER }
  | "every"  | "EVERY"   { EVERY }
  | "detect" | "DETECT"  { DETECT }
  | "until"  | "UNTIL"   { UNTIL }
  | "while"  | "WHILE"   { WHILE }
  | id as text { IDENT text }
  | [' ' '\t']	{ g_token lexbuf }	(* eat up whitespace *)
  | '\n'        { update_position lexbuf; g_token lexbuf }
  | _ as c
  	{ printf "Unrecognized character: %c\n" c;
	  g_token lexbuf
	}
  | eof		{ EOF }
