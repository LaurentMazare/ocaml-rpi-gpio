module Gpio = Rpi_gpio.Gpio

let () =
  let gpio = Gpio.create ~channel:42 ~mode:`board in
  Stdio.printf "GPIO created.";
  Gpio.setup gpio `input `off
