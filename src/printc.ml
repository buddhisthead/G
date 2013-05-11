(***************** sample output
int buttonPin = 3;

void setup()
{
  Serial.begin(9600);
  pinMode(buttonPin, INPUT);
}

void loop()
{
  // ...
}
******************)

type id = string
type lines = string list
type vfunc = id * lines

let semi = ";"
let tab = "    "

let nextInt = ref 0
let nextId() =
  let n = !nextInt
  in
    nextInt := n+1;
    (string_of_int n)

let printPinId(pin_num) = "pin"^(string_of_int pin_num)
let printPinMode(mode) =
  match mode with
      G.Input -> "INPUT"
    | G.Output -> "OUTPUT"
let printPinDecls(pins) =
    (List.map (fun ((n,_),i) ->
		 "int "^(printPinId(n))^" = "^(string_of_int n)^semi) pins)
let printLine l = l^semi
let printVoidFunc(id,lines) =
  ("void "^id^"() {")
  ::(List.map printLine lines)
  @["}"]

let printSetup(pins) =
  let lines =
    List.map
      (fun ((n,mode),i) -> "pinMode("^(printPinId(n))^", "^(printPinMode(mode))^")")
      pins
  in printVoidFunc("setup",lines)

let uniqify ll =
  let rec f keep xx =
    match xx with
	[] -> keep
      | x::rest -> if List.mem x keep then f keep rest else f (x::keep) rest
  in
    f [] ll
  
