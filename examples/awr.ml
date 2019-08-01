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
    { tr : [ `output ] Gpio.t
    ; ec : [ `input ] Gpio.t
    }

  let create () =
    let tr = Gpio.create_output ~channel:23 ~mode:`board in
    let ec = Gpio.create_input ~channel:24 ~mode:`board in
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
    Gpio.close t.tr;
    Gpio.close t.ec
end

module Motors : sig
  type t

  val create : unit -> t
  val move : t -> speed_a:float -> speed_b:float -> unit
  val reset : t -> unit
end = struct
  module Motor = struct
    type t =
      { en : [ `output ] Gpio.t
      ; pin1 : [ `output ] Gpio.t
      ; pin2 : [ `output ] Gpio.t
      ; pwm : Gpio.pwm
      }

    let reset t =
      Gpio.output t.en 0;
      Gpio.output t.pin1 0;
      Gpio.output t.pin2 0

    let create a_or_b =
      let en, pin1, pin2 =
        match a_or_b with
        | `A -> 7, 37, 40
        | `B -> 11, 13, 12
      in
      let en = Gpio.create_output ~channel:en ~mode:`board in
      let pin1 = Gpio.create_output ~channel:pin1 ~mode:`board in
      let pin2 = Gpio.create_output ~channel:pin2 ~mode:`board in
      let pwm = Gpio.pwm_init en ~frequency:1000. in
      let t = { en; pin1; pin2; pwm } in
      reset t;
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
      then reset t
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

  let reset t =
    Motor.reset t.motor_a;
    Motor.reset t.motor_b
end

let navigate () =
  let motors = Motors.create () in
  let ultra = Ultrasonic.create () in
  let stopped = ref 0 in
  while !stopped < 10 do
    Unix.sleepf 0.1;
    let d = Ultrasonic.get ultra in
    Stdio.printf "%f\n%!" d;
    let speed_a, speed_b =
      if Float.(d < 0.1)
      then (
        Int.incr stopped;
        0., 0.)
      else if Float.(d < 0.6)
      then 70., -70.
      else 100., 100.
    in
    Motors.move motors ~speed_a ~speed_b
  done;
  Ultrasonic.close ultra;
  Motors.reset motors

let mode = `navigate

let () =
  match mode with
  | `navigate -> navigate ()
  | `move_forward ->
    let motors = Motors.create () in
    Motors.move motors ~speed_a:100.0 ~speed_b:100.0;
    Unix.sleepf 3.;
    Motors.reset motors
  | `ultra ->
    let ultra = Ultrasonic.create () in
    Stdio.printf "Ultra created.\n";
    for i = 1 to 10 do
      Unix.sleepf 1.;
      Stdio.printf "%d %.2f\n%!" i (Ultrasonic.get ultra)
    done;
    Ultrasonic.close ultra
