(*Expert mode values*)
let defaultExtArraySize = ref 5
let defaultGraphSize = ref 5
let defaultLiftSetSize = ref 5
let defaultInjectionHeapSize = ref 5
let defaultLogSize = ref 10
let debugModeOn = ref false
let progressBarSymbol = ref '#'
let progressBarSize = ref 60
let plotSepChar = ref ' '

(*User definable values*)
let (maxEventValue:int option ref) = ref None
let (maxTimeValue:float option ref) = ref None
let (pointNumberValue:int option ref) = ref None
let (seedValue:int option ref) = ref None
let plotModeOn = ref false
let compileModeOn = ref false
let implicitSignature = ref false


(*Computed values*)
let (timeIncrementValue:float option ref) = ref None

(*Name convention*)
let outputDirName = ref (Sys.getcwd ())
let snapshotFileName = ref "snap"
let dir_sep = match Sys.os_type with
	| "Unix" | "Cygwin" -> "/"
	| _ -> "\\" (*Filename.dir_sep*) (* only if ocaml >= 3.11.2 otherwise use "/" *)

let (openOutDescriptors:out_channel list ref) = ref []
let (openInDescriptors:in_channel list ref) = ref []

(*Profiling*)
(*let profiling:Profiling.t = Profiling.create 10*) 
