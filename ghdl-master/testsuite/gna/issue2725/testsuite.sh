#! /bin/sh

. ../../testenv.sh

export GHDL_STD_FLAGS=--std=08
analyze mwe.vhdl
elab_simulate mwe

clean

echo "Test successful"
