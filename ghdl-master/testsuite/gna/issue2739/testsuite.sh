#! /bin/sh

. ../../testenv.sh

export GHDL_STD_FLAGS=--std=08
analyze_failure mwe.vhdl

clean

echo "Test successful"
