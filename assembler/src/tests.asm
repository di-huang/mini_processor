# Author: Di Huang

.data
	# showing the title of the test case
	mesg:	.asciiz "---test1---\n"

.text
	li $v0, 4
	la $a0, mesg
	syscall

# including the test file 
.include "tests/test1.asm"

