	.file	"traphandler.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.type	write_csr_mtvec, @function
write_csr_mtvec:
.LFB0:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)
	lw	a5,-20(s0)
#APP
# 38 "traphandler.c" 1
	csrw mtvec, a5
# 0 "" 2
#NO_APP
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE0:
	.size	write_csr_mtvec, .-write_csr_mtvec
	.align	2
	.type	set_csr_mie, @function
set_csr_mie:
.LFB1:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)
	lw	a5,-20(s0)
#APP
# 43 "traphandler.c" 1
	csrs mie, a5
# 0 "" 2
#NO_APP
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE1:
	.size	set_csr_mie, .-set_csr_mie
	.align	2
	.type	set_csr_mstatus, @function
set_csr_mstatus:
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
	sw	a0,-20(s0)
	lw	a5,-20(s0)
#APP
# 48 "traphandler.c" 1
	csrs mstatus, a5
# 0 "" 2
#NO_APP
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE2:
	.size	set_csr_mstatus, .-set_csr_mstatus
	.align	2
	.type	clear_csr_mip, @function
clear_csr_mip:
.LFB3:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)
	lw	a5,-20(s0)
#APP
# 53 "traphandler.c" 1
	csrc mip, a5
# 0 "" 2
#NO_APP
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE3:
	.size	clear_csr_mip, .-clear_csr_mip
	.globl	g_counter
	.section	.sbss,"aw",@nobits
	.align	2
	.type	g_counter, @object
	.size	g_counter, 4
g_counter:
	.zero	4
	.text
	.align	2
	.type	simple_delay, @function
simple_delay:
.LFB4:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)
	j	.L6
.L7:
#APP
# 77 "traphandler.c" 1
	nop
# 0 "" 2
#NO_APP
.L6:
	lw	a5,-20(s0)
	addi	a4,a5,-1
	sw	a4,-20(s0)
	bne	a5,zero,.L7
	nop
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE4:
	.size	simple_delay, .-simple_delay
	.align	2
	.globl	trap_handler_c
	.type	trap_handler_c, @function
trap_handler_c:
.LFB5:
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	li	a5,536875008
	addi	a5,a5,-1016
	lw	a5,0(a5)
	sw	a5,-24(s0)
	li	a5,536875008
	addi	a5,a5,-1012
	lw	a5,0(a5)
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	sw	a5,-28(s0)
	lw	a4,-24(s0)
	li	a5,249999360
	addi	a5,a5,640
	add	a5,a4,a5
	sw	a5,-24(s0)
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	bgeu	a4,a5,.L9
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L9:
	li	a5,536875008
	addi	a5,a5,-1024
	lw	a4,-24(s0)
	sw	a4,0(a5)
	li	a5,536875008
	addi	a5,a5,-1020
	lw	a4,-20(s0)
	sw	a4,0(a5)
	li	a0,128
	call	clear_csr_mip
	li	a5,536870912
	addi	a5,a5,260
	li	a4,65536
	addi	a4,a4,-1
	sw	a4,0(a5)
	li	a0,1048576
	call	simple_delay
	li	a5,536870912
	addi	a5,a5,260
	sw	zero,0(a5)
	li	a0,1048576
	call	simple_delay
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE5:
	.size	trap_handler_c, .-trap_handler_c
	.align	2
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
.LFB6:
	.cfi_startproc
#APP
# 126 "traphandler.c" 1
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
	   call   trap_handler_c    
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
	   mret                     
	
# 0 "" 2
#NO_APP
	nop
	.cfi_endproc
.LFE6:
	.size	trap_handler, .-trap_handler
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB7:
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
#APP
# 178 "traphandler.c" 1
	li sp, 0x0FFFFFFF
# 0 "" 2
#NO_APP
	lui	a5,%hi(trap_handler)
	addi	a0,a5,%lo(trap_handler)
	call	write_csr_mtvec
	li	a0,128
	call	set_csr_mie
	li	a0,8
	call	set_csr_mstatus
	li	a5,536875008
	addi	a5,a5,-1024
	li	a4,249999360
	addi	a4,a4,640
	sw	a4,0(a5)
	li	a5,536875008
	addi	a5,a5,-1020
	sw	zero,0(a5)
.L13:
	lui	a5,%hi(g_counter)
	lw	a5,%lo(g_counter)(a5)
	addi	a4,a5,1
	lui	a5,%hi(g_counter)
	sw	a4,%lo(g_counter)(a5)
	lui	a5,%hi(g_counter)
	lw	a4,%lo(g_counter)(a5)
	li	a5,65536
	bltu	a4,a5,.L12
	lui	a5,%hi(g_counter)
	sw	zero,%lo(g_counter)(a5)
.L12:
	li	a5,536870912
	addi	a5,a5,260
	lui	a4,%hi(g_counter)
	lw	a4,%lo(g_counter)(a4)
	sw	a4,0(a5)
	li	a5,2498560
	addi	a0,a5,1440
	call	simple_delay
	j	.L13
	.cfi_endproc
.LFE7:
	.size	main, .-main
	.ident	"GCC: () 14.2.0"
	.section	.note.GNU-stack,"",@progbits