(* return a list of (pin * src_info) from the program stmts *)
let rec collectPins(stmts) =
  let f_action (i:G.src_info) act = match act with
      G.Blink(pin,_,_) -> [pin,i]
    | G.Set(pin,_) -> [pin,i]
    | G.Wait(_) -> [] in
  let f_cond (i:G.src_info) cond = match cond with
      G.Detect(pin,_) -> [pin,i] in
  let f_stmt pins ((i:G.src_info),stmt) =
    match stmt with
	G.Action(action) -> (f_action i action)@pins
      | G.Cond(cond,actions) ->
	  (f_cond i cond)@(List.flatten (List.map (f_action i) actions))@pins
      | G.Repeat(G.Block(stmts),guard) -> collectPins(stmts)@pins
      | G.Do(G.Block(stmts),guard) -> collectPins(stmts)@pins
  in
  let nonuniquePins =
    List.fold_left f_stmt [] stmts in
  let uniqifyPins ll =
    (* get unique list of pins, ignoring source info *)
    let rec f keep xx =
      match xx with
	  [] -> keep
	| (p',_)as x::rest ->
	    if List.exists (fun (p,_) -> p=p') keep
	    then f keep rest else f (x::keep) rest
    in
      f [] ll
  in
    uniqifyPins nonuniquePins

(** check that each mentioned pin has a consistent I/O direction *)
let checkPins(pins:((G.pin * G.src_info) list)) =
  let pinError(((n,m),(f,l)),((n',m'),(f',l'))) =
    Printf.printf
      "Error: Pins can only be used as either an Input or an Output, but not both at the same time.\n";
    Printf.printf
      "Error: pin%i is used for %s near line %i and for %s near line %i\n"
      n (printPinMode m) l (printPinMode m') l';
    Printf.printf
      "Error: To fix this, you should use a different pin for either the input or output.\n";
    flush stdout;
    exit 1 in
  let f_check (((n,mode),i)as p) seen =
    List.iter (fun (((n',mode'),i')as p') ->
		 if n=n' && mode<>mode' then pinError(p,p')) pins in
  let rec f checked xx =
    match xx with
	[] -> () (* all pins have unique I/O direction *)
      | pin::rest -> f_check pin checked
  in
    f [] pins

let nextCounterId() = "counter_"^(nextId())
let nextTimerId() = "timer_"^(nextId())

let timeslice interval var (actions:string list) dur_incr =
  ("if (millis() - "^var^" >= "^(string_of_int interval)^") {")
  ::dur_incr
  ::(var^" = millis();   // remember the last time we took action")
  ::actions
  @["}"]

let nonBlockingBlinkAction ledPin =
  let pinVar = printPinId ledPin in
  let valVar = "value_of_"^pinVar
  in
    "// if the LED is off turn it on and vice-versa."
    ::("int "^valVar^" = digitalRead("^pinVar^");")
    ::("if ("^valVar^" == LOW) {")
    ::(  valVar^" = HIGH;")
    ::"}"
    ::"else {"
    ::(  valVar^" = LOW;")
    ::"}"
    ::["digitalWrite("^pinVar^", "^valVar^");"]

let printMsec m = (string_of_int m)^" msec"
let printLevel level =
  match level with
      G.HIGH -> "HIGH"
    | G.LOW -> "LOW"
let printCondExp exp =
  match exp with
    G.Detect((pin,_),level) ->
      "digitalRead("^(printPinId pin)^") == "
      ^(printLevel level)

let printDuration duration =
  match duration with
      G.DCount i ->
	let var = nextCounterId()
	in ("int "^var^" = 0;", var^" < "^(string_of_int i), var^"++;")
    | G.DPeriod msec ->
	let var = nextTimerId()
	in
	  ("long "^var^" = millis() + "^(string_of_int msec)^";","millis() < "^var,"")

(* timeloop is used for a group of time slices. So it can be used
 * to hold a single sequential action, or a group of concurrent ones.
 * [inits] will be issued before the outer loop.
 *)
let timeloop timeSlice duration inits concur =
  let init,test,incr = printDuration duration in
  let mode = if concur then "if" else "while"
  in
    init::inits
    @[mode^" ("^test^") {"]
    @(timeSlice incr)
    @["}"]

let printAction (concur:bool) a : string list * string list =
  match a with
      G.Blink((pin,_),msec,dur) ->
	let msec = msec / 2 in
	let dur = (match dur with
		       G.DCount i -> G.DCount (i*2)
		     | G.DPeriod msec -> dur) in
	let blink_action = nonBlockingBlinkAction pin in
	let var = nextTimerId() in
	let inits = ["long "^var^" = 0;"]
	in
	  if concur then inits,(timeloop (timeslice msec var blink_action) dur [] concur)
	  else [],(timeloop (timeslice msec var blink_action) dur inits concur)
    | G.Set((pin,_),level) ->
	([],
	 ["digitalWrite("^(printPinId pin)^","^(printLevel level)^");"])
    | G.Wait(msec) ->
	([],
	 ["delay("^(string_of_int msec)^");"])

let printTruth t = if t then "" else "!"

(* returns (init,test,incr) strings *)
let printGuard guard =
  match guard with
      G.GDuration dur -> printDuration dur
    | G.GCond(cond,t) -> "",((printTruth t)^printCondExp(cond)),""
    | G.GForever -> "","1",""

(* return inits and lines *)
let rec printRange (concur:bool) (G.Block(stmts)) : string list * string list =
  let (a,b) = List.split (List.map (printStmt concur) stmts)
  in (List.concat a, List.concat b)
and printStmt concur (sstmt:G.src_stmt) : string list * string list =
  let ((file,line),s) = sstmt in
  let inits,lines =
    match s with
	G.Action(action) -> printAction concur action
      | G.Cond(e,acts) ->
	  let inits,lines = List.split (List.map (printAction concur) acts) in
      let inits,lines = ((List.concat inits),(List.concat lines))
	  in
	    (inits,
	     ("if ("^(printCondExp e)^") {")
	     ::lines
	     @["}"])
      | G.Repeat(range,guard) ->
	  let init,test,incr = printGuard guard in
	  let inits,ss = printRange false range
	  in
	    (inits,
	     "// repeat sequentially"
	     ::[init]
	     @[("while ("^test^") {")]
	     @ss
	     @[incr; "}"])
      | G.Do(range,guard) ->
	  let init,test,incr = printGuard guard in
	  let inits,ss = printRange true range
	  in
	    (inits,
	     "// repeat sequentially"
	     ::[init]
	     @[("while ("^test^") {")]
	     @ss
	     @[incr; "}"])
  in
    inits,lines
(*
    ("#line "^(string_of_int line)^" \""^file^"\"")::lines
*)

let printLoop(stmts) : string list =
  let inits,ss = List.split (List.map (printStmt false) stmts) in
  let inits,ss = ((List.concat inits),(List.concat ss))
  in "void loop() {"
     ::inits
     @ss
     @["}"]

let indent i =
  if i >= 0 then String.make (i*2) ' '
  else String.make 4 '>'

let lineflow (lines:string list) : string =
  let rec flow i lines =
    match lines with
	[] -> []
      | line::rest ->
	  (match String.length line with
	       0 -> flow i rest
	     | len ->
		 (match line.[len-1] with
		      '{' -> ((indent i)^line)::flow (i+1) rest
		    | '}' -> ((indent (i-1))^line)::flow (i-1) rest
		    | _ -> ((indent i)^line)::flow i rest
		 )
	  )
  in
  let lines = flow 0 lines
  in
    (String.concat "\n" lines)^"\n"
  
let print(G.Prog(stmts)as gprog) =
  let pins = collectPins(stmts) in
  let _ = checkPins(pins) in
    (* gather statements into blocks *)
    (* let G.Prog(stmts)as gprog = Structure.rewrite(gprog) in *)
  let cprog =
     "/* Arduino C Program auto-generated by g2c.\n"
    ^" * g2c is Copyright 2009, Geordie and Chris Tilt and free to use and modify.\n"
    ^" * original G program:\n\n\t"
    ^(G.print(gprog))^"\n*/\n"
    ^(lineflow (printPinDecls pins))
    ^"\n"
    ^(lineflow (printSetup pins))
    ^"\n"
    ^(lineflow (printLoop stmts))
  in
    Printf.printf "%s\n"cprog;
    flush stdout

