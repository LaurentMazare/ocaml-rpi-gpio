external setup : unit -> unit = "ml_setup"
external cleanup : unit -> unit = "ml_cleanup"
external setup_gpio : int -> int -> int -> unit = "ml_setup_gpio"
external input_gpio : int -> int = "ml_input_gpio"
external output_gpio : int -> int -> unit = "ml_output_gpio"
external gpio_function : int -> int = "ml_gpio_function"

external get_rpi_info
  :  unit
  -> int * string * string * string * string
  = "ml_get_rpi_info"

external pwm_start : int -> unit = "ml_pwm_start"
external pwm_stop : int -> unit = "ml_pwm_stop"
external pwm_exists : int -> int = "ml_pwm_exists"
external pwm_set_duty_cycle : int -> float -> unit = "ml_pwm_set_duty_cycle"
external pwm_set_frequency : int -> float -> unit = "ml_pwm_set_frequency"
