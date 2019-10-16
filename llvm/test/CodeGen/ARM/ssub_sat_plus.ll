; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=thumbv6m-none-eabi | FileCheck %s --check-prefix=CHECK-T1
; RUN: llc < %s -mtriple=thumbv7m-none-eabi | FileCheck %s --check-prefix=CHECK-T2 --check-prefix=CHECK-T2NODSP
; RUN: llc < %s -mtriple=thumbv7em-none-eabi | FileCheck %s --check-prefix=CHECK-T2 --check-prefix=CHECK-T2DSP
; RUN: llc < %s -mtriple=armv8a-none-eabi | FileCheck %s --check-prefix=CHECK-ARM

declare i4 @llvm.ssub.sat.i4(i4, i4)
declare i8 @llvm.ssub.sat.i8(i8, i8)
declare i16 @llvm.ssub.sat.i16(i16, i16)
declare i32 @llvm.ssub.sat.i32(i32, i32)
declare i64 @llvm.ssub.sat.i64(i64, i64)

define i32 @func32(i32 %x, i32 %y, i32 %z) nounwind {
; CHECK-T1-LABEL: func32:
; CHECK-T1:       @ %bb.0:
; CHECK-T1-NEXT:    .save {r4, lr}
; CHECK-T1-NEXT:    push {r4, lr}
; CHECK-T1-NEXT:    mov r3, r0
; CHECK-T1-NEXT:    muls r1, r2, r1
; CHECK-T1-NEXT:    movs r2, #1
; CHECK-T1-NEXT:    subs r0, r0, r1
; CHECK-T1-NEXT:    mov r4, r2
; CHECK-T1-NEXT:    bmi .LBB0_2
; CHECK-T1-NEXT:  @ %bb.1:
; CHECK-T1-NEXT:    movs r4, #0
; CHECK-T1-NEXT:  .LBB0_2:
; CHECK-T1-NEXT:    cmp r4, #0
; CHECK-T1-NEXT:    bne .LBB0_4
; CHECK-T1-NEXT:  @ %bb.3:
; CHECK-T1-NEXT:    lsls r2, r2, #31
; CHECK-T1-NEXT:    cmp r3, r1
; CHECK-T1-NEXT:    bvs .LBB0_5
; CHECK-T1-NEXT:    b .LBB0_6
; CHECK-T1-NEXT:  .LBB0_4:
; CHECK-T1-NEXT:    ldr r2, .LCPI0_0
; CHECK-T1-NEXT:    cmp r3, r1
; CHECK-T1-NEXT:    bvc .LBB0_6
; CHECK-T1-NEXT:  .LBB0_5:
; CHECK-T1-NEXT:    mov r0, r2
; CHECK-T1-NEXT:  .LBB0_6:
; CHECK-T1-NEXT:    pop {r4, pc}
; CHECK-T1-NEXT:    .p2align 2
; CHECK-T1-NEXT:  @ %bb.7:
; CHECK-T1-NEXT:  .LCPI0_0:
; CHECK-T1-NEXT:    .long 2147483647 @ 0x7fffffff
;
; CHECK-T2-LABEL: func32:
; CHECK-T2:       @ %bb.0:
; CHECK-T2-NEXT:    .save {r7, lr}
; CHECK-T2-NEXT:    push {r7, lr}
; CHECK-T2-NEXT:    mls r12, r1, r2, r0
; CHECK-T2-NEXT:    mov.w lr, #0
; CHECK-T2-NEXT:    mov.w r3, #-2147483648
; CHECK-T2-NEXT:    muls r1, r2, r1
; CHECK-T2-NEXT:    cmp.w r12, #0
; CHECK-T2-NEXT:    it mi
; CHECK-T2-NEXT:    movmi.w lr, #1
; CHECK-T2-NEXT:    cmp.w lr, #0
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    mvnne r3, #-2147483648
; CHECK-T2-NEXT:    cmp r0, r1
; CHECK-T2-NEXT:    it vc
; CHECK-T2-NEXT:    movvc r3, r12
; CHECK-T2-NEXT:    mov r0, r3
; CHECK-T2-NEXT:    pop {r7, pc}
;
; CHECK-ARM-LABEL: func32:
; CHECK-ARM:       @ %bb.0:
; CHECK-ARM-NEXT:    mls r3, r1, r2, r0
; CHECK-ARM-NEXT:    mul r12, r1, r2
; CHECK-ARM-NEXT:    mov r2, #0
; CHECK-ARM-NEXT:    mov r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r3, #0
; CHECK-ARM-NEXT:    movwmi r2, #1
; CHECK-ARM-NEXT:    cmp r2, #0
; CHECK-ARM-NEXT:    mvnne r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r0, r12
; CHECK-ARM-NEXT:    movvc r1, r3
; CHECK-ARM-NEXT:    mov r0, r1
; CHECK-ARM-NEXT:    bx lr
  %a = mul i32 %y, %z
  %tmp = call i32 @llvm.ssub.sat.i32(i32 %x, i32 %a)
  ret i32 %tmp
}

