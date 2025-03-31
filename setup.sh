#!/usr/bin/bash

apt install python3 python3-pip python3-venv ghdl gtkwave git
python3 -m venv venv
. venv/bin/activate
pip3 install cocotb cocotbext-axi pytest
git submodule update --recursive --init
