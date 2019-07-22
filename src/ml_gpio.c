#include <assert.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

#include "c_gpio.h"

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
