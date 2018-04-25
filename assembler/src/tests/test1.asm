# Author: Brandon Myers

.data

#################
# INPUT instructions
#################
# number of input instructions = 4
ni: .word 4
# label1: addu $t0, $zero, $zero
TestInput: .word 2  8  0  0 0 0 0 1 0
# addu $s0, $s7, $t4
.word 2 16 23 12 0 0 0 0 0
# blt  $s0,$t0,label1
.word 100 0 16 8 0 0 0 0 1 
# addiu $s1,$s2,0xF00000
.word 1 0 18 17 0xF00000 0 0 0 0

#####################
# Phase 1 test case
#####################

# label1: addu $t0, $zero, $zero
Phase1Test: .word 2  8  0  0 0 0 0 1 0
# addu $s0, $s7, $t4
.word 2 16 23 12 0 0 0 0 0
# slt $at,$s0,$t0
# bne $at,$zero,label1
.word 8 1 16 8 0 0 0 0 0
.word 6 0 1 0 0 0 0 0 1
# lui $at, 0x00F0
# ori $at, $at 0x0000
# addu $s1,$s2,$at
.word 9 0 0 1 0x00F0 0 0 0 0
.word 10 0 1 1 0x0000 0 0 0 0
Phase1TestLast: .word 2 17 18 1 0 0 0 0 0

#######################
# Phase 2 test case
#######################
Phase2Test: .word 2 8 0 0 0 0 0 1 0
.word 2 16 23 12 0 0 0 0 0
.word 8 1 16 8 0 0 0 0 0
# translated label1 to immediate
.word 6 0 1 0 0xfffffffc 0 0 0 1
.word 9 0 0 1 0x00F0 0 0 0 0
.word 10 0 1 1 0x0000 0 0 0 0
Phase2TestLast: .word 2 17 18 1 0 0 0 0 0 

.text
###################
# Phase 3 test case
###################
# These instructions are in .text section because they
# will be translated by MARS, and then we
# will compare the binary code MARS outputed to phase 3 output
Phase3Test:	addu $t0,$zero,$zero  # Phase3Test = label1
addu $s0,$s7,$t4
blt  $s0,$t0,Phase3Test
addiu $s1,$s2,0xF00000
Phase3TestLast: # address after last TAL instruction
