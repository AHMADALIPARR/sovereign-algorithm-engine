// Sovereign Algorithm Engine — CUDA modular inversion kernel
// Binary extended Euclidean algorithm, single-thread device function.
//
// Returns inv such that (inv * x) ≡ 1 (mod m), or 0 if not invertible.

#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>

typedef uint64_t limb_t;

__device__ limb_t modinv(limb_t x, limb_t m) {
  if (m < 2) return 0;
  limb_t u = x % m;
  if (u == 0) return 0;
  limb_t v = m;
  limb_t x1 = 1, x2 = 0;

  while (u != 0) {
    while ((u & 1) == 0) {
      u >>= 1;
      if ((x1 & 1) == 0) x1 >>= 1;
      else x1 = (x1 + m) >> 1;
    }
    while ((v & 1) == 0) {
      v >>= 1;
      if ((x2 & 1) == 0) x2 >>= 1;
      else x2 = (x2 + m) >> 1;
    }
    if (u >= v) {
      u -= v;
      x1 -= x2;
    } else {
      v -= u;
      x2 -= x1;
    }
  }
  if (v != 1) return 0;
  return x2 % m;
}

__global__ void modinv_kernel(limb_t *out, const limb_t *x, const limb_t *m, int n) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  if (idx < n) out[idx] = modinv(x[idx], m[idx]);
}

int main() {
  limb_t hx = 3, hm = 7, h_out;
  limb_t *dx, *dm, *d_out;
  cudaMalloc(&dx, sizeof(limb_t));
  cudaMalloc(&dm, sizeof(limb_t));
  cudaMalloc(&d_out, sizeof(limb_t));
  cudaMemcpy(dx, &hx, sizeof(limb_t), cudaMemcpyHostToDevice);
  cudaMemcpy(dm, &hm, sizeof(limb_t), cudaMemcpyHostToDevice);
  modinv_kernel<<<1, 1>>>(d_out, dx, dm, 1);
  cudaMemcpy(&h_out, d_out, sizeof(limb_t), cudaMemcpyDeviceToHost);
  printf("CUDA modinv(3) mod 7 = %llu (expected 5)\n", (unsigned long long)h_out);
  cudaFree(dx); cudaFree(dm); cudaFree(d_out);
  return 0;
}
