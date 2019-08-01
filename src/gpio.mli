type _ t

val create_input : channel:int -> mode:[ `bcm | `board ] -> [ `input ] t
val create_output : channel:int -> mode:[ `bcm | `board ] -> [ `output ] t
val input : [ `input ] t -> int
val output : [ `output ] t -> int -> unit
val close : _ t -> unit

type pwm

val with_pwm : [ `output ] t -> f:(pwm -> 'a) -> 'a
val pwm_init : [ `output ] t -> frequency:float -> pwm
val pwm_start : pwm -> unit
val pwm_set_duty_cycle : pwm -> duty_cycle:float -> unit
val pwm_set_frequency : pwm -> frequency:float -> unit
val pwm_stop : pwm -> unit
