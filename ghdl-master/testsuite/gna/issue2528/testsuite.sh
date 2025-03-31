#! /bin/sh

. ../../testenv.sh

if ghdl_is_preelaboration; then
    export GHDL_STD_FLAGS=--std=08
    analyze test1.vhdl
    elab_simulate_failure test1

    analyze test2.vhdl
    elab_simulate test2

    clean
fi

echo "Test successful"
