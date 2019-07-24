module Gpio = Rpi_gpio.Gpio

let () =
  let gpio = Gpio.create ~channel:42 ~mode:`board in
  Gpio.setup gpio `input `off
