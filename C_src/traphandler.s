	.file	"traphandler.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.start,"ax",@progbits
	.align	2
	.globl	_start
	.type	_start, @function
_start:
.LFB0:
	.cfi_startproc
#APP
# 86 "traphandler.c" 1
	li sp, 0x1000       
	call main                
	1:  j 1b                 
	
# 0 "" 2
#NO_APP
	nop
	.cfi_endproc
.LFE0:
	.size	_start, .-_start
	.text
	.align	2
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
.LFB1:
	.cfi_startproc
#APP
# 108 "traphandler.c" 1
	   addi   sp, sp, -64       
	   sw     ra,  0(sp)        
	   sw     t0,  4(sp)        
	   sw     t1,  8(sp)        
	   sw     t2, 12(sp)        
	   sw     t3, 16(sp)        
	   sw     t4, 20(sp)        
	   sw     t5, 24(sp)        
	   sw     a0, 28(sp)        
	   sw     a1, 32(sp)        
	   sw     a2, 36(sp)        
	   sw     a3, 40(sp)        
	   sw     a4, 44(sp)        
	   sw     a5, 48(sp)        
	   sw     a6, 52(sp)        
	   sw     a7, 56(sp)        
	   nop                      
	   nop                      
	   nop                      
	
# 0 "" 2
#NO_APP
	li	a5,128
#APP
# 131 "traphandler.c" 1
	add zero, zero, a5 
	add zero, zero, a5 
	csrc mip, a5
# 0 "" 2
#NO_APP
	li	a5,536870912
	addi	a5,a5,260
	li	a4,65536
	addi	a4,a4,-1
	sw	a4,0(a5)
	li	s1,4194304
	j	.L3
.L4:
	addi	s1,s1,-1
.L3:
	bne	s1,zero,.L4
	li	a5,536870912
	addi	a5,a5,260
	sw	zero,0(a5)
	li	s1,4194304
	j	.L5
.L6:
	addi	s1,s1,-1
.L5:
	bne	s1,zero,.L6
	li	a5,536875008
	addi	a5,a5,-1016
	sw	zero,0(a5)
	li	a5,536875008
	addi	a5,a5,-1012
	sw	zero,0(a5)
#APP
# 139 "traphandler.c" 1
	   lw     a7, 56(sp)        
	   lw     a6, 52(sp)        
	   lw     a5, 48(sp)        
	   lw     a4, 44(sp)        
	   lw     a3, 40(sp)        
	   lw     a2, 36(sp)        
	   lw     a1, 32(sp)        
	   lw     a0, 28(sp)        
	   lw     t5, 24(sp)        
	   lw     t4, 20(sp)        
	   lw     t3, 16(sp)        
	   lw     t2, 12(sp)        
	   lw     t1,  8(sp)        
	   lw     t0,  4(sp)        
	   lw     ra,  0(sp)        
	   addi   sp,  sp, 64       
	   nop                      
	   nop                      
	   nop                      
	   mret                     
	   nop                      
	   nop                      
	   nop                      
	
# 0 "" 2
#NO_APP
	nop
	.cfi_endproc
.LFE1:
	.size	trap_handler, .-trap_handler
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB2:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	lui	a5,%hi(trap_handler)
	addi	a5,a5,%lo(trap_handler)
#APP
# 175 "traphandler.c" 1
	add zero, zero, a5 
	add zero, zero, a5 
	csrw mtvec, a5
# 0 "" 2
#NO_APP
	li	a5,128
#APP
# 179 "traphandler.c" 1
	add zero, zero, a5 
	add zero, zero, a5 
	csrs mie, a5
# 0 "" 2
#NO_APP
	li	a5,8
#APP
# 183 "traphandler.c" 1
	add zero, zero, a5 
	add zero, zero, a5 
	csrs mstatus, a5
# 0 "" 2
#NO_APP
	li	a5,536875008
	addi	a5,a5,-1024
	li	a4,268435456
	addi	a4,a4,-1
	sw	a4,0(a5)
	li	a5,536875008
	addi	a5,a5,-1020
	sw	zero,0(a5)
	li	a5,1
	sw	a5,-20(s0)
.L10:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	li	a5,536870912
	addi	a5,a5,260
	lw	a4,-20(s0)
	sw	a4,0(a5)
	li	a5,1048576
	sw	a5,-24(s0)
	j	.L8
.L9:
	lw	a5,-24(s0)
	addi	a5,a5,-1
	sw	a5,-24(s0)
.L8:
	lw	a5,-24(s0)
	bne	a5,zero,.L9
	j	.L10
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: () 14.2.0"
	.section	.note.GNU-stack,"",@progbits
