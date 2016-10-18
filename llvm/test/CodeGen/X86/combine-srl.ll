; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse4.1 | FileCheck %s --check-prefix=SSE
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx2 | FileCheck %s --check-prefix=AVX

; fold (srl 0, x) -> 0
define <4 x i32> @combine_vec_lshr_zero(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_zero:
; SSE:       # BB#0:
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrldq {{.*#+}} xmm2 = xmm2[12,13,14,15],zero,zero,zero,zero,zero,zero,zero,zero,zero,zero,zero,zero
; SSE-NEXT:    pxor %xmm1, %xmm1
; SSE-NEXT:    pxor %xmm3, %xmm3
; SSE-NEXT:    psrld %xmm2, %xmm3
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrlq $32, %xmm2
; SSE-NEXT:    pxor %xmm4, %xmm4
; SSE-NEXT:    psrld %xmm2, %xmm4
; SSE-NEXT:    pblendw {{.*#+}} xmm4 = xmm4[0,1,2,3],xmm3[4,5,6,7]
; SSE-NEXT:    pmovzxdq {{.*#+}} xmm2 = xmm0[0],zero,xmm0[1],zero
; SSE-NEXT:    punpckhdq {{.*#+}} xmm0 = xmm0[2],xmm1[2],xmm0[3],xmm1[3]
; SSE-NEXT:    pxor %xmm3, %xmm3
; SSE-NEXT:    psrld %xmm0, %xmm3
; SSE-NEXT:    psrld %xmm2, %xmm1
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1,2,3],xmm3[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1],xmm4[2,3],xmm1[4,5],xmm4[6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_zero:
; AVX:       # BB#0:
; AVX-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpsrlvd %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> zeroinitializer, %x
  ret <4 x i32> %1
}

; fold (srl x, c >= size(x)) -> undef
define <4 x i32> @combine_vec_lshr_outofrange0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_outofrange0:
; SSE:       # BB#0:
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_outofrange0:
; AVX:       # BB#0:
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 33, i32 33, i32 33, i32 33>
  ret <4 x i32> %1
}

define <4 x i32> @combine_vec_lshr_outofrange1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_outofrange1:
; SSE:       # BB#0:
; SSE-NEXT:    xorps %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_outofrange1:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 33, i32 34, i32 35, i32 36>
  ret <4 x i32> %1
}

; fold (srl x, 0) -> x
define <4 x i32> @combine_vec_lshr_by_zero(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_by_zero:
; SSE:       # BB#0:
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_by_zero:
; AVX:       # BB#0:
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, zeroinitializer
  ret <4 x i32> %1
}

; if (srl x, c) is known to be zero, return 0
define <4 x i32> @combine_vec_lshr_known_zero0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_known_zero0:
; SSE:       # BB#0:
; SSE-NEXT:    pand {{.*}}(%rip), %xmm0
; SSE-NEXT:    psrld $4, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_known_zero0:
; AVX:       # BB#0:
; AVX-NEXT:    vpbroadcastd {{.*}}(%rip), %xmm1
; AVX-NEXT:    vpand %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vpsrld $4, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = and <4 x i32> %x, <i32 15, i32 15, i32 15, i32 15>
  %2 = lshr <4 x i32> %1, <i32 4, i32 4, i32 4, i32 4>
  ret <4 x i32> %2
}

define <4 x i32> @combine_vec_lshr_known_zero1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_known_zero1:
; SSE:       # BB#0:
; SSE-NEXT:    pand {{.*}}(%rip), %xmm0
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $11, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $9, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $10, %xmm1
; SSE-NEXT:    psrld $8, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_known_zero1:
; AVX:       # BB#0:
; AVX-NEXT:    vpbroadcastd {{.*}}(%rip), %xmm1
; AVX-NEXT:    vpand %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = and <4 x i32> %x, <i32 15, i32 15, i32 15, i32 15>
  %2 = lshr <4 x i32> %1, <i32 8, i32 9, i32 10, i32 11>
  ret <4 x i32> %2
}

; fold (srl (srl x, c1), c2) -> (srl x, (add c1, c2))
define <4 x i32> @combine_vec_lshr_lshr0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lshr0:
; SSE:       # BB#0:
; SSE-NEXT:    psrld $6, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lshr0:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrld $6, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 2, i32 2, i32 2, i32 2>
  %2 = lshr <4 x i32> %1, <i32 4, i32 4, i32 4, i32 4>
  ret <4 x i32> %2
}

define <4 x i32> @combine_vec_lshr_lshr1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lshr1:
; SSE:       # BB#0:
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $2, %xmm1
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    psrld $3, %xmm0
; SSE-NEXT:    psrld $1, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm0[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1],xmm2[2,3],xmm1[4,5],xmm2[6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    psrld $7, %xmm0
; SSE-NEXT:    movdqa %xmm1, %xmm2
; SSE-NEXT:    psrld $5, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm0[4,5,6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    psrld $6, %xmm0
; SSE-NEXT:    psrld $4, %xmm1
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1,2,3],xmm0[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1],xmm2[2,3],xmm1[4,5],xmm2[6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lshr1:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 0, i32 1, i32 2, i32 3>
  %2 = lshr <4 x i32> %1, <i32 4, i32 5, i32 6, i32 7>
  ret <4 x i32> %2
}

; fold (srl (srl x, c1), c2) -> 0
define <4 x i32> @combine_vec_lshr_lshr_zero0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lshr_zero0:
; SSE:       # BB#0:
; SSE-NEXT:    xorps %xmm0, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lshr_zero0:
; AVX:       # BB#0:
; AVX-NEXT:    vxorps %xmm0, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 16, i32 16, i32 16, i32 16>
  %2 = lshr <4 x i32> %1, <i32 20, i32 20, i32 20, i32 20>
  ret <4 x i32> %2
}

define <4 x i32> @combine_vec_lshr_lshr_zero1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lshr_zero1:
; SSE:       # BB#0:
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $20, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $18, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $19, %xmm1
; SSE-NEXT:    psrld $17, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $28, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $26, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $27, %xmm1
; SSE-NEXT:    psrld $25, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lshr_zero1:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 17, i32 18, i32 19, i32 20>
  %2 = lshr <4 x i32> %1, <i32 25, i32 26, i32 27, i32 28>
  ret <4 x i32> %2
}

; fold (srl (trunc (srl x, c1)), c2) -> (trunc (srl x, (add c1, c2)))
define <4 x i32> @combine_vec_lshr_trunc_lshr0(<4 x i64> %x) {
; SSE-LABEL: combine_vec_lshr_trunc_lshr0:
; SSE:       # BB#0:
; SSE-NEXT:    psrlq $32, %xmm0
; SSE-NEXT:    psrlq $32, %xmm1
; SSE-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,0,2]
; SSE-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    psrld $16, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_trunc_lshr0:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlq $32, %ymm0, %ymm0
; AVX-NEXT:    vpshufd {{.*#+}} ymm0 = ymm0[0,2,2,3,4,6,6,7]
; AVX-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX-NEXT:    vpsrld $16, %xmm0, %xmm0
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = lshr <4 x i64> %x, <i64 32, i64 32, i64 32, i64 32>
  %2 = trunc <4 x i64> %1 to <4 x i32>
  %3 = lshr <4 x i32> %2, <i32 16, i32 16, i32 16, i32 16>
  ret <4 x i32> %3
}

define <4 x i32> @combine_vec_lshr_trunc_lshr1(<4 x i64> %x) {
; SSE-LABEL: combine_vec_lshr_trunc_lshr1:
; SSE:       # BB#0:
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrlq $33, %xmm2
; SSE-NEXT:    psrlq $32, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm2
; SSE-NEXT:    psrlq $35, %xmm2
; SSE-NEXT:    psrlq $34, %xmm1
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,0,2]
; SSE-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $19, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $17, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $18, %xmm1
; SSE-NEXT:    psrld $16, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_trunc_lshr1:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlvq {{.*}}(%rip), %ymm0, %ymm0
; AVX-NEXT:    vpshufd {{.*#+}} ymm0 = ymm0[0,2,2,3,4,6,6,7]
; AVX-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = lshr <4 x i64> %x, <i64 32, i64 33, i64 34, i64 35>
  %2 = trunc <4 x i64> %1 to <4 x i32>
  %3 = lshr <4 x i32> %2, <i32 16, i32 17, i32 18, i32 19>
  ret <4 x i32> %3
}

; fold (srl (trunc (srl x, c1)), c2) -> 0
define <4 x i32> @combine_vec_lshr_trunc_lshr_zero0(<4 x i64> %x) {
; SSE-LABEL: combine_vec_lshr_trunc_lshr_zero0:
; SSE:       # BB#0:
; SSE-NEXT:    psrlq $48, %xmm0
; SSE-NEXT:    psrlq $48, %xmm1
; SSE-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,0,2]
; SSE-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    psrld $24, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_trunc_lshr_zero0:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlq $48, %ymm0, %ymm0
; AVX-NEXT:    vpshufd {{.*#+}} ymm0 = ymm0[0,2,2,3,4,6,6,7]
; AVX-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX-NEXT:    vpsrld $24, %xmm0, %xmm0
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = lshr <4 x i64> %x, <i64 48, i64 48, i64 48, i64 48>
  %2 = trunc <4 x i64> %1 to <4 x i32>
  %3 = lshr <4 x i32> %2, <i32 24, i32 24, i32 24, i32 24>
  ret <4 x i32> %3
}

define <4 x i32> @combine_vec_lshr_trunc_lshr_zero1(<4 x i64> %x) {
; SSE-LABEL: combine_vec_lshr_trunc_lshr_zero1:
; SSE:       # BB#0:
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrlq $49, %xmm2
; SSE-NEXT:    psrlq $48, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm2
; SSE-NEXT:    psrlq $51, %xmm2
; SSE-NEXT:    psrlq $50, %xmm1
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,0,2]
; SSE-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $27, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $25, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $26, %xmm1
; SSE-NEXT:    psrld $24, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_trunc_lshr_zero1:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrlvq {{.*}}(%rip), %ymm0, %ymm0
; AVX-NEXT:    vpshufd {{.*#+}} ymm0 = ymm0[0,2,2,3,4,6,6,7]
; AVX-NEXT:    vpermq {{.*#+}} ymm0 = ymm0[0,2,2,3]
; AVX-NEXT:    vpsrlvd {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = lshr <4 x i64> %x, <i64 48, i64 49, i64 50, i64 51>
  %2 = trunc <4 x i64> %1 to <4 x i32>
  %3 = lshr <4 x i32> %2, <i32 24, i32 25, i32 26, i32 27>
  ret <4 x i32> %3
}

; fold (srl (shl x, c), c) -> (and x, cst2)
define <4 x i32> @combine_vec_lshr_shl_mask0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_shl_mask0:
; SSE:       # BB#0:
; SSE-NEXT:    andps {{.*}}(%rip), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_shl_mask0:
; AVX:       # BB#0:
; AVX-NEXT:    vbroadcastss {{.*}}(%rip), %xmm1
; AVX-NEXT:    vandps %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 =  shl <4 x i32> %x, <i32 2, i32 2, i32 2, i32 2>
  %2 = lshr <4 x i32> %1, <i32 2, i32 2, i32 2, i32 2>
  ret <4 x i32> %2
}

define <4 x i32> @combine_vec_lshr_shl_mask1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_shl_mask1:
; SSE:       # BB#0:
; SSE-NEXT:    pmulld {{.*}}(%rip), %xmm0
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $5, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld $3, %xmm2
; SSE-NEXT:    pblendw {{.*#+}} xmm2 = xmm2[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrld $4, %xmm1
; SSE-NEXT:    psrld $2, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm1[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm2[2,3],xmm0[4,5],xmm2[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_shl_mask1:
; AVX:       # BB#0:
; AVX-NEXT:    vmovdqa {{.*#+}} xmm1 = [2,3,4,5]
; AVX-NEXT:    vpsllvd %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vpsrlvd %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 =  shl <4 x i32> %x, <i32 2, i32 3, i32 4, i32 5>
  %2 = lshr <4 x i32> %1, <i32 2, i32 3, i32 4, i32 5>
  ret <4 x i32> %2
}

; fold (srl (sra X, Y), 31) -> (srl X, 31)
define <4 x i32> @combine_vec_lshr_ashr_sign(<4 x i32> %x, <4 x i32> %y) {
; SSE-LABEL: combine_vec_lshr_ashr_sign:
; SSE:       # BB#0:
; SSE-NEXT:    psrld $31, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_ashr_sign:
; AVX:       # BB#0:
; AVX-NEXT:    vpsrld $31, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = ashr <4 x i32> %x, %y
  %2 = lshr <4 x i32> %1, <i32 31, i32 31, i32 31, i32 31>
  ret <4 x i32> %2
}

; fold (srl (ctlz x), "5") -> x  iff x has one bit set (the low bit).
define <4 x i32> @combine_vec_lshr_lzcnt_bit0(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lzcnt_bit0:
; SSE:       # BB#0:
; SSE-NEXT:    pand {{.*}}(%rip), %xmm0
; SSE-NEXT:    psrld $4, %xmm0
; SSE-NEXT:    pxor {{.*}}(%rip), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lzcnt_bit0:
; AVX:       # BB#0:
; AVX-NEXT:    vpbroadcastd {{.*}}(%rip), %xmm1
; AVX-NEXT:    vpand %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vpsrld $4, %xmm0, %xmm0
; AVX-NEXT:    vpbroadcastd {{.*}}(%rip), %xmm1
; AVX-NEXT:    vpxor %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = and <4 x i32> %x, <i32 16, i32 16, i32 16, i32 16>
  %2 = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %1, i1 0)
  %3 = lshr <4 x i32> %2, <i32 5, i32 5, i32 5, i32 5>
  ret <4 x i32> %3
}

define <4 x i32> @combine_vec_lshr_lzcnt_bit1(<4 x i32> %x) {
; SSE-LABEL: combine_vec_lshr_lzcnt_bit1:
; SSE:       # BB#0:
; SSE-NEXT:    pand {{.*}}(%rip), %xmm0
; SSE-NEXT:    movdqa {{.*#+}} xmm2 = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    pand %xmm2, %xmm1
; SSE-NEXT:    movdqa {{.*#+}} xmm3 = [4,3,2,2,1,1,1,1,0,0,0,0,0,0,0,0]
; SSE-NEXT:    movdqa %xmm3, %xmm4
; SSE-NEXT:    pshufb %xmm1, %xmm4
; SSE-NEXT:    movdqa %xmm0, %xmm1
; SSE-NEXT:    psrlw $4, %xmm1
; SSE-NEXT:    pand %xmm2, %xmm1
; SSE-NEXT:    pxor %xmm2, %xmm2
; SSE-NEXT:    pshufb %xmm1, %xmm3
; SSE-NEXT:    pcmpeqb %xmm2, %xmm1
; SSE-NEXT:    pand %xmm4, %xmm1
; SSE-NEXT:    paddb %xmm3, %xmm1
; SSE-NEXT:    movdqa %xmm0, %xmm3
; SSE-NEXT:    pcmpeqb %xmm2, %xmm3
; SSE-NEXT:    psrlw $8, %xmm3
; SSE-NEXT:    pand %xmm1, %xmm3
; SSE-NEXT:    psrlw $8, %xmm1
; SSE-NEXT:    paddw %xmm3, %xmm1
; SSE-NEXT:    pcmpeqw %xmm2, %xmm0
; SSE-NEXT:    psrld $16, %xmm0
; SSE-NEXT:    pand %xmm1, %xmm0
; SSE-NEXT:    psrld $16, %xmm1
; SSE-NEXT:    paddd %xmm0, %xmm1
; SSE-NEXT:    psrld $5, %xmm1
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_lzcnt_bit1:
; AVX:       # BB#0:
; AVX-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; AVX-NEXT:    vmovdqa {{.*#+}} xmm1 = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15]
; AVX-NEXT:    vpand %xmm1, %xmm0, %xmm2
; AVX-NEXT:    vmovdqa {{.*#+}} xmm3 = [4,3,2,2,1,1,1,1,0,0,0,0,0,0,0,0]
; AVX-NEXT:    vpshufb %xmm2, %xmm3, %xmm2
; AVX-NEXT:    vpsrlw $4, %xmm0, %xmm4
; AVX-NEXT:    vpand %xmm1, %xmm4, %xmm1
; AVX-NEXT:    vpxor %xmm4, %xmm4, %xmm4
; AVX-NEXT:    vpcmpeqb %xmm4, %xmm1, %xmm5
; AVX-NEXT:    vpand %xmm5, %xmm2, %xmm2
; AVX-NEXT:    vpshufb %xmm1, %xmm3, %xmm1
; AVX-NEXT:    vpaddb %xmm1, %xmm2, %xmm1
; AVX-NEXT:    vpcmpeqb %xmm4, %xmm0, %xmm2
; AVX-NEXT:    vpsrlw $8, %xmm2, %xmm2
; AVX-NEXT:    vpand %xmm2, %xmm1, %xmm2
; AVX-NEXT:    vpsrlw $8, %xmm1, %xmm1
; AVX-NEXT:    vpaddw %xmm2, %xmm1, %xmm1
; AVX-NEXT:    vpcmpeqw %xmm4, %xmm0, %xmm0
; AVX-NEXT:    vpsrld $16, %xmm0, %xmm0
; AVX-NEXT:    vpand %xmm0, %xmm1, %xmm0
; AVX-NEXT:    vpsrld $16, %xmm1, %xmm1
; AVX-NEXT:    vpaddd %xmm0, %xmm1, %xmm0
; AVX-NEXT:    vpsrld $5, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = and <4 x i32> %x, <i32 4, i32 32, i32 64, i32 128>
  %2 = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %1, i1 0)
  %3 = lshr <4 x i32> %2, <i32 5, i32 5, i32 5, i32 5>
  ret <4 x i32> %3
}
declare <4 x i32> @llvm.ctlz.v4i32(<4 x i32>, i1)

; fold (srl x, (trunc (and y, c))) -> (srl x, (and (trunc y), (trunc c))).
define <4 x i32> @combine_vec_lshr_trunc_and(<4 x i32> %x, <4 x i64> %y) {
; SSE-LABEL: combine_vec_lshr_trunc_and:
; SSE:       # BB#0:
; SSE-NEXT:    pand {{.*}}(%rip), %xmm1
; SSE-NEXT:    pand {{.*}}(%rip), %xmm2
; SSE-NEXT:    pshufd {{.*#+}} xmm2 = xmm2[0,1,0,2]
; SSE-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; SSE-NEXT:    pblendw {{.*#+}} xmm1 = xmm1[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    movdqa %xmm1, %xmm2
; SSE-NEXT:    psrldq {{.*#+}} xmm2 = xmm2[12,13,14,15],zero,zero,zero,zero,zero,zero,zero,zero,zero,zero,zero,zero
; SSE-NEXT:    movdqa %xmm0, %xmm3
; SSE-NEXT:    psrld %xmm2, %xmm3
; SSE-NEXT:    movdqa %xmm1, %xmm2
; SSE-NEXT:    psrlq $32, %xmm2
; SSE-NEXT:    movdqa %xmm0, %xmm4
; SSE-NEXT:    psrld %xmm2, %xmm4
; SSE-NEXT:    pblendw {{.*#+}} xmm4 = xmm4[0,1,2,3],xmm3[4,5,6,7]
; SSE-NEXT:    pxor %xmm2, %xmm2
; SSE-NEXT:    pmovzxdq {{.*#+}} xmm3 = xmm1[0],zero,xmm1[1],zero
; SSE-NEXT:    punpckhdq {{.*#+}} xmm1 = xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; SSE-NEXT:    movdqa %xmm0, %xmm2
; SSE-NEXT:    psrld %xmm1, %xmm2
; SSE-NEXT:    psrld %xmm3, %xmm0
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1,2,3],xmm2[4,5,6,7]
; SSE-NEXT:    pblendw {{.*#+}} xmm0 = xmm0[0,1],xmm4[2,3],xmm0[4,5],xmm4[6,7]
; SSE-NEXT:    retq
;
; AVX-LABEL: combine_vec_lshr_trunc_and:
; AVX:       # BB#0:
; AVX-NEXT:    vpand {{.*}}(%rip), %ymm1, %ymm1
; AVX-NEXT:    vpshufd {{.*#+}} ymm1 = ymm1[0,2,2,3,4,6,6,7]
; AVX-NEXT:    vpermq {{.*#+}} ymm1 = ymm1[0,2,2,3]
; AVX-NEXT:    vpsrlvd %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vzeroupper
; AVX-NEXT:    retq
  %1 = and <4 x i64> %y, <i64 15, i64 255, i64 4095, i64 65535>
  %2 = trunc <4 x i64> %1 to <4 x i32>
  %3 = lshr <4 x i32> %x, %2
  ret <4 x i32> %3
}
