#include <assert.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

#include "c_gpio.h"
#include "cpuinfo.h"
#include "soft_pwm.h"

#define SETUP_OK           0
#define SETUP_DEVMEM_FAIL  1
#define SETUP_MALLOC_FAIL  2
#define SETUP_MMAP_FAIL    3
#define SETUP_CPUINFO_FAIL 4
#define SETUP_NOT_RPI_FAIL 5

int module_setup = 0;

value ml_setup(value unit) {
  CAMLparam1(unit);
  if (module_setup == 0) {
    int status = setup();
    if (status == SETUP_DEVMEM_FAIL)
      caml_failwith("No access to /dev/mem");
    else if (status == SETUP_MALLOC_FAIL)
      caml_failwith("Malloc failed");
    else if (status == SETUP_MMAP_FAIL)
      caml_failwith("Mmap of GPIO registers failed");
    else if (status == SETUP_CPUINFO_FAIL)
      caml_failwith("Unable to open /proc/cpuinfo");
    else if (status == SETUP_NOT_RPI_FAIL)
      caml_failwith("Not running on a RPi");
    else if (status == SETUP_OK)
      module_setup = 1;
    else
      caml_failwith("unexpected error during setup");
  }
  CAMLreturn(Val_unit);
}

value ml_cleanup(value unit) {
  CAMLparam1(unit);
  cleanup();
  CAMLreturn(Val_unit);
}

value ml_setup_gpio(value gpio, value direction, value pud) {
  CAMLparam3(gpio, direction, pud);
  setup_gpio(Int_val(gpio), Int_val(direction), Int_val(pud));
  CAMLreturn(Val_unit);
}

value ml_input_gpio(value gpio) {
  CAMLparam1(gpio);
  int r = input_gpio(Int_val(gpio));
  CAMLreturn(Val_int(r));
}

value ml_output_gpio(value gpio, value v) {
  CAMLparam2(gpio, v);
  output_gpio(Int_val(gpio), Int_val(v));
  CAMLreturn(Val_unit);
}

value ml_gpio_function(value gpio) {
  CAMLparam1(gpio);
  int r = gpio_function(Int_val(gpio));
  CAMLreturn(Val_int(r));
}

value ml_get_rpi_info(value unit) {
  CAMLparam1(unit);
  rpi_info rpi_info;
  int res = get_rpi_info(&rpi_info);
  if (res != 0) caml_failwith("get_rpi_info failed");

  CAMLlocal1(out);
  out = caml_alloc_tuple(5);
  Store_field(out, 0, Val_int(rpi_info.p1_revision));
  Store_field(out, 1, caml_copy_string(rpi_info.ram));
  Store_field(out, 2, caml_copy_string(rpi_info.manufacturer));
  Store_field(out, 3, caml_copy_string(rpi_info.processor));
  Store_field(out, 4, caml_copy_string(rpi_info.type));
  CAMLreturn(out);
}

value ml_pwm_start(value gpio) {
  CAMLparam1(gpio);
  pwm_start(Int_val(gpio));
  CAMLreturn(Val_unit);
}

value ml_pwm_stop(value gpio) {
  CAMLparam1(gpio);
  pwm_stop(Int_val(gpio));
  CAMLreturn(Val_unit);
}

value ml_pwm_exists(value gpio) {
  CAMLparam1(gpio);
  int r = pwm_exists(Int_val(gpio));
  CAMLreturn(Val_int(r));
}

value ml_pwm_set_duty_cycle(value gpio, value dutycycle) {
  CAMLparam2(gpio, dutycycle);
  double d = Double_val(dutycycle);
  if (d < 0) caml_failwith("Negative duty cycle.");
  if (d > 100) caml_failwith("Duty cycle greater than 100.");
  pwm_set_duty_cycle(Int_val(gpio), d);
  CAMLreturn(Val_unit);
}

value ml_pwm_set_frequency(value gpio, value freq) {
  CAMLparam2(gpio, freq);
  double f = Double_val(freq);
  if (f <= 0) caml_failwith("Non-positive frequency.");
  pwm_set_frequency(Int_val(gpio), f);
  CAMLreturn(Val_unit);
}