define i64 @func64(i64 %x, i64 %y, i64 %z) nounwind {
; CHECK-T1-LABEL: func64:
; CHECK-T1:       @ %bb.0:
; CHECK-T1-NEXT:    .save {r4, r5, r6, r7, lr}
; CHECK-T1-NEXT:    push {r4, r5, r6, r7, lr}
; CHECK-T1-NEXT:    .pad #4
; CHECK-T1-NEXT:    sub sp, #4
; CHECK-T1-NEXT:    ldr r5, [sp, #28]
; CHECK-T1-NEXT:    movs r2, #1
; CHECK-T1-NEXT:    movs r4, #0
; CHECK-T1-NEXT:    cmp r5, #0
; CHECK-T1-NEXT:    mov r3, r2
; CHECK-T1-NEXT:    bge .LBB1_2
; CHECK-T1-NEXT:  @ %bb.1:
; CHECK-T1-NEXT:    mov r3, r4
; CHECK-T1-NEXT:  .LBB1_2:
; CHECK-T1-NEXT:    cmp r1, #0
; CHECK-T1-NEXT:    mov r6, r2
; CHECK-T1-NEXT:    bge .LBB1_4
; CHECK-T1-NEXT:  @ %bb.3:
; CHECK-T1-NEXT:    mov r6, r4
; CHECK-T1-NEXT:  .LBB1_4:
; CHECK-T1-NEXT:    subs r3, r6, r3
; CHECK-T1-NEXT:    subs r7, r3, #1
; CHECK-T1-NEXT:    sbcs r3, r7
; CHECK-T1-NEXT:    ldr r7, [sp, #24]
; CHECK-T1-NEXT:    subs r0, r0, r7
; CHECK-T1-NEXT:    sbcs r1, r5
; CHECK-T1-NEXT:    cmp r1, #0
; CHECK-T1-NEXT:    mov r5, r2
; CHECK-T1-NEXT:    bge .LBB1_6
; CHECK-T1-NEXT:  @ %bb.5:
; CHECK-T1-NEXT:    mov r5, r4
; CHECK-T1-NEXT:  .LBB1_6:
; CHECK-T1-NEXT:    subs r4, r6, r5
; CHECK-T1-NEXT:    subs r5, r4, #1
; CHECK-T1-NEXT:    sbcs r4, r5
; CHECK-T1-NEXT:    ands r3, r4
; CHECK-T1-NEXT:    beq .LBB1_8
; CHECK-T1-NEXT:  @ %bb.7:
; CHECK-T1-NEXT:    asrs r0, r1, #31
; CHECK-T1-NEXT:  .LBB1_8:
; CHECK-T1-NEXT:    cmp r1, #0
; CHECK-T1-NEXT:    bmi .LBB1_10
; CHECK-T1-NEXT:  @ %bb.9:
; CHECK-T1-NEXT:    lsls r2, r2, #31
; CHECK-T1-NEXT:    cmp r3, #0
; CHECK-T1-NEXT:    beq .LBB1_11
; CHECK-T1-NEXT:    b .LBB1_12
; CHECK-T1-NEXT:  .LBB1_10:
; CHECK-T1-NEXT:    ldr r2, .LCPI1_0
; CHECK-T1-NEXT:    cmp r3, #0
; CHECK-T1-NEXT:    bne .LBB1_12
; CHECK-T1-NEXT:  .LBB1_11:
; CHECK-T1-NEXT:    mov r2, r1
; CHECK-T1-NEXT:  .LBB1_12:
; CHECK-T1-NEXT:    mov r1, r2
; CHECK-T1-NEXT:    add sp, #4
; CHECK-T1-NEXT:    pop {r4, r5, r6, r7, pc}
; CHECK-T1-NEXT:    .p2align 2
; CHECK-T1-NEXT:  @ %bb.13:
; CHECK-T1-NEXT:  .LCPI1_0:
; CHECK-T1-NEXT:    .long 2147483647 @ 0x7fffffff
;
; CHECK-T2-LABEL: func64:
; CHECK-T2:       @ %bb.0:
; CHECK-T2-NEXT:    .save {r4, lr}
; CHECK-T2-NEXT:    push {r4, lr}
; CHECK-T2-NEXT:    ldr.w r12, [sp, #12]
; CHECK-T2-NEXT:    movs r2, #0
; CHECK-T2-NEXT:    movs r3, #0
; CHECK-T2-NEXT:    ldr r4, [sp, #8]
; CHECK-T2-NEXT:    cmp.w r12, #-1
; CHECK-T2-NEXT:    it gt
; CHECK-T2-NEXT:    movgt r2, #1
; CHECK-T2-NEXT:    cmp.w r1, #-1
; CHECK-T2-NEXT:    it gt
; CHECK-T2-NEXT:    movgt r3, #1
; CHECK-T2-NEXT:    subs r2, r3, r2
; CHECK-T2-NEXT:    mov.w lr, #0
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    movne r2, #1
; CHECK-T2-NEXT:    subs r0, r0, r4
; CHECK-T2-NEXT:    sbc.w r4, r1, r12
; CHECK-T2-NEXT:    cmp.w r4, #-1
; CHECK-T2-NEXT:    it gt
; CHECK-T2-NEXT:    movgt.w lr, #1
; CHECK-T2-NEXT:    subs.w r1, r3, lr
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    movne r1, #1
; CHECK-T2-NEXT:    ands r2, r1
; CHECK-T2-NEXT:    mov.w r1, #-2147483648
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    asrne r0, r4, #31
; CHECK-T2-NEXT:    cmp r4, #0
; CHECK-T2-NEXT:    it mi
; CHECK-T2-NEXT:    mvnmi r1, #-2147483648
; CHECK-T2-NEXT:    cmp r2, #0
; CHECK-T2-NEXT:    it eq
; CHECK-T2-NEXT:    moveq r1, r4
; CHECK-T2-NEXT:    pop {r4, pc}
;
; CHECK-ARM-LABEL: func64:
; CHECK-ARM:       @ %bb.0:
; CHECK-ARM-NEXT:    .save {r4, r5, r11, lr}
; CHECK-ARM-NEXT:    push {r4, r5, r11, lr}
; CHECK-ARM-NEXT:    ldr lr, [sp, #20]
; CHECK-ARM-NEXT:    cmn r1, #1
; CHECK-ARM-NEXT:    mov r3, #0
; CHECK-ARM-NEXT:    mov r4, #0
; CHECK-ARM-NEXT:    movwgt r3, #1
; CHECK-ARM-NEXT:    cmn lr, #1
; CHECK-ARM-NEXT:    movwgt r4, #1
; CHECK-ARM-NEXT:    ldr r12, [sp, #16]
; CHECK-ARM-NEXT:    subs r4, r3, r4
; CHECK-ARM-NEXT:    mov r5, #0
; CHECK-ARM-NEXT:    movwne r4, #1
; CHECK-ARM-NEXT:    subs r0, r0, r12
; CHECK-ARM-NEXT:    sbc r2, r1, lr
; CHECK-ARM-NEXT:    cmn r2, #1
; CHECK-ARM-NEXT:    movwgt r5, #1
; CHECK-ARM-NEXT:    subs r1, r3, r5
; CHECK-ARM-NEXT:    movwne r1, #1
; CHECK-ARM-NEXT:    ands r3, r4, r1
; CHECK-ARM-NEXT:    asrne r0, r2, #31
; CHECK-ARM-NEXT:    mov r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r2, #0
; CHECK-ARM-NEXT:    mvnmi r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r3, #0
; CHECK-ARM-NEXT:    moveq r1, r2
; CHECK-ARM-NEXT:    pop {r4, r5, r11, pc}
  %a = mul i64 %y, %z
  %tmp = call i64 @llvm.ssub.sat.i64(i64 %x, i64 %z)
  ret i64 %tmp
}

define signext i16 @func16(i16 signext %x, i16 signext %y, i16 signext %z) nounwind {
; CHECK-T1-LABEL: func16:
; CHECK-T1:       @ %bb.0:
; CHECK-T1-NEXT:    .save {r4, lr}
; CHECK-T1-NEXT:    push {r4, lr}
; CHECK-T1-NEXT:    muls r1, r2, r1
; CHECK-T1-NEXT:    lsls r1, r1, #16
; CHECK-T1-NEXT:    lsls r2, r0, #16
; CHECK-T1-NEXT:    movs r3, #1
; CHECK-T1-NEXT:    subs r0, r2, r1
; CHECK-T1-NEXT:    mov r4, r3
; CHECK-T1-NEXT:    bmi .LBB2_2
; CHECK-T1-NEXT:  @ %bb.1:
; CHECK-T1-NEXT:    movs r4, #0
; CHECK-T1-NEXT:  .LBB2_2:
; CHECK-T1-NEXT:    cmp r4, #0
; CHECK-T1-NEXT:    bne .LBB2_4
; CHECK-T1-NEXT:  @ %bb.3:
; CHECK-T1-NEXT:    lsls r3, r3, #31
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvs .LBB2_5
; CHECK-T1-NEXT:    b .LBB2_6
; CHECK-T1-NEXT:  .LBB2_4:
; CHECK-T1-NEXT:    ldr r3, .LCPI2_0
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvc .LBB2_6
; CHECK-T1-NEXT:  .LBB2_5:
; CHECK-T1-NEXT:    mov r0, r3
; CHECK-T1-NEXT:  .LBB2_6:
; CHECK-T1-NEXT:    asrs r0, r0, #16
; CHECK-T1-NEXT:    pop {r4, pc}
; CHECK-T1-NEXT:    .p2align 2
; CHECK-T1-NEXT:  @ %bb.7:
; CHECK-T1-NEXT:  .LCPI2_0:
; CHECK-T1-NEXT:    .long 2147483647 @ 0x7fffffff
;
; CHECK-T2-LABEL: func16:
; CHECK-T2:       @ %bb.0:
; CHECK-T2-NEXT:    mul r12, r1, r2
; CHECK-T2-NEXT:    lsls r0, r0, #16
; CHECK-T2-NEXT:    movs r3, #0
; CHECK-T2-NEXT:    mov.w r1, #-2147483648
; CHECK-T2-NEXT:    sub.w r2, r0, r12, lsl #16
; CHECK-T2-NEXT:    cmp r2, #0
; CHECK-T2-NEXT:    it mi
; CHECK-T2-NEXT:    movmi r3, #1
; CHECK-T2-NEXT:    cmp r3, #0
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    mvnne r1, #-2147483648
; CHECK-T2-NEXT:    cmp.w r0, r12, lsl #16
; CHECK-T2-NEXT:    it vc
; CHECK-T2-NEXT:    movvc r1, r2
; CHECK-T2-NEXT:    asrs r0, r1, #16
; CHECK-T2-NEXT:    bx lr
;
; CHECK-ARM-LABEL: func16:
; CHECK-ARM:       @ %bb.0:
; CHECK-ARM-NEXT:    smulbb r12, r1, r2
; CHECK-ARM-NEXT:    lsl r0, r0, #16
; CHECK-ARM-NEXT:    mov r3, #0
; CHECK-ARM-NEXT:    mov r1, #-2147483648
; CHECK-ARM-NEXT:    sub r2, r0, r12, lsl #16
; CHECK-ARM-NEXT:    cmp r2, #0
; CHECK-ARM-NEXT:    movwmi r3, #1
; CHECK-ARM-NEXT:    cmp r3, #0
; CHECK-ARM-NEXT:    mvnne r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r0, r12, lsl #16
; CHECK-ARM-NEXT:    movvc r1, r2
; CHECK-ARM-NEXT:    asr r0, r1, #16
; CHECK-ARM-NEXT:    bx lr
  %a = mul i16 %y, %z
  %tmp = call i16 @llvm.ssub.sat.i16(i16 %x, i16 %a)
  ret i16 %tmp
}

define signext i8 @func8(i8 signext %x, i8 signext %y, i8 signext %z) nounwind {
; CHECK-T1-LABEL: func8:
; CHECK-T1:       @ %bb.0:
; CHECK-T1-NEXT:    .save {r4, lr}
; CHECK-T1-NEXT:    push {r4, lr}
; CHECK-T1-NEXT:    muls r1, r2, r1
; CHECK-T1-NEXT:    lsls r1, r1, #24
; CHECK-T1-NEXT:    lsls r2, r0, #24
; CHECK-T1-NEXT:    movs r3, #1
; CHECK-T1-NEXT:    subs r0, r2, r1
; CHECK-T1-NEXT:    mov r4, r3
; CHECK-T1-NEXT:    bmi .LBB3_2
; CHECK-T1-NEXT:  @ %bb.1:
; CHECK-T1-NEXT:    movs r4, #0
; CHECK-T1-NEXT:  .LBB3_2:
; CHECK-T1-NEXT:    cmp r4, #0
; CHECK-T1-NEXT:    bne .LBB3_4
; CHECK-T1-NEXT:  @ %bb.3:
; CHECK-T1-NEXT:    lsls r3, r3, #31
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvs .LBB3_5
; CHECK-T1-NEXT:    b .LBB3_6
; CHECK-T1-NEXT:  .LBB3_4:
; CHECK-T1-NEXT:    ldr r3, .LCPI3_0
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvc .LBB3_6
; CHECK-T1-NEXT:  .LBB3_5:
; CHECK-T1-NEXT:    mov r0, r3
; CHECK-T1-NEXT:  .LBB3_6:
; CHECK-T1-NEXT:    asrs r0, r0, #24
; CHECK-T1-NEXT:    pop {r4, pc}
; CHECK-T1-NEXT:    .p2align 2
; CHECK-T1-NEXT:  @ %bb.7:
; CHECK-T1-NEXT:  .LCPI3_0:
; CHECK-T1-NEXT:    .long 2147483647 @ 0x7fffffff
;
; CHECK-T2-LABEL: func8:
; CHECK-T2:       @ %bb.0:
; CHECK-T2-NEXT:    mul r12, r1, r2
; CHECK-T2-NEXT:    lsls r0, r0, #24
; CHECK-T2-NEXT:    movs r3, #0
; CHECK-T2-NEXT:    mov.w r1, #-2147483648
; CHECK-T2-NEXT:    sub.w r2, r0, r12, lsl #24
; CHECK-T2-NEXT:    cmp r2, #0
; CHECK-T2-NEXT:    it mi
; CHECK-T2-NEXT:    movmi r3, #1
; CHECK-T2-NEXT:    cmp r3, #0
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    mvnne r1, #-2147483648
; CHECK-T2-NEXT:    cmp.w r0, r12, lsl #24
; CHECK-T2-NEXT:    it vc
; CHECK-T2-NEXT:    movvc r1, r2
; CHECK-T2-NEXT:    asrs r0, r1, #24
; CHECK-T2-NEXT:    bx lr
;
; CHECK-ARM-LABEL: func8:
; CHECK-ARM:       @ %bb.0:
; CHECK-ARM-NEXT:    smulbb r12, r1, r2
; CHECK-ARM-NEXT:    lsl r0, r0, #24
; CHECK-ARM-NEXT:    mov r3, #0
; CHECK-ARM-NEXT:    mov r1, #-2147483648
; CHECK-ARM-NEXT:    sub r2, r0, r12, lsl #24
; CHECK-ARM-NEXT:    cmp r2, #0
; CHECK-ARM-NEXT:    movwmi r3, #1
; CHECK-ARM-NEXT:    cmp r3, #0
; CHECK-ARM-NEXT:    mvnne r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r0, r12, lsl #24
; CHECK-ARM-NEXT:    movvc r1, r2
; CHECK-ARM-NEXT:    asr r0, r1, #24
; CHECK-ARM-NEXT:    bx lr
  %a = mul i8 %y, %z
  %tmp = call i8 @llvm.ssub.sat.i8(i8 %x, i8 %a)
  ret i8 %tmp
}

define signext i4 @func4(i4 signext %x, i4 signext %y, i4 signext %z) nounwind {
; CHECK-T1-LABEL: func4:
; CHECK-T1:       @ %bb.0:
; CHECK-T1-NEXT:    .save {r4, lr}
; CHECK-T1-NEXT:    push {r4, lr}
; CHECK-T1-NEXT:    muls r1, r2, r1
; CHECK-T1-NEXT:    lsls r1, r1, #28
; CHECK-T1-NEXT:    lsls r2, r0, #28
; CHECK-T1-NEXT:    movs r3, #1
; CHECK-T1-NEXT:    subs r0, r2, r1
; CHECK-T1-NEXT:    mov r4, r3
; CHECK-T1-NEXT:    bmi .LBB4_2
; CHECK-T1-NEXT:  @ %bb.1:
; CHECK-T1-NEXT:    movs r4, #0
; CHECK-T1-NEXT:  .LBB4_2:
; CHECK-T1-NEXT:    cmp r4, #0
; CHECK-T1-NEXT:    bne .LBB4_4
; CHECK-T1-NEXT:  @ %bb.3:
; CHECK-T1-NEXT:    lsls r3, r3, #31
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvs .LBB4_5
; CHECK-T1-NEXT:    b .LBB4_6
; CHECK-T1-NEXT:  .LBB4_4:
; CHECK-T1-NEXT:    ldr r3, .LCPI4_0
; CHECK-T1-NEXT:    cmp r2, r1
; CHECK-T1-NEXT:    bvc .LBB4_6
; CHECK-T1-NEXT:  .LBB4_5:
; CHECK-T1-NEXT:    mov r0, r3
; CHECK-T1-NEXT:  .LBB4_6:
; CHECK-T1-NEXT:    asrs r0, r0, #28
; CHECK-T1-NEXT:    pop {r4, pc}
; CHECK-T1-NEXT:    .p2align 2
; CHECK-T1-NEXT:  @ %bb.7:
; CHECK-T1-NEXT:  .LCPI4_0:
; CHECK-T1-NEXT:    .long 2147483647 @ 0x7fffffff
;
; CHECK-T2-LABEL: func4:
; CHECK-T2:       @ %bb.0:
; CHECK-T2-NEXT:    mul r12, r1, r2
; CHECK-T2-NEXT:    lsls r0, r0, #28
; CHECK-T2-NEXT:    movs r3, #0
; CHECK-T2-NEXT:    mov.w r1, #-2147483648
; CHECK-T2-NEXT:    sub.w r2, r0, r12, lsl #28
; CHECK-T2-NEXT:    cmp r2, #0
; CHECK-T2-NEXT:    it mi
; CHECK-T2-NEXT:    movmi r3, #1
; CHECK-T2-NEXT:    cmp r3, #0
; CHECK-T2-NEXT:    it ne
; CHECK-T2-NEXT:    mvnne r1, #-2147483648
; CHECK-T2-NEXT:    cmp.w r0, r12, lsl #28
; CHECK-T2-NEXT:    it vc
; CHECK-T2-NEXT:    movvc r1, r2
; CHECK-T2-NEXT:    asrs r0, r1, #28
; CHECK-T2-NEXT:    bx lr
;
; CHECK-ARM-LABEL: func4:
; CHECK-ARM:       @ %bb.0:
; CHECK-ARM-NEXT:    smulbb r12, r1, r2
; CHECK-ARM-NEXT:    lsl r0, r0, #28
; CHECK-ARM-NEXT:    mov r3, #0
; CHECK-ARM-NEXT:    mov r1, #-2147483648
; CHECK-ARM-NEXT:    sub r2, r0, r12, lsl #28
; CHECK-ARM-NEXT:    cmp r2, #0
; CHECK-ARM-NEXT:    movwmi r3, #1
; CHECK-ARM-NEXT:    cmp r3, #0
; CHECK-ARM-NEXT:    mvnne r1, #-2147483648
; CHECK-ARM-NEXT:    cmp r0, r12, lsl #28
; CHECK-ARM-NEXT:    movvc r1, r2
; CHECK-ARM-NEXT:    asr r0, r1, #28
; CHECK-ARM-NEXT:    bx lr
  %a = mul i4 %y, %z
  %tmp = call i4 @llvm.ssub.sat.i4(i4 %x, i4 %a)
  ret i4 %tmp
}
