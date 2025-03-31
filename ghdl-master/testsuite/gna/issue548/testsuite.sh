#! /bin/sh

. ../../testenv.sh

if ghdl_is_preelaboration; then
  export GHDL_STD_FLAGS=--std=08
  analyze tb.vhdl
  elab_simulate tb --stop-time=1us

  clean
fi

echo "Test successful"
