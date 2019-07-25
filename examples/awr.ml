(* Adeept AWR robot control. *)
module Gpio = Rpi_gpio.Gpio

module Ultrasonic : sig
  type t

  val create : unit -> t
  val get : t -> float
  val close : t -> unit
end = struct
  type t =
    { tr : Gpio.t
    ; ec : Gpio.t
    }

  let create () =
    let tr = Gpio.create ~channel:23 ~mode:`board in
    let ec = Gpio.create ~channel:24 ~mode:`board in
    Gpio.setup tr `output `off;
    Gpio.output tr 0;
    Gpio.setup ec `input `off;
    { tr; ec }

  let rec loop_until ~f =
    if f ()
    then ()
    else (
      Unix.sleepf 5e-6;
      loop_until ~f)

  let get t =
    Gpio.output t.tr 1;
    Unix.sleepf 15e-6;
    Gpio.output t.tr 0;
    loop_until ~f:(fun () -> Gpio.input t.ec = 0);
    let start_time = Unix.gettimeofday () in
    loop_until ~f:(fun () -> Gpio.input t.ec <> 0);
    let stop_time = Unix.gettimeofday () in
    (stop_time -. start_time) *. 340. /. 2.

  let close t =
    Gpio.setup t.tr `input `off;
    Gpio.setup t.ec `input `off
end

let () =
  let ultra = Ultrasonic.create () in
  Stdio.printf "Ultra created.\n";
  for i = 1 to 10 do
    Unix.sleepf 1.;
    Stdio.printf "%d %.2f\n%!" i (Ultrasonic.get ultra)
  done;
  Ultrasonic.close ultra
