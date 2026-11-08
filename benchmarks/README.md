# Benchmarks

Micro-benchmarks for the Sovereign Algorithm Engine kernels.

## Running

```bash
# Julia (requires BenchmarkTools)
julia -e 'using Pkg; Pkg.add("BenchmarkTools")'
julia benchmarks/julia_bench.jl

# Fortran
gfortran -O3 -o fortran_bench benchmarks/fortran_bench.f90 \
  kernels/fortran/modexp_dynamic_odd.f90 kernels/fortran/modinv.f90
./fortran_bench

# CUDA (sm_70+)
nvcc -O3 -o cuda_bench benchmarks/cuda_bench.cu \
  kernels/cuda/butterfly_warp_modexp.cu kernels/cuda/modinv.cu -arch=sm_70
./cuda_bench
```

## Notes

- Timings are wall-clock averages over repeated calls on small fixed vectors
  (5^13 mod 100, inv(3) mod 7). They are intended for regression tracking,
  not absolute performance claims.
- Full multi-limb production paths are not yet instrumented.
- Results are machine-dependent; record them in STATUS.md after a local run.
