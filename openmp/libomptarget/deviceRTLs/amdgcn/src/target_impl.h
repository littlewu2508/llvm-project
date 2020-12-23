//===------- target_impl.h - AMDGCN OpenMP GPU implementation ----- HIP -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Declarations and definitions of target specific functions and constants
//
//===----------------------------------------------------------------------===//
#ifndef OMPTARGET_AMDGCN_TARGET_IMPL_H
#define OMPTARGET_AMDGCN_TARGET_IMPL_H

#ifndef __AMDGCN__
#error "amdgcn target_impl.h expects to be compiled under __AMDGCN__"
#endif

#include "amdgcn_interface.h"
#include "amdgcn_intrinsics.h"

#include <assert.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>

#ifdef _OPENMP
#define DEVICE
#else
#define DEVICE __attribute__((device))
#endif

#define INLINE inline DEVICE
#define NOINLINE __attribute__((noinline)) DEVICE

#ifdef _OPENMP

// Follows the pattern in interface.h
typedef enum omp_allocator_handle_t {
  omp_null_allocator = 0,
  omp_default_mem_alloc = 1,
  omp_large_cap_mem_alloc = 2,
  omp_const_mem_alloc = 3,
  omp_high_bw_mem_alloc = 4,
  omp_low_lat_mem_alloc = 5,
  omp_cgroup_mem_alloc = 6,
  omp_pteam_mem_alloc = 7,
  omp_thread_mem_alloc = 8,
  KMP_ALLOCATOR_MAX_HANDLE = UINTPTR_MAX
} omp_allocator_handle_t;

#define __p(STR) _Pragma(STR)
#define __p2(STR) __p(#STR)

#define SHARED(NAME)                                                           \
  NAME [[clang::loader_uninitialized]];                                        \
  __p2(omp allocate(NAME) allocator(omp_pteam_mem_alloc))

#define EXTERN_SHARED(NAME)                                                    \
  NAME;                                                                        \
  __p2(omp allocate(NAME) allocator(omp_pteam_mem_alloc))

#else
// HIP
#define SHARED(NAME) __attribute__((shared)) NAME
#define EXTERN_SHARED(NAME) __attribute__((shared)) NAME
#endif

#define ALIGN(N) __attribute__((aligned(N)))

#include "hip_atomics.h"

////////////////////////////////////////////////////////////////////////////////
// Kernel options
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// The following def must match the absolute limit hardwired in the host RTL
// max number of threads per team
#define MAX_THREADS_PER_TEAM 1024

#define WARPSIZE 64

// Maximum number of preallocated arguments to an outlined parallel/simd
// function. Anything more requires dynamic memory allocation.
#define MAX_SHARED_ARGS 40

// Maximum number of omp state objects per SM allocated statically in global
// memory.
#define OMP_STATE_COUNT 32
#define MAX_SM 64

#define OMP_ACTIVE_PARALLEL_LEVEL 128

// Data sharing related quantities, need to match what is used in the compiler.
enum DATA_SHARING_SIZES {
  // The maximum number of workers in a kernel.
  DS_Max_Worker_Threads = 960,
  // The size reserved for data in a shared memory slot.
  DS_Slot_Size = 256,
  // The slot size that should be reserved for a working warp.
  DS_Worker_Warp_Slot_Size = WARPSIZE * DS_Slot_Size,
  // The maximum number of warps in use
  DS_Max_Warp_Number = 16,
};

INLINE void __kmpc_impl_unpack(uint64_t val, uint32_t &lo, uint32_t &hi) {
  lo = (uint32_t)(val & UINT64_C(0x00000000FFFFFFFF));
  hi = (uint32_t)((val & UINT64_C(0xFFFFFFFF00000000)) >> 32);
}

INLINE uint64_t __kmpc_impl_pack(uint32_t lo, uint32_t hi) {
  return (((uint64_t)hi) << 32) | (uint64_t)lo;
}

enum : __kmpc_impl_lanemask_t {
  __kmpc_impl_all_lanes = ~(__kmpc_impl_lanemask_t)0
};

DEVICE __kmpc_impl_lanemask_t __kmpc_impl_lanemask_lt();

DEVICE __kmpc_impl_lanemask_t __kmpc_impl_lanemask_gt();

DEVICE uint32_t __kmpc_impl_smid();

DEVICE double __kmpc_impl_get_wtick();

DEVICE double __kmpc_impl_get_wtime();

INLINE uint64_t __kmpc_impl_ffs(uint64_t x) { return __builtin_ffsl(x); }

INLINE uint64_t __kmpc_impl_popc(uint64_t x) { return __builtin_popcountl(x); }

template <typename T> INLINE T __kmpc_impl_min(T x, T y) {
  return x < y ? x : y;
}

DEVICE __kmpc_impl_lanemask_t __kmpc_impl_activemask();

DEVICE int32_t __kmpc_impl_shfl_sync(__kmpc_impl_lanemask_t, int32_t Var,
                                     int32_t SrcLane);

DEVICE int32_t __kmpc_impl_shfl_down_sync(__kmpc_impl_lanemask_t, int32_t Var,
                                          uint32_t Delta, int32_t Width);

INLINE void __kmpc_impl_syncthreads() { __builtin_amdgcn_s_barrier(); }

INLINE void __kmpc_impl_syncwarp(__kmpc_impl_lanemask_t) {
  // AMDGCN doesn't need to sync threads in a warp
}

// AMDGCN specific kernel initialization
DEVICE void __kmpc_impl_target_init();

// Equivalent to ptx bar.sync 1. Barrier until num_threads arrive.
DEVICE void __kmpc_impl_named_sync(uint32_t num_threads);

INLINE void __kmpc_impl_threadfence() {
  __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "agent");
}

INLINE void __kmpc_impl_threadfence_block() {
  __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "workgroup");
}

INLINE void __kmpc_impl_threadfence_system() {
  __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "");
}

// Calls to the AMDGCN layer (assuming 1D layout)
INLINE int GetThreadIdInBlock() { return __builtin_amdgcn_workitem_id_x(); }
INLINE int GetBlockIdInKernel() { return __builtin_amdgcn_workgroup_id_x(); }
DEVICE int GetNumberOfBlocksInKernel();
DEVICE int GetNumberOfThreadsInBlock();
DEVICE unsigned GetWarpId();
DEVICE unsigned GetLaneId();

// Locks
DEVICE void __kmpc_impl_init_lock(omp_lock_t *lock);
DEVICE void __kmpc_impl_destroy_lock(omp_lock_t *lock);
DEVICE void __kmpc_impl_set_lock(omp_lock_t *lock);
DEVICE void __kmpc_impl_unset_lock(omp_lock_t *lock);
DEVICE int __kmpc_impl_test_lock(omp_lock_t *lock);

// Memory
DEVICE void *__kmpc_impl_malloc(size_t x);
DEVICE void __kmpc_impl_free(void *x);

// DEVICE versions of part of libc
INLINE void __assert_fail(const char *, const char *, unsigned int,
                          const char *) {
  __builtin_trap();
}
EXTERN int printf(const char *, ...);

#endif
