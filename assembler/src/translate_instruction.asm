# Author: Di Huang

.macro setTop4Digits(%opcode, %rs, %rt)
    addu $t0, $0, %opcode
    addu $t1, $0, %rs
    addu $t2, $0, %rt
    sll $t0, $t0, 10
    sll $t1, $t1, 5
    addu $t0, $t0, $t1
    addu $t0, $t0, $t2
    sll $t0, $t0, 16
    addu $v0, $v0, $t0
.end_macro

.macro setBot4Digits(%rd, %fun)
    addu $t0, $0, %rd
    addu $t1, $0, %fun
    sll $t0, $t0, 11
    addu $t0, $t0, $t1
    addu $v0, $v0, $t0
.end_macro

translate_instruction: # ($a0 = instr) => 32-bit binary MIPS instruction
    subiu $sp, $sp, 20
    sw $ra, ($sp)
    sw $s7, 4($sp)
    sw $s6, 8($sp)
    sw $s5, 12($sp)
    sw $s4, 16($sp)
    addiu $v0, $0, 0
    lw $s7, 4($a0)				# s7 = Rd
    lw $s6, 8($a0)				# s6 = Rs
    lw $s5, 12($a0)				# s5 = Rt
    lw $s4, 16($a0)				# s4 = imm
    andi $s4, $s4, 0x0000ffff
    lw $t0, ($a0)				# t0 = instr_id
    
    # I-type
    beq $t0, 1,  ADDIU 				
    beq $t0, 5,  BEQ				
    beq $t0, 6,  BNE				
    beq $t0, 9,  LUI				
    beq $t0, 10, ORI				
    # R-type
    beq $t0, 2,  ADDU				
    beq $t0, 3,  OR			
    beq $t0, 8,  SLT				
    # unused
    beq $t0, 0, UNUSED				
    # invalid instr
    jal fail_unrecognized_instr_id

    ADDIU:
    addiu $t0, $0, 9
    j Itype
    
    BEQ:
    addiu $t0, $0, 4
    j Itype
    
    BNE:
    addiu $t0, $0, 5
    j Itype
    
    LUI:
    addiu $t0, $0, 15
    j Itype
    
    ORI:
    addiu $t0, $0, 13
    j Itype
    
    ADDU:
    addiu $t0, $0, 0
    addiu $t3, $0, 33
    j Rtype
    
    OR:
    addiu $t0, $0, 0
    addiu $t3, $0, 37
    j Rtype
    
    SLT:
    addiu $t0, $0, 0
    addiu $t3, $0, 42
    j Rtype
    
    UNUSED:
    addiu $v0, $0, 0
    j translate_end
    
    Itype:
    setTop4Digits($t0, $s6, $s5)
    addu $v0, $v0, $s4
    j translate_end
    
    Rtype:
    setTop4Digits($t0, $s6, $s5)
    setBot4Digits($s7, $t3)
    j translate_end
    
    translate_end:
    lw $s4, 16($sp)
    lw $s5, 12($sp)
    lw $s6, 8($sp)
    lw $s7, 4($sp)
    lw $ra, ($sp)
    addiu $sp, $sp, 20
    jr $ra
