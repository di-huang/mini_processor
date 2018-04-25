.data

#################
# INPUT instructions
#################
# number of input instructions = 4
ni: .word 4
# bge $t0, $zero, label2
TestInput: .word 101 0 8 0 0 0 0 0 2
# label1: ori $t1, $s0, 0xffffffff
.word 10 0 16 9 0xffffffff 0 0 1 0
# label2: or $t2, $s5, $t4
.word 3 10 21 12 0 0 0 2 0
# addiu $t3, $s2, 0x8000
.word 1 0 18 11 0x8000 0 0 0 0

#####################
# Phase 1 test case
#####################
# slt $at, $t0, $zero
# beq $at, $zer0, label2
Phase1Test: .word 8 1 8 0 0 0 0 0 0
.word 5 0 1 0 0 0 0 0 2
# label1: lui $at, 0xffffffff (with sign)
# ori $at, $at, 0xffff
# or $t1, $s0, $at
.word 9 0 0 1 0xffffffff 0 0 1 0
.word 10 0 1 1 0xffff 0 0 0 0
.word 3 9 16 1 0 0 0 0 0
# label2: or $t2, $s5, $t4
.word 3 10 21 12 0 0 0 2 0
# lui $at, 0x0000
# ori $at, $at 0x8000
# addu $t3, $s2, $at
.word 9 0 0 1 0x0000 0 0 0 0
.word 10 0 1 1 0x8000 0 0 0 0
Phase1TestLast: .word 2 11 18 1 0 0 0 0 0

#######################
# Phase 2 test case
#######################
Phase2Test: .word 8 1 8 0 0 0 0 0 0
# translated label1 to immediate
.word 5 0 1 0 0x00000003 0 0 0 2
.word 9 0 0 1 0xffffffff 0 0 1 0
.word 10 0 1 1 0xffff 0 0 0 0
.word 3 9 16 1 0 0 0 0 0
.word 3 10 21 12 0 0 0 2 0
.word 9 0 0 1 0x0000 0 0 0 0
.word 10 0 1 1 0x8000 0 0 0 0
Phase2TestLast: .word 2 11 18 1 0 0 0 0 0

.text
###################
# Phase 3 test case
###################
# These instructions are in .text section because they
# will be translated by MARS, and then we
# will compare the binary code MARS outputed to phase 3 output
Phase3Test:
bge $t0, $zero, Phase3TestLabel2 # Phase3Test = label1
Phase3TestLabel1: ori $t1, $s0, 0xffffffff
Phase3TestLabel2: or $t2, $s5, $t4
addiu $t3, $s2, 0x8000
Phase3TestLast: # address after last TAL instruction
