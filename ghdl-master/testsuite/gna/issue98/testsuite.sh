#! /bin/sh

. ../../testenv.sh

analyze test_load.vhdl
elab test_load

if c_compiler_is_available && ghdl_has_feature test_load vpi; then
  add_vpi_path

  $GHDL --vpi-compile -v $CC -c vpi1.c
  $GHDL --vpi-link -v $CC -o vpi1.vpi vpi1.o

  simulate test_load --vpi=./vpi1.vpi

  rm -f vpi1.vpi vpi1.o
fi
clean

echo "Test successful"
