#! /bin/sh

. ../../testenv.sh

export GHDL_STD_FLAGS=--std=08

if ghdl_is_preelaboration; then
    analyze streamtb.vhdl
    elab_simulate streamtb --fst=streamtb.fst
    clean
fi


echo "Test successful"
