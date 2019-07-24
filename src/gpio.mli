type t

val create : channel:int -> mode:[ `bcm | `board ] -> t
val setup : t -> [ `input | `output ] -> [ `off | `down | `up ] -> unit
val input : t -> int
val output : t -> int -> unit

type pwm

val with_pwm : t -> f:(pwm -> 'a) -> 'a
