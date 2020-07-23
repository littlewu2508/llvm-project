; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --check-attributes
; RUN: opt -attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=4 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=4 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM
target datalayout = "E-p:64:64:64-a0:0:8-f32:32:32-f64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-v64:64:64-v128:128:128"

; Checks if !prof metadata is corret in deadargelim.

define void @caller() #0 {
; NOT_TUNIT_NPM-LABEL: define {{[^@]+}}@caller()
; NOT_TUNIT_NPM-NEXT:    [[X:%.*]] = alloca i32, align 4
; NOT_TUNIT_NPM-NEXT:    store i32 42, i32* [[X]], align 4
; NOT_TUNIT_NPM-NEXT:    call void @promote_i32_ptr(i32* noalias nocapture nonnull readonly align 4 dereferenceable(4) [[X]]), !prof !0
; NOT_TUNIT_NPM-NEXT:    ret void
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@caller()
; IS__TUNIT_NPM-NEXT:    [[X:%.*]] = alloca i32, align 4
; IS__TUNIT_NPM-NEXT:    store i32 42, i32* [[X]], align 4
; IS__TUNIT_NPM-NEXT:    [[TMP1:%.*]] = load i32, i32* [[X]], align 4
; IS__TUNIT_NPM-NEXT:    call void @promote_i32_ptr(i32 [[TMP1]]), !prof !0
; IS__TUNIT_NPM-NEXT:    ret void
;
  %x = alloca i32
  store i32 42, i32* %x
  call void @promote_i32_ptr(i32* %x), !prof !0
  ret void
}

define internal void @promote_i32_ptr(i32* %xp) {
; IS__TUNIT_OPM-LABEL: define {{[^@]+}}@promote_i32_ptr
; IS__TUNIT_OPM-SAME: (i32* noalias nocapture nonnull readonly align 4 dereferenceable(4) [[XP:%.*]])
; IS__TUNIT_OPM-NEXT:    [[X:%.*]] = load i32, i32* [[XP]], align 4
; IS__TUNIT_OPM-NEXT:    call void @use_i32(i32 [[X]])
; IS__TUNIT_OPM-NEXT:    ret void
;
; IS__TUNIT_NPM-LABEL: define {{[^@]+}}@promote_i32_ptr
; IS__TUNIT_NPM-SAME: (i32 [[TMP0:%.*]])
; IS__TUNIT_NPM-NEXT:    [[XP_PRIV:%.*]] = alloca i32, align 4
; IS__TUNIT_NPM-NEXT:    store i32 [[TMP0]], i32* [[XP_PRIV]], align 4
; IS__TUNIT_NPM-NEXT:    [[X:%.*]] = load i32, i32* [[XP_PRIV]], align 4
; IS__TUNIT_NPM-NEXT:    call void @use_i32(i32 [[X]])
; IS__TUNIT_NPM-NEXT:    ret void
;
; IS__CGSCC____-LABEL: define {{[^@]+}}@promote_i32_ptr
; IS__CGSCC____-SAME: (i32* nocapture nonnull readonly align 4 dereferenceable(4) [[XP:%.*]])
; IS__CGSCC____-NEXT:    [[X:%.*]] = load i32, i32* [[XP]], align 4
; IS__CGSCC____-NEXT:    call void @use_i32(i32 [[X]])
; IS__CGSCC____-NEXT:    ret void
;
  %x = load i32, i32* %xp
  call void @use_i32(i32 %x)
  ret void
}

declare void @use_i32(i32)

!0 = !{!"branch_weights", i32 30}
