; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=powerpc64le-- -verify-machineinstrs | FileCheck %s

define i32 @sub_zext_cmp_mask_same_size_result(i32 %x) {
; CHECK-LABEL: sub_zext_cmp_mask_same_size_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    nor 3, 3, 3
; CHECK-NEXT:    clrlwi 3, 3, 31
; CHECK-NEXT:    subfic 3, 3, -27
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %z = zext i1 %c to i32
  %r = sub i32 -27, %z
  ret i32 %r
}

define i32 @sub_zext_cmp_mask_wider_result(i8 %x) {
; CHECK-LABEL: sub_zext_cmp_mask_wider_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    nor 3, 3, 3
; CHECK-NEXT:    clrlwi 3, 3, 31
; CHECK-NEXT:    subfic 3, 3, 27
; CHECK-NEXT:    blr
  %a = and i8 %x, 1
  %c = icmp eq i8 %a, 0
  %z = zext i1 %c to i32
  %r = sub i32 27, %z
  ret i32 %r
}

define i8 @sub_zext_cmp_mask_narrower_result(i32 %x) {
; CHECK-LABEL: sub_zext_cmp_mask_narrower_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    nor 3, 3, 3
; CHECK-NEXT:    clrlwi 3, 3, 31
; CHECK-NEXT:    subfic 3, 3, 47
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %z = zext i1 %c to i8
  %r = sub i8 47, %z
  ret i8 %r
}

define i8 @add_zext_cmp_mask_same_size_result(i8 %x) {
; CHECK-LABEL: add_zext_cmp_mask_same_size_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    xori 3, 3, 65535
; CHECK-NEXT:    xoris 3, 3, 65535
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 26
; CHECK-NEXT:    blr
  %a = and i8 %x, 1
  %c = icmp eq i8 %a, 0
  %z = zext i1 %c to i8
  %r = add i8 %z, 26
  ret i8 %r
}

define i32 @add_zext_cmp_mask_wider_result(i8 %x) {
; CHECK-LABEL: add_zext_cmp_mask_wider_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    xori 3, 3, 65535
; CHECK-NEXT:    xoris 3, 3, 65535
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 26
; CHECK-NEXT:    blr
  %a = and i8 %x, 1
  %c = icmp eq i8 %a, 0
  %z = zext i1 %c to i32
  %r = add i32 %z, 26
  ret i32 %r
}

define i8 @add_zext_cmp_mask_narrower_result(i32 %x) {
; CHECK-LABEL: add_zext_cmp_mask_narrower_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    xori 3, 3, 65535
; CHECK-NEXT:    xoris 3, 3, 65535
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 42
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %z = zext i1 %c to i8
  %r = add i8 %z, 42
  ret i8 %r
}

define i32 @low_bit_select_constants_bigger_false_same_size_result(i32 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_false_same_size_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    not 3, 3
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    subfic 3, 3, 43
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %r = select i1 %c, i32 42, i32 43
  ret i32 %r
}

define i64 @low_bit_select_constants_bigger_false_wider_result(i32 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_false_wider_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    not 3, 3
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    subfic 3, 3, 27
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %r = select i1 %c, i64 26, i64 27
  ret i64 %r
}

define i16 @low_bit_select_constants_bigger_false_narrower_result(i32 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_false_narrower_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    nor 3, 3, 3
; CHECK-NEXT:    clrlwi 3, 3, 31
; CHECK-NEXT:    subfic 3, 3, 37
; CHECK-NEXT:    blr
  %a = and i32 %x, 1
  %c = icmp eq i32 %a, 0
  %r = select i1 %c, i16 36, i16 37
  ret i16 %r
}

define i8 @low_bit_select_constants_bigger_true_same_size_result(i8 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_true_same_size_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    xori 3, 3, 65535
; CHECK-NEXT:    xoris 3, 3, 65535
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 65506
; CHECK-NEXT:    oris 3, 3, 65535
; CHECK-NEXT:    blr
  %a = and i8 %x, 1
  %c = icmp eq i8 %a, 0
  %r = select i1 %c, i8 227, i8 226
  ret i8 %r
}

define i32 @low_bit_select_constants_bigger_true_wider_result(i8 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_true_wider_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    not 3, 3
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 226
; CHECK-NEXT:    blr
  %a = and i8 %x, 1
  %c = icmp eq i8 %a, 0
  %r = select i1 %c, i32 227, i32 226
  ret i32 %r
}

define i8 @low_bit_select_constants_bigger_true_narrower_result(i16 %x) {
; CHECK-LABEL: low_bit_select_constants_bigger_true_narrower_result:
; CHECK:       # %bb.0:
; CHECK-NEXT:    xori 3, 3, 65535
; CHECK-NEXT:    xoris 3, 3, 65535
; CHECK-NEXT:    clrldi 3, 3, 63
; CHECK-NEXT:    ori 3, 3, 40
; CHECK-NEXT:    blr
  %a = and i16 %x, 1
  %c = icmp eq i16 %a, 0
  %r = select i1 %c, i8 41, i8 40
  ret i8 %r
}

