# class Instruction {    // byte offsets
#   int instruction_id;   // 0
#   int rd;               // 4
#   int rs;               // 8
#   int rt;               // 12
#   int immediate;        // 16
#   int jump_address;     // 20
#   int shift_amount;     // 24
#   int label_id;         // 28     0 means none; 1+ means id
#   int branch_label      // 32
#}
#
#sizeof(Instruction) = 36 Bytes

.macro printstring (%label)
li $v0, 4
la $a0, %label
syscall
.end_macro

.macro printhex (%reg)
li $v0, 34
move $a0, %reg
syscall
.end_macro

.include "tests.asm"

.data

#####################
# Error messages
#####################
failtest: .asciiz "Failed test"
failtestbyte: .asciiz "Failed test on byte "
fail_unrecognized: .asciiz "Fail: unrecognized instruction id "

#####################
# Log messages
#####################
phase1testmsg: .asciiz "Starting Phase1Test\n"
phase2testmsg: .asciiz "Starting Phase2Test\n"
phase3testmsg: .asciiz "Starting Phase3Test\n"
donemsg: .asciiz "Finished assembly"


.text
j main


################################
# Helper functions
################################
	
check_bytes: # addr1,addr2,endaddr1
	addiu $sp,$sp,-4 
	sw $ra,0($sp)
check_bytes_loop:
	beq $a0,$a2,check_bytes_success
	lb $t0,0($a0)
	lb $t1,0($a1)
	bne $t0,$t1,check_bytes_fail
	addiu $a0,$a0,1
	addiu $a1,$a1,1
	j check_bytes_loop
check_bytes_fail:
	move $s0, $a0 # fine to trample $s0,$s1 because assert fail only
	move $s1, $a1
	printstring (failtestbyte) # print message
	printhex ($s0) # print byte address
	li $v0, 11
	li $a0, ' '
	syscall
	printhex ($s1)    # print byte address
	j exit
check_bytes_success:
	lw $ra,0($sp)
	addiu $sp,$sp,4
	jr $ra

# We have check_word and check_bytes because
# MARS only allows reading word-aligned words from text segment
check_words: #addr1,addr2,endaddr1
	addiu $sp,$sp,-4 
	sw $ra,0($sp)
check_words_loop:
	beq $a0,$a2,check_words_success
	lw $t0,0($a0)
	lw $t1,0($a1)
	bne $t0,$t1,check_bytes_fail
	addiu $a0,$a0,4
	addiu $a1,$a1,4
	j check_words_loop
check_words_success:
	lw $ra,0($sp)
	addiu $sp,$sp,4
	jr $ra
##################################


main:
# SETUP 
	la $t0, ni       # s7=number of instructions
	lw $s7,0($t0)
	
	mul $a0,$s7,36    # allocate TAL buffer for 3x more instructions (3*36B*ni)
	mul $a0,$a0,3
	li $v0, 9
	syscall
	move $s4,$v0     # s4=base address of TAL buffer
	move $s3,$s4         # s3=TAL buffer current ptr

#######################	
# PHASE ONE: MAL to TAL
#######################
	li $s6, 0    # s6=[0..number of instructions)
	la $s5, TestInput    # s5=base address of input instructions
translate_mal_to_tal_loop:
	beq $s6,$s7,end_mal_to_tal_loop
	mul $t0,$s6,36   # byte index = sizeof(inst)*i = 36*i
	addu $s0,$s5,$t0  # calculate inst address

	move $a0, $s0
	move $a1, $s3
	jal mal_to_tal   # (a0=$s0 instr, a1=$s3 ptr)
	  
	mul $v0,$v0,36    # increment TAL buffer ptr
	addu $s3,$s3,$v0  # increment TAL ptr
	addiu $s6,$s6,1
	j translate_mal_to_tal_loop
end_mal_to_tal_loop:

# TEST PHASE 1
printstring (phase1testmsg)
la $a0,Phase1Test     #first
move $a1,$s4
la $a2,Phase1TestLast   # calculate last+1 byte address
addiu $a2,$a2,36
jal check_bytes

#################################
# Phase 2: resolve addresses
#################################
move $s5,$s3   # get end of TAL array
move $s3,$s4   # point to beginning of TAL array
subu $s5,$s5,$s3   # s5=get new num instructions
divu $s5,$s5,36

# allocate 4*instructions bytes for labels
move $a0,$s5
sll  $a0,$a0,2
li $v0,9
syscall
move $s7,$v0   #s7=base of label_map
# allocate 4*instructions bytes for instructions
move $a0,$s5
sll  $a0,$a0,2
li $v0,9
syscall
move $s0,$v0   #s0=base of future binary instructions

# Phase 2: PASS ONE: building label_map

move $s2,$zero  #s2=index into TAL array
pass1loop:
beq $s2,$s5,pass1done
lw $t0, 28($s3)
beqz $t0,dont_set_label
sll $t1,$t0,2   # address = base+4*label_id
addu $t1,$t1,$s7
sll $t2,$s2,2      # calculate address of the line
addu $t2,$t2,$s0  
sw $t2, 0($t1)    # label_map[label_id]=instruction address
dont_set_label:
addiu $s2,$s2,1
addiu $s3,$s3,36
j pass1loop
pass1done:

# registers at this point
# s0 = base of future instructions
# s7 = base of label_map
# s4 = base of TAL array
# s5 = num TAL instructions

# Phase 2: PASS TWO: resolve branch addresses using label_map

move $s3,$s4   # s3=ptr into TAL array
move $s1,$zero  #s1=index into TAL array
pass2loop:
beq $s1,$s5,pass2done
sll $a1,$s1,2  # calculate future address of current instr
addu $a1,$a1,$s0
move $a0,$s3
move $a2,$s7
jal resolve_address

addiu $s3,$s3,36
addiu $s1,$s1,1
j pass2loop
pass2done:

# registers at this point
# s0 = base of future instructions
# s4 = base of TAL array
# s5 = num TAL instructions

# Test that phase 2 is correct
printstring (phase2testmsg)
la   $a0,Phase2Test
move $a1,$s4
la $a2,Phase2TestLast   # calculate last+1 byte address
addiu $a2,$a2,36
jal check_bytes

# Phase 3
move $s6,$zero # index of TAL array
move $s3,$s4   # ptr into TAL array
move $s1,$s0   # ptr into instructions
trans_loop:
beq $s6,$s5,trans_loop_done
move $a0,$s3  # call translate_instruction
jal translate_instruction
sw $v0, 0($s1)
addiu $s6,$s6,1
addiu $s3,$s3,36
addiu $s1,$s1,4
j trans_loop
trans_loop_done:

# final test for phase 3
printstring (phase3testmsg)
la $a0, Phase3Test
move $a1, $s0
la $a2, Phase3TestLast
jal check_words

printstring (donemsg)
j exit


fail:
	printstring (failtest)
	j exit

fail_unrecognized_instr_id:
	printstring (fail_unrecognized)
	j exit


.include "mal_to_tal.asm"
.include "resolve_address.asm"
.include "translate_instruction.asm"

exit:
	li $v0, 10
	syscall
