/* file: ggram.mly
 * OCaml YACC input for G language grammar.
 * Copyright(C) 2009 Geordie and Chris Tilt
 * Free for use and distribution. Please retain credits.
 */

%{
open Printf

%}

%token <float> FLOAT
%token <int> INT PIN
%token <string> IDENT
%token BLINK WAIT FAST SLOW MEDIUM TIMES SECS REPEAT MSECS
%token LINE LINES TURN ON OFF AND IF DETECT ALL
%token EVERY LAST FOR IS FROM TO DO UNTIL WHILE FOREVER
%token NEWLINE EOF

%start prog
%type <G.prog> prog

%% /* Grammar rules and actions follow */
prog: EOF                    { G.Prog[]      }
  | stmts EOF                { G.Prog($1)    }
;

stmts: stmt_list             { List.rev $1   }
;

/* Left recursion builds it reversed */
stmt_list: src_stmt          { [$1]          }
  | stmt_list src_stmt       { $2::$1        }
;

/* associate source position info with a stmt */
src_stmt: stmt               { let pos = Parsing.rhs_start_pos 1 in
			       let file = pos.Lexing.pos_fname in
			       let line = pos.Lexing.pos_lnum
			       in (file,line),$1 }

level: /* empty */           { G.HIGH        }
  | ON                       { G.HIGH        }
  | OFF                      { G.LOW         }
;

cond:
  | DETECT PIN level         { G.Detect(($2,G.Input),$3) }
  | DETECT PIN IS level      { G.Detect(($2,G.Input),$4) }
;

stmt: action                 { G.Action($1)             }
  | IF cond actions          { G.Cond($2,$3)            }
  | REPEAT stmts guard       { G.Repeat(G.Block($2),$3) }
  | DO stmts guard           { G.Do(G.Block($2),$3)     }
;

rate: /* empty */   { 1000 } /* default if not specified */
  | SLOW            { 1500 }
  | MEDIUM          { 1000 }
  | FAST            { 500  }
  | EVERY period    { $2   } /* alternate syntax */
;

period:
  | INT SECS        { $1 * 1000 }
  | INT MSECS       { $1        }
;

actions: action_list        { List.rev $1  }
;

/* Left recursion builds it reversed */
action_list:
  | action                      { [$1]         }
  | action_list AND action      { $3::$1       }
;

action:
  | rate BLINK PIN duration_opt    { G.Blink(($3,G.Output),$1,$4) }
  | BLINK rate PIN duration_opt    { G.Blink(($3,G.Output),$2,$4) }
  | BLINK PIN rate duration_opt    { G.Blink(($2,G.Output),$3,$4) }
  | TURN ON PIN                { G.Set(($3,G.Output),G.HIGH)  }
  | TURN PIN ON                { G.Set(($2,G.Output),G.HIGH)  }
  | TURN OFF PIN               { G.Set(($3,G.Output),G.LOW)   }
  | TURN PIN OFF               { G.Set(($2,G.Output),G.LOW)   }
  | WAIT INT SECS              { G.Wait($2 * 1000) }
  | WAIT INT MSECS             { G.Wait($2)        }
;

guard:
  | FOREVER           { G.GForever        }
  | WHILE cond        { G.GCond($2,true)  }
  | UNTIL cond        { G.GCond($2,false) }
  | UNTIL duration    { G.GDuration($2)   }
;

duration:
  | INT TIMES        { G.DCount($1)    }
  | period           { G.DPeriod($1)   }
;

duration_opt: /* empty */    { G.DCount(1) }
  | duration                 { $1          }
  | FOR duration             { $2          }
;

%%
