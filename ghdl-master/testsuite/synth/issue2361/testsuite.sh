#! /bin/sh

. ../../testenv.sh

GHDL_STD_FLAGS="--std=08 --latches"
synth_only jkff

echo "Test successful"
