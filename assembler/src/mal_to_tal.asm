# Author: Di Huang
.macro isTal(%lower, %upper)
    lw $t0, 16($s7)				# t0 = imm, s7 = address of instr
    ble $t0, %upper, isTal_AND			# <= %upper
    j isTal_DONE
    isTal_AND: bge $t0, %lower, alreadyTAL	# >= %lower
    isTal_DONE:
.end_macro

.macro common_addiu_ori(%id)
    addiu $t0, $0, 9				# lui: get id
    sw $t0, ($s6)				# set id
    addiu $t0, $0, 1				# get $at
    sw $t0, 12($s6)				# set Rt
    lw $t1, 16($s7)				# get imm
    sra $t0, $t1, 16				# get upper 4 digit (with sign)
    sw $t0, 16($s6)				# set upper 4 digits
    lw $t0, 28($s7)				# get label_id
    sw $t0, 28($s6)				# set label_id
    addiu $t0, $0, 10				# ori: get id
    sw $t0, 36($s6)				# set id
    addiu $t0, $0, 1				# get $at
    sw $t0, 44($s6)				# set Rs
    sw $t0, 48($s6)				# set Rt
    andi $t0, $t1, 0xffff			# get lower 4 digits
    sw $t0, 52($s6)				# set lower 4 digits
    addiu $t0, $0, %id				# addu/or: get id
    sw $t0, 72($s6)				# set id
    lw $t0, 12($s7)				# get Rt of src
    sw $t0, 76($s6)				# set Rd of dest
    lw $t0, 8($s7)				# get Rs
    sw $t0, 80($s6)				# set Rs
    addiu $t0, $0, 1				# get $at
    sw $t0, 84($s6)				# set Rt
    addiu $v0, $0, 3
    j mal_to_tal_end
.end_macro

.macro common_blt_bge(%id)
    addiu $t0, $0, 8				# slt: get id
    sw $t0, ($a1)				# set id	
    addiu $t0, $0, 1		        	# get $at
    sw $t0, 4($a1)				# set Rd
    lw $t0, 8($a0)				# get Rs
    sw $t0, 8($a1)				# set Rs
    lw $t0, 12($a0)				# get Rt
    sw $t0, 12($a1)  				# set Rt
    lw $t0, 28($a0)				# get label_id
    sw $t0, 28($a1)				# set label_id
    addiu $t0, $0, %id				# bne/beq: get id
    sw $t0, 36($a1)				# set id
    addiu $t0, $0, 1				# get $at
    sw $t0, 44($a1)				# set Rs
    sw $0, 48($a1)				# set Rt
    lw $t0, 32($a0)				# get branch_label
    sw $t0, 68($a1)				# set branch_label
    addiu $v0, $0, 2
    j mal_to_tal_end
.end_macro

mal_to_tal: # (instr(a0), buffer(a1)) => num of instrs generated(v0)
    subiu $sp, $sp, 16
    sw $ra, ($sp)
    sw $s7, 4($sp)
    sw $s6, 8($sp)
    sw $s5, 12($sp)
    la $s7, ($a0)				# s7 = address of instr to be converted
    la $s6, ($a1)				# s6 = address of buffer storing converted instr
    lw $s5, ($s7)				# s5 = instr_id

    beq $s5, 2, alreadyTAL			# addu
    beq $s5, 3, alreadyTAL			# or
    beq $s5, 5, alreadyTAL			# beq
    beq $s5, 6, alreadyTAL			# bne
    beq $s5, 8, alreadyTAL			# slt
    beq $s5, 9, alreadyTAL			# lui
    beq $s5, 1, addiuMAL			# addiu
    beq $s5, 10, oriMAL				# ori
    beq $s5, 100, bltMAL			# blt
    beq $s5, 101, bgeMAL			# bge
    jal fail_unrecognized_instr_id		# invalid instr

    alreadyTAL:
    jal copy_instruction
    addiu $v0, $0, 1
    j mal_to_tal_end
    
    addiuMAL:
    isTal(-32768,32767)
    common_addiu_ori(2)
    
    oriMAL:
    isTal(0,65535)
    common_addiu_ori(3)
    
    bltMAL:
    common_blt_bge(6)
    
    bgeMAL:
    common_blt_bge(5)
    
    mal_to_tal_end:
    lw $s5, 12($sp)
    lw $s6, 8($sp)
    lw $s7, 4($sp)
    lw $ra, ($sp)
    addiu $sp, $sp, 16
    jr $ra

memcpy: # (src(a0), dest(a1), n(a2)), which must be recursive
    subiu $sp, $sp, 4
    sw $ra, ($sp)
    beq $a2, 0, recur_done			# base case: n == 0
    lbu $t0, ($a0)				# load 1 byte from SRC
    sb $t0, ($a1)				# store 1 byte to DEST
    addiu $a0, $a0, 1				# increase src by 1
    addiu $a1, $a1, 1				# increase dest by 1
    subiu $a2, $a2, 1				# decrease n by 1
    jal memcpy					# recursive cases
    recur_done:
    lw $ra, ($sp)
    addiu $sp, $sp, 4
    jr $ra

copy_instruction: # (srcs(a0), dest(a1))
    subiu $sp, $sp, 4
    sw $ra, ($sp)
    la $a0, ($s7)
    la $a1, ($s6)
    addiu $a2, $0, 36				# 9 words = 36 bytes
    jal memcpy
    lw $ra, ($sp)
    addiu $sp, $sp, 4
    jr $ra
