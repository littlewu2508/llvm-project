// RUN: %clang_cc1 -S -emit-llvm %s -o - | FileCheck %s

typedef void (*fptrs_t[4])(void);
fptrs_t p __attribute__((noreturn));

void __attribute__((noreturn)) f() {
  p[0]();
}
// CHECK: call
// CHECK-NEXT: unreachable
