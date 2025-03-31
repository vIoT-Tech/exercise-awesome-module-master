#! /bin/sh

. ../../testenv.sh

$GHDL fmt --std=08 --level=space print1.vhdl > print1.out
diff_nocr print1.ref print1.out

$GHDL fmt --std=08 --range=10:10 print1.vhdl > print2.out
diff_nocr print2.ref print2.out

$GHDL fmt --range=5:5 print4.vhdl > print4.out
diff_nocr print4.ref print4.out

$GHDL fmt proc1.vhdl > proc1.out
diff_nocr proc1.out proc1.vhdl

$GHDL fmt proc2.vhdl > proc2.out
diff_nocr proc2.out proc2.vhdl

echo "Test successful"
