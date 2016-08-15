(** Network/ODE generation
  * Creation: 22/07/2016
  * Last modification: Time-stamp: <Jul 29 2016>
*)

module A = Odes.Make (Dummy_interface)

let main () =
  let usage_msg =
    "KaDE "^Version.version_string^":\n"^
    "Usage is KaDE [-i] input_file [--ode-backend Matlab | Octave] [-t-init time] [-t time] [-p points] [-o output_file]\n"
  in
  let cli_args = Run_cli_args.default in
  let common_args = Common_args.default in
  let ode_args = Ode_args.default in
  let options =
    Run_cli_args.options cli_args
    @ Ode_args.options ode_args
      @ Common_args.options common_args
  in
  try
    Arg.parse
      options
      (fun fic ->
         cli_args.Run_cli_args.inputKappaFileNames <-
           fic::(cli_args.Run_cli_args.inputKappaFileNames))
      usage_msg;
    let () = Kappa_files.set_data cli_args.Run_cli_args.outputDataFile in
    let () = Kappa_files.set_dir cli_args.Run_cli_args.outputDirectory in
    (*  let () = match kasim_args.Kasim_args.marshalizeOutFile with
        | None -> ()
        | Some marshalizeOutFile ->
        Kappa_files.set_marshalized marshalizeOutFile
        in*)
    (*  let () = match kasim_args.Kasim_args.domainOutputFile with
        | None -> ()
        | Some domainOutputFile ->
        Kappa_files.set_ccFile domainOutputFile
        in*)
    (*  let () = match kasim_args.Kasim_args.traceFile with
        | None -> ()
        | Some traceFile ->
        Kappa_files.set_traceFile traceFile
        in*)
    let () = Parameter.debugModeOn := common_args.Common_args.debug in
    (*  let () = Parameter.eclipseMode := kasim_args.Kasim_args.eclipseMode in*)
    (*let () = Parameter.emacsMode := kasim_args.Kasim_args.emacsMode in*)
    (*let () = Parameter.compileModeOn := kasim_args.Kasim_args.compileMode in*)
    let () = Parameter.batchmode := cli_args.Run_cli_args.batchmode in
    (*let () =
      Parameter.time_independent := common_args.Common_args.timeIndependent*)
    let backend =
      match ode_args.Ode_args.backend with
      | "Octave" | "OCTAVE" | "octave" -> Loggers.Octave
      | "Matlab" | "MATLAB" | "matlab" -> Loggers.Matlab
      | s ->
        begin
          Arg.usage options usage_msg;
          Debug.tag
            Format.std_formatter
            ("Wrong option "^s^".\nOnly matlab and octave backends are supported.");
          exit 0
        end
    in
    let abort =
      match cli_args.Run_cli_args.inputKappaFileNames with
      | [] -> cli_args.Run_cli_args.marshalizedInFile = ""
      | _ -> false
    in
    if abort then (prerr_string usage_msg ; exit 1) ;
    let () = Sys.catch_break true in
    let () =
      Kappa_files.setCheckFileExistsODE ~batchmode:!Parameter.batchmode in
    let command_line =
      Format.asprintf "%a"
        (Pp.array (fun f -> Format.fprintf f " ")
           (fun i f s ->
              Format.fprintf
                f "%s" (if i = 0 then "KaDE" else s)))
        Sys.argv
    in
    let command_line_quotes =
      Format.asprintf "%a"
        (Pp.array Pp.space
           (fun i f s ->
              Format.fprintf
                f "'%s'" (if i = 0 then "KaDE" else s)))
        Sys.argv
    in
    let (env,contact_map,init) = A.get_compil common_args cli_args in
    let network = A.network_from_compil env contact_map init in
    let out_channel = Kappa_files.open_out (Kappa_files.get_ode ()) in
    let logger = Loggers.open_logger_from_channel ~mode:backend out_channel in
    let () = A.export_network
        ~command_line
        ~command_line_quotes
        ~data_file:(Kappa_files.get_data ())
        ~init_t:cli_args.Run_cli_args.minTimeValue
        ~max_t:(Tools.unsome 1. cli_args.Run_cli_args.maxTimeValue)
        ~nb_points:cli_args.Run_cli_args.pointNumberValue
        logger env network
    in
    let () = Loggers.flush_logger logger in
    let () = close_out out_channel in
    ()
  with
  | ExceptionDefn.Malformed_Decl er ->
    let () = ExceptionDefn.flush_warning Format.err_formatter in
    let () = Kappa_files.close_all_out_desc () in
    let () = Pp.error Format.pp_print_string er in
    exit 2
  | Sys_error msg ->
    let () = ExceptionDefn.flush_warning Format.err_formatter in
    let () = Kappa_files.close_all_out_desc () in
    let () = Format.eprintf "%s@." msg in
    exit 2
  | e ->
    let () = Format.pp_print_flush Format.err_formatter () in raise e

let () = main ()
