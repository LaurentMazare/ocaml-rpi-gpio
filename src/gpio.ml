open Base

module Rpi_info = struct
  type t =
    { version : [ `v1 | `v2 | `v3 ]
    ; ram : string
    ; manufacturer : string
    ; processor : string
    ; type_ : string
    }

  let create () =
    let version, ram, manufacturer, processor, type_ = Gpio_bindings.get_rpi_info () in
    let version =
      match version with
      | 1 -> `v1
      | 2 -> `v2
      | 3 -> `v3
      | _ -> Printf.failwithf "unexpected rpi version %d" version ()
    in
    { version; ram; manufacturer; processor; type_ }

  let pin_to_gpio_rev1 =
    [| -1
     ; -1
     ; -1
     ; 0
     ; -1
     ; 1
     ; -1
     ; 4
     ; 14
     ; -1
     ; 15
     ; 17
     ; 18
     ; 21
     ; -1
     ; 22
     ; 23
     ; -1
     ; 24
     ; 10
     ; -1
     ; 9
     ; 25
     ; 11
     ; 8
     ; -1
     ; 7
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
    |]

  let pin_to_gpio_rev2 =
    [| -1
     ; -1
     ; -1
     ; 2
     ; -1
     ; 3
     ; -1
     ; 4
     ; 14
     ; -1
     ; 15
     ; 17
     ; 18
     ; 27
     ; -1
     ; 22
     ; 23
     ; -1
     ; 24
     ; 10
     ; -1
     ; 9
     ; 25
     ; 11
     ; 8
     ; -1
     ; 7
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
     ; -1
    |]

  let pin_to_gpio_rev3 =
    [| -1
     ; -1
     ; -1
     ; 2
     ; -1
     ; 3
     ; -1
     ; 4
     ; 14
     ; -1
     ; 15
     ; 17
     ; 18
     ; 27
     ; -1
     ; 22
     ; 23
     ; -1
     ; 24
     ; 10
     ; -1
     ; 9
     ; 25
     ; 11
     ; 8
     ; -1
     ; 7
     ; -1
     ; -1
     ; 5
     ; -1
     ; 6
     ; 12
     ; 13
     ; -1
     ; 19
     ; 16
     ; 26
     ; 20
     ; -1
     ; 21
    |]

  let pin_to_gpio t =
    match t.version with
    | `v1 -> pin_to_gpio_rev1
    | `v2 -> pin_to_gpio_rev2
    | `v3 -> pin_to_gpio_rev3
end

type t = int

let create ~channel ~mode =
  Gpio_bindings.setup ();
  let rpi_info = Rpi_info.create () in
  let invalid_channel () = Printf.failwithf "invalid channel %d" channel () in
  let valid_channel =
    match mode, rpi_info.version with
    | `bcm, _ -> channel >= 0 && channel <= 53
    | `board, (`v1 | `v2) -> channel >= 1 && channel <= 26
    | `board, `v3 -> channel >= 1 && channel <= 40
  in
  if not valid_channel then invalid_channel ();
  match mode with
  | `bcm -> channel
  | `board ->
    let channels = Rpi_info.pin_to_gpio rpi_info in
    let channel = channels.(channel) in
    if channel = -1 then invalid_channel () else channel

let setup t direction pud =
  let pud =
    match pud with
    | `off -> 0
    | `down -> 1
    | `up -> 2
  in
  let direction =
    match direction with
    | `input -> 1
    | `output -> 0
  in
  Gpio_bindings.setup_gpio t direction pud

let input t = Gpio_bindings.input_gpio t
let output t v = Gpio_bindings.output_gpio t v
