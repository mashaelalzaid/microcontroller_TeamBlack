	.file	"traphandler.c"
	.option nopic
	.attribute arch, "rv32i2p1_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	led
	.section	.sdata,"aw"
	.align	2
	.type	led, @object
	.size	led, 4
led:
	.word	536871172
	.globl	mtime
	.align	2
	.type	mtime, @object
	.size	mtime, 4
mtime:
	.word	536873992
	.globl	mtimecmp
	.align	2
	.type	mtimecmp, @object
	.size	mtimecmp, 4
mtimecmp:
	.word	536873984
	.text
	.align	1
	.globl	setup_interrupts
	.type	setup_interrupts, @function
setup_interrupts:
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
	lui	a5,%hi(trap_handler)
	addi	a5,a5,%lo(trap_handler)
	sw	a5,-20(s0)
	lw	a5,-20(s0)
#APP
# 17 "traphandler.c" 1
	csrw mtvec, a5
# 0 "" 2
# 22 "traphandler.c" 1
	li t0, 0x80
csrs mie, t0

# 0 "" 2
# 29 "traphandler.c" 1
	li t0, 0x8
csrs mstatus, t0

# 0 "" 2
#NO_APP
	lui	a5,%hi(mtime)
	lw	a5,%lo(mtime)(a5)
	lw	a4,0(a5)
	lui	a5,%hi(mtimecmp)
	lw	a5,%lo(mtimecmp)(a5)
	addi	a4,a4,100
	sw	a4,0(a5)
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
	.size	setup_interrupts, .-setup_interrupts
	.align	1
	.globl	trap_handler
	.type	trap_handler, @function
trap_handler:
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
	lui	a5,%hi(mtime)
	lw	a5,%lo(mtime)(a5)
	lw	a5,0(a5)
	sw	a5,-20(s0)
	lui	a5,%hi(mtimecmp)
	lw	a5,%lo(mtimecmp)(a5)
	lw	a4,-20(s0)
	addi	a4,a4,100
	sw	a4,0(a5)
	lui	a5,%hi(led)
	lw	a5,%lo(led)(a5)
	lw	a4,0(a5)
	lui	a5,%hi(led)
	lw	a5,%lo(led)(a5)
	xori	a4,a4,1
	sw	a4,0(a5)
#APP
# 48 "traphandler.c" 1
	li t0, 0x80
csrc mip, t0

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
	.size	trap_handler, .-trap_handler
	.align	1
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
	call	setup_interrupts
	sw	zero,-20(s0)
.L5:
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	lw	a4,-20(s0)
	li	a5,65536
	bltu	a4,a5,.L4
	sw	zero,-20(s0)
.L4:
	lui	a5,%hi(led)
	lw	a5,%lo(led)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	j	.L5
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: () 14.2.0"
	.section	.note.GNU-stack,"",@progbits
