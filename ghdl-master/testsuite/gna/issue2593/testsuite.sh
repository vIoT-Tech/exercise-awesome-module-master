#! /bin/sh

. ../../testenv.sh

if ghdl_is_preelaboration; then
    export GHDL_STD_FLAGS=--std=08
    analyze tb.vhdl
    elab_simulate mode_tb

    elab_simulate -gMODE="mode_0" mode_tb
    clean
fi

echo "Test successful"
