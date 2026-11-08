// CUDA micro-benchmark for Sovereign Algorithm Engine kernels
// Compile: nvcc -O3 -o cuda_bench benchmarks/cuda_bench.cu kernels/cuda/butterfly_warp_modexp.cu kernels/cuda/modinv.cu -arch=sm_70
// (Link the device functions; adjust as needed for your layout.)

#include <cuda_runtime.h>
#include <stdio.h>
#include <stdint.h>

typedef uint32_t limb_t;

// Forward declarations (from the kernel sources)
__global__ void modexp_kernel(limb_t *out, const limb_t *g, const limb_t *e,
                              const limb_t *m, const int *hints, int n);
__device__ limb_t modinv(limb_t x, limb_t m);
__global__ void modinv_kernel(limb_t *out, const limb_t *x, const limb_t *m, int n);

int main() {
  printf("=== Sovereign Algorithm Engine — CUDA Benchmarks ===\n");

  const int nrep = 1000;
  limb_t h_g = 5, h_e = 13, h_m = 100, h_hint = 4;
  limb_t *d_g, *d_e, *d_m, *d_out;
  int *d_hint;

  cudaMalloc(&d_g, sizeof(limb_t));
  cudaMalloc(&d_e, sizeof(limb_t));
  cudaMalloc(&d_m, sizeof(limb_t));
  cudaMalloc(&d_out, sizeof(limb_t));
  cudaMalloc(&d_hint, sizeof(int));

  cudaMemcpy(d_g, &h_g, sizeof(limb_t), cudaMemcpyHostToDevice);
  cudaMemcpy(d_e, &h_e, sizeof(limb_t), cudaMemcpyHostToDevice);
  cudaMemcpy(d_m, &h_m, sizeof(limb_t), cudaMemcpyHostToDevice);
  cudaMemcpy(d_hint, &h_hint, sizeof(int), cudaMemcpyHostToDevice);

  // Warm-up
  modexp_kernel<<<1, 32>>>(d_out, d_g, d_e, d_m, d_hint, 1);
  cudaDeviceSynchronize();

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  cudaEventRecord(start);
  for (int i = 0; i < nrep; ++i)
    modexp_kernel<<<1, 32>>>(d_out, d_g, d_e, d_m, d_hint, 1);
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);

  float ms;
  cudaEventElapsedTime(&ms, start, stop);
  printf("\n[butterfly-warp modexp]\n");
  printf("  5^13 mod 100: %.2f µs/call\n", (ms * 1000.0f) / nrep);

  // modinv
  limb_t hx = 3, hm = 7;
  limb_t *dx, *dm;
  cudaMalloc(&dx, sizeof(limb_t));
  cudaMalloc(&dm, sizeof(limb_t));
  cudaMemcpy(dx, &hx, sizeof(limb_t), cudaMemcpyHostToDevice);
  cudaMemcpy(dm, &hm, sizeof(limb_t), cudaMemcpyHostToDevice);

  cudaEventRecord(start);
  for (int i = 0; i < nrep; ++i)
    modinv_kernel<<<1, 1>>>(d_out, dx, dm, 1);
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  cudaEventElapsedTime(&ms, start, stop);
  printf("\n[modinv]\n");
  printf("  inv(3) mod 7: %.2f µs/call\n", (ms * 1000.0f) / nrep);

  printf("\nDone.\n");

  cudaFree(d_g); cudaFree(d_e); cudaFree(d_m); cudaFree(d_out); cudaFree(d_hint);
  cudaFree(dx); cudaFree(dm);
  return 0;
}
