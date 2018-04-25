# Author: Di Huang

resolve_address: # (instr(a0), pc_of_instr(a1), label_map(a2))
    subiu $sp, $sp, 16
    sw $ra, ($sp)
    sw $s7, 4($sp)
    sw $s6, 8($sp)
    sw $s5, 12($sp)
    la $s7, ($a0)			# s7 = address of instr
    la $s6, ($a1)			# s6 = address of pc_of_instr
    la $s5, ($a2)			# s5 = address of label_map
    lw $t0, ($s7)			# t0 = instr_id
    
    beq $t0, 5, resolve_there
    beq $t0, 6, resolve_there
    j resolve_end
    
    resolve_there:
    lw $t0, 32($s7)			# t0 = branch_label
    sll $t0, $t0, 2			# t0 = t0 * 4
    addu $t0, $t0, $s5			# t0 = t0 + address of label_map
    lw $t0, ($t0)			# t0 = val of $t0 = label_map[branch_label]
    subu $t0, $t0, $s6			# t0 = t0 - address of pc_of_instr
    sra $t0, $t0, 2			# t0 = t0 / 4, which needs arithmetic shifting
    subiu $t0, $t0, 1			# t0 = t0 - 1 (jump across itself) = imm
    sw $t0, 16($s7)			# fill imm in instr
    
    resolve_end:
    lw $s5, 12($sp)
    lw $s6, 8($sp)
    lw $s7, 4($sp)
    lw $ra, ($sp)
    addiu $sp, $sp, 16
    jr $ra
