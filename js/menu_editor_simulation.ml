(******************************************************************************)
(*  _  __ * The Kappa Language                                                *)
(* | |/ / * Copyright 2010-2017 CNRS - Harvard Medical School - INRIA - IRIF  *)
(* | ' /  *********************************************************************)
(* | . \  * This file is distributed under the terms of the                   *)
(* |_|\_\ * GNU Lesser General Public License Version 3                       *)
(******************************************************************************)

module Html = Tyxml_js.Html5

let simulation_options_modal_id = "simulation_options_modal"

let configuration_seed_input_id = "simulation_seed_input"

let option_seed_input =
  Html.input ~a:[
    Html.a_id configuration_seed_input_id;
    Html.a_input_type `Number;
    Html.a_class ["form-control"];
  ] ()
let option_withtrace =
  Html.input ~a:[
    Html.a_input_type `Checkbox;
    Tyxml_js.R.filter_attrib (Html.a_checked ())
      (React.S.map
         (fun s -> s.State_project.model_parameters.State_project.store_trace)
         State_project.model);
  ] ()
let decrease_font =
  Html.button ~a:[
    Html.a_button_type `Button;
    Html.a_class [ "btn"; "btn-default"; "btn-sm" ]
  ] [Html.pcdata "-"]
let increase_font =
  Html.button ~a:[
    Html.a_button_type `Button;
    Html.a_class [ "btn"; "btn-default"; "btn-lg" ]
  ] [Html.pcdata "+"]

let options_modal =
  Ui_common.create_modal
    ~id:simulation_options_modal_id
    ~title_label:"Simulation Configuration"
    ~body:[%html
            {|<div class="row">
                   <div class="col-md-1"><label for="|}configuration_seed_input_id{|">Seed</label></div>
                   <div class="col-md-5">|}[option_seed_input]{|</div>
              </div>
              <div class="row">
                <div class="col-md-offset-1 col-md-5 checkbox">
                  <label>|}[option_withtrace]{|Store trace</label>
                </div>
              </div>
              <div class="row">
                   <div class="col-md-1"><label>Font size</label></div>
                   <div class="col-md-5">|}[decrease_font; increase_font]{|</div>
</div>|}]
    ~submit_label:"Save"
    ~submit:
      (Dom_html.handler
         (fun (_ : Dom_html.event Js.t)  ->
            let input : Dom_html.inputElement Js.t =
              Tyxml_js.To_dom.of_input option_seed_input in
            let value : string = Js.to_string input##.value in
            let model_seed =
              try Some (int_of_string value) with Failure _ -> None in
            let () = State_project.set_seed model_seed in
            let () = State_project.set_store_trace
                (Js.to_bool
                   (Tyxml_js.To_dom.of_input option_withtrace)##.checked) in
            let () =
              Common.modal
                ~id:("#"^simulation_options_modal_id)
                ~action:"hide"
            in
            Js._false))

let options =
  Html.button
    ~a:[ Html.Unsafe.string_attrib "type" "button"
       ; Html.a_class ["btn"; "btn-default" ] ]
    [ Html.cdata "Simulation options" ]

let content () =
  [ options ; options_modal]


let fontSizeParamId = Js.string "kappappFontSize"
let initFontSize () =
  Js.Optdef.case
    Dom_html.window##.localStorage
    (fun () -> 1.4)
    (fun st ->
       Js.Opt.case (st##getItem fontSizeParamId) (fun () -> 1.4) Js.parseFloat)

let setFontSize v =
  let v' = string_of_float v in
  let () = Dom_html.document##.body##.style##.fontSize :=
      Js.string (v'^"em") in
  let () = Js.Optdef.iter
      Dom_html.window##.localStorage
      (fun st -> st##setItem fontSizeParamId (Js.string v')) in
  ()

let onload () =
  let () =
    (Tyxml_js.To_dom.of_button options)##.onclick :=
      Dom_html.handler
        (fun _  ->
           let input : Dom_html.inputElement Js.t =
             Tyxml_js.To_dom.of_input option_seed_input in
           let () = input##.value := Js.string
                 (match (React.S.value State_project.model).
                          State_project.model_parameters.State_project.seed with
                 | None -> ""
                 | Some model_seed -> string_of_int model_seed) in
           let () =
             Common.modal
               ~id:("#"^simulation_options_modal_id)
               ~action:"show"
           in
           Js._false) in
  let currentFontSize = ref (initFontSize ()) in
  let () = setFontSize !currentFontSize in
  let () =
    (Tyxml_js.To_dom.of_button increase_font)##.onclick :=
      Dom_html.handler
        (fun _ ->
           let () = currentFontSize :=
               min 3. (!currentFontSize +. 0.2) in
           let () = setFontSize !currentFontSize in
           Js._false) in
  let () =
    (Tyxml_js.To_dom.of_button decrease_font)##.onclick :=
      Dom_html.handler
        (fun _ ->
           let () = currentFontSize :=
               max 0.2 (!currentFontSize -. 0.2) in
           let () = setFontSize !currentFontSize in
           Js._false) in
  ()
