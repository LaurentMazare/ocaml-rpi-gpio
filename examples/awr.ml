(* Adeept AWR robot control. *)
open Base
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
    Gpio.output tr 0;
    Gpio.setup tr `output `off;
    Gpio.setup ec `input `off;
    { tr; ec }

  let rec loop_until ~f = if f () then () else loop_until ~f

  let get t =
    Gpio.output t.tr 1;
    Unix.sleepf 15e-6;
    Gpio.output t.tr 0;
    loop_until ~f:(fun () -> Gpio.input t.ec <> 0);
    let start_time = Unix.gettimeofday () in
    loop_until ~f:(fun () -> Gpio.input t.ec = 0);
    let stop_time = Unix.gettimeofday () in
    (stop_time -. start_time) *. 340. /. 2.

  let close t =
    Gpio.setup t.tr `input `off;
    Gpio.setup t.ec `input `off
end

module Motors : sig
  type t

  val create : unit -> t
  val move : t -> speed_a:float -> speed_b:float -> unit
  val stop : t -> unit
end = struct
  module Motor = struct
    type t =
      { en : Gpio.t
      ; pin1 : Gpio.t
      ; pin2 : Gpio.t
      ; pwm : Gpio.pwm
      }

    let stop t =
      Gpio.output t.en 0;
      Gpio.output t.pin1 0;
      Gpio.output t.pin2 0

    let create a_or_b =
      let en, pin1, pin2 =
        match a_or_b with
        | `A -> 7, 37, 40
        | `B -> 11, 13, 12
      in
      let en = Gpio.create ~channel:en ~mode:`board in
      let pin1 = Gpio.create ~channel:pin1 ~mode:`board in
      let pin2 = Gpio.create ~channel:pin2 ~mode:`board in
      Gpio.setup en `output `off;
      Gpio.setup pin1 `output `off;
      Gpio.setup pin2 `output `off;
      let pwm = Gpio.pwm_init en ~frequency:1000. in
      let t = { en; pin1; pin2; pwm } in
      stop t;
      t

    let forward t ~speed =
      Gpio.output t.pin1 1;
      Gpio.output t.pin2 0;
      Gpio.pwm_set_duty_cycle t.pwm ~duty_cycle:100.0;
      Gpio.pwm_start t.pwm;
      Gpio.pwm_set_duty_cycle t.pwm ~duty_cycle:speed

    let backward t ~speed =
      Gpio.output t.pin1 0;
      Gpio.output t.pin2 1;
      Gpio.pwm_set_duty_cycle t.pwm ~duty_cycle:100.0;
      Gpio.pwm_start t.pwm;
      Gpio.pwm_set_duty_cycle t.pwm ~duty_cycle:speed

    let move t ~speed =
      if Float.( = ) speed 0.
      then stop t
      else if Float.( > ) speed 0.
      then forward t ~speed
      else backward t ~speed:(-.speed)
  end

  type t =
    { motor_a : Motor.t
    ; motor_b : Motor.t
    }

  let create () =
    let motor_a = Motor.create `A in
    let motor_b = Motor.create `B in
    { motor_a; motor_b }

  let move t ~speed_a ~speed_b =
    Motor.move t.motor_a ~speed:speed_a;
    Motor.move t.motor_b ~speed:speed_b

  let stop t =
    Motor.stop t.motor_a;
    Motor.stop t.motor_b
end

let mode = `move

let () =
  match mode with
  | `move ->
    let motors = Motors.create () in
    Motors.move motors ~speed_a:100.0 ~speed_b:100.0;
    Unix.sleepf 3.;
    Motors.stop motors
  | `ultra ->
    let ultra = Ultrasonic.create () in
    Stdio.printf "Ultra created.\n";
    for i = 1 to 10 do
      Unix.sleepf 1.;
      Stdio.printf "%d %.2f\n%!" i (Ultrasonic.get ultra)
    done;
    Ultrasonic.close ultra
