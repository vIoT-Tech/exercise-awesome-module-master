#! /bin/sh

. ../../testenv.sh

GHDL_STD_FLAGS=--std=08
analyze test.vhdl
elab_simulate test

analyze test2.vhdl
elab_simulate test2

clean

echo "Test successful"
