; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -mtriple=aarch64-- -mcpu=falkor -mattr=+lse -O0 -aarch64-enable-atomic-cfg-tidy=0 -stop-after=irtranslator -global-isel -verify-machineinstrs %s -o - | FileCheck %s

define i16 @convert_to_fp16(float %src) {
  ; CHECK-LABEL: name: convert_to_fp16
  ; CHECK: bb.1 (%ir-block.0):
  ; CHECK:   liveins: $s0
  ; CHECK:   [[COPY:%[0-9]+]]:_(s32) = COPY $s0
  ; CHECK:   [[FPTRUNC:%[0-9]+]]:_(s16) = G_FPTRUNC [[COPY]](s32)
  ; CHECK:   [[ANYEXT:%[0-9]+]]:_(s32) = G_ANYEXT [[FPTRUNC]](s16)
  ; CHECK:   $w0 = COPY [[ANYEXT]](s32)
  ; CHECK:   RET_ReallyLR implicit $w0
  %cvt = call i16 @llvm.convert.to.fp16.f32(float %src)
  ret i16 %cvt
}

define float @convert_from_fp16(i16 %src) {
  ; CHECK-LABEL: name: convert_from_fp16
  ; CHECK: bb.1 (%ir-block.0):
  ; CHECK:   liveins: $w0
  ; CHECK:   [[COPY:%[0-9]+]]:_(s32) = COPY $w0
  ; CHECK:   [[TRUNC:%[0-9]+]]:_(s16) = G_TRUNC [[COPY]](s32)
  ; CHECK:   [[FPEXT:%[0-9]+]]:_(s32) = G_FPEXT [[TRUNC]](s16)
  ; CHECK:   $s0 = COPY [[FPEXT]](s32)
  ; CHECK:   RET_ReallyLR implicit $s0
  %cvt = call float @llvm.convert.from.fp16.f32(i16 %src)
  ret float %cvt
}

declare i16 @llvm.convert.to.fp16.f32(float) nounwind readnone
declare float @llvm.convert.from.fp16.f32(i16) nounwind readnone
