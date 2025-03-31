#!/usr/bin/bash

apt install python3 python3-pip python3-venv ghdl gtkwave git
python3 -m venv venv
. venv/bin/activate # VAS: avisar product-map.ai que aquesta linia la posa abans de crear el venv
pip3 install cocotb cocotbext-axi pytest
git submodule update --recursive --init # VAS: que fa això exactament? 
            # Updates and initializes all submodules recursively in a Git repository.
            # Key Operations
            # Update submodules recursively
            # Initialize uninitialized submodules
