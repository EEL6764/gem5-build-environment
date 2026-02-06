from gem5.components.boards.simple_board import SimpleBoard
from gem5.components.cachehierarchies.classic.private_l1_private_l2_cache_hierarchy import (
    PrivateL1PrivateL2CacheHierarchy,
)
from gem5.components.memory.single_channel import SingleChannelDDR4_2400
from gem5.resources.resource import BinaryResource
from gem5.simulate.simulator import Simulator
from gem5.isas import ISA

from gem5.components.processors.base_cpu_core import BaseCPUCore
from gem5.components.processors.base_cpu_processor import BaseCPUProcessor

from m5.objects import X86O3CPU
from m5.objects import TournamentBP
from m5.objects import InstCsvTrace

import m5
import os
from pathlib import Path


class MyOutOfOrderCore(BaseCPUCore):
    def __init__(self, width, rob_size, num_int_regs, num_fp_regs):
        core = X86O3CPU()
        core.fetchWidth = width
        core.decodeWidth = width
        core.renameWidth = width
        core.dispatchWidth = width
        core.issueWidth = width
        core.wbWidth = width
        core.commitWidth = width

        core.numROBEntries = rob_size
        core.numPhysIntRegs = num_int_regs
        core.numPhysFloatRegs = num_fp_regs

        core.branchPred = TournamentBP()

        inst_trace = InstCsvTrace()
        inst_trace.trace_file = "inst_trace.csv"
        inst_trace.trace_fetch = True
        inst_trace.trace_mem = True
        inst_trace.start_after_inst = 0
        inst_trace.stop_after_inst = 0
        core.probeListener = inst_trace

        super().__init__(core, ISA.X86)


class MyOutOfOrderProcessor(BaseCPUProcessor):
    def __init__(self, width, rob_size, num_int_regs, num_fp_regs):
        super().__init__(
            cores=[MyOutOfOrderCore(width, rob_size, num_int_regs, num_fp_regs)]
        )


main_memory = SingleChannelDDR4_2400(size="4GB")

cache_hierarchy = PrivateL1PrivateL2CacheHierarchy(
    l1d_size="1kB", l1i_size="1kB", l2_size="8kB"
)

my_ooo_processor = MyOutOfOrderProcessor(
    width=8, rob_size=192, num_int_regs=256, num_fp_regs=256
)

board = SimpleBoard(
    processor=my_ooo_processor,
    memory=main_memory,
    cache_hierarchy=cache_hierarchy,
    clk_freq="3GHz",
)

binary_path = Path(__file__).parent.parent.parent / "programs" / "mm_bench"
board.set_se_binary_workload(
    binary=BinaryResource(local_path=str(binary_path)),
    arguments=["-n", "32", "-repeat", "3", "-kernel", "ijk", "-check"],
)

simulator = Simulator(board)

outdir = m5.options.outdir

simulator.add_text_stats_output(os.path.join(outdir, "stats.txt"))
simulator.add_json_stats_output(os.path.join(outdir, "stats.json"))

simulator.run()
