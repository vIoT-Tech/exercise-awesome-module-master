import os
import pytest
import cocotb
import subprocess
import sys
from cocotb.runner import Command
from itertools import product # VAS: no import possible...?!
from glob import glob
from typing import List

class Ghdl(cocotb.runner.Ghdl):
    def _test_command(self) -> List[Command]:
        cmds = super()._test_command()
        
        if self.waves:
            cmds[0] += ['--vcd=../wave.vcd']

        return cmds

def _build(runner = None):
    if runner is None:
        runner = Ghdl()

    runner.build(
            vhdl_sources = glob('open-logic/src/**/*.vhd', recursive=True),
            hdl_library = 'olo',
            build_args = ['--std=08', '-frelaxed']
    )
    runner.build(
            vhdl_sources = glob('vhdl/*.vhd'),
            hdl_library = 'bl',
            build_args = ['--std=08']
    )

    # GHDL support seems to be buggy
    subprocess.run('ghdl -m --std=08 -frelaxed bl.AwesomeModule', cwd='sim_build', shell=True, check=True)

    return runner

def test_awesome_module():
    runner = _build()

    runner.test(
            test_module = 'tb.tb_awesome_module',
            hdl_toplevel = 'awesomemodule',
            hdl_toplevel_library = 'bl',
            waves = True,
            test_args = ['--std=08', '-frelaxed']
    )


