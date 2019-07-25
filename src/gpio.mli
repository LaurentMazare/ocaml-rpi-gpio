type t

val create : channel:int -> mode:[ `bcm | `board ] -> t
val setup : t -> [ `input | `output ] -> [ `off | `down | `up ] -> unit
val input : t -> int
val output : t -> int -> unit

type pwm

val with_pwm : t -> f:(pwm -> 'a) -> 'a
val pwm_init : t -> frequency:float -> pwm
val pwm_start : pwm -> unit
val pwm_set_duty_cycle : pwm -> duty_cycle:float -> unit
val pwm_set_frequency : pwm -> frequency:float -> unit
val pwm_stop : t -> unit
