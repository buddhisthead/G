type msec = int (* number of milliseconds *)

type mode = (* pin I/O modes *)
    Input
  | Output

type pin = int * mode (* pins are either inputs are outputs *)

type level =
    HIGH
  | LOW

type duration =
    DCount of int
  | DPeriod of msec

type action =
    Blink of pin * msec * duration (* pin number, period, how long to blink *)
  | Set of pin * level
  | Wait of msec

type cond =
    Detect of pin * level

type guard =
    GDuration of duration
  | GCond of cond * bool
  | GForever

(* [file] and [line] of original program source *)
type src_info = string * int

type stmt_range =
    Block of src_stmt list

and src_stmt = src_info * stmt

and stmt =
  | Action of action
  | Cond of cond * action list  (* if cond then [action list] *)
  | Repeat of stmt_range * guard
      (* repeat [stmt_range] sequence while guard is true *)
  | Do of stmt_range * guard
      (* execute [stmt_range] in parallel while guard is true *)

type prog =
    Prog of src_stmt list

let printMsec m = (string_of_int m)^" msec"
let printDuration d =
  match d with
      DCount i -> (string_of_int i)^" times"
    | DPeriod msec -> printMsec msec
let printPin (n,mode) = "pin"^(string_of_int n)
let printLevel level =
  match level with
      HIGH -> "ON"
    | LOW -> "OFF"
let printCondExp exp =
  match exp with
    Detect(pin,level) -> "detect "^(printPin pin)^" is "^(printLevel level)
let printAction a =
  match a with
      Blink(pin,msec,dur) ->
	"blink "^(printPin pin)^" every "^(printMsec msec)^
	" for "^(printDuration dur)
    | Set(pin,level) -> "turn "^(printPin pin)^" "^(printLevel level)
    | Wait(msec) -> "wait "^(printMsec msec)
let printTruth t = if t then "while" else "until"
let printGuard guard =
  match guard with
      GDuration dur -> "until "^(printDuration dur)
    | GCond(cond,t) -> (printTruth t)^" "^printCondExp(cond)
    | GForever -> "forver"
let rec printRange r =
  match r with
    | Block(stmts) -> "\n\t"^(String.concat "\n\t" (List.map (printStmt "\t") stmts))^"\n\t"
and printStmt t (info,s) : string =
  match s with
    | Action(action) -> t^printAction(action)
    | Cond(e,acts) ->
	t^"if "^(printCondExp e)^" "^(String.concat " and " (List.map printAction acts))
    | Repeat(range,guard) -> "repeat "^(printRange range)^(printGuard guard)
    | Do(range,guard) -> "do "^(printRange range)^(printGuard guard)
let print (p:prog) =
  let Prog(stmts) = p in
  let ss = List.map (printStmt "") stmts
  in
    String.concat "\n\t" ss
