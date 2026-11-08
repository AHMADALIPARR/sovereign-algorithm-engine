# Sovereign Algorithm Engine

A windowed modular-exponentiation engine and the feedback loop that
analyses exponentiation code against it.

Two mechanisms define the engine:

1. **Dynamic window sizing** — the window scales with input size,
   w = ceil(log2(n)), rather than sitting at a fixed constant.
2. **Odd-only lookup tables** — the precomputed multiples are
   restricted to odd values (1P, 3P, 5P, ...): 2^(w-1) entries,
   half the memory of a full table, with table index (v - 1) / 2.

## Layout

- `src/WindowedExponentiation.jl` — the engine core: `dynamic_window`
  (exact integer ceil(log2(n))), `odd_multiples` (the table's index
  set), and `modexp_dynamic_odd`, a sliding-window exponentiation over
  BigInt whose precomputation table holds odd multiples only.
- `src/FullKernels.jl` — full kernels that separate precomputation
  (`precompute_odd_table`) from the sliding-window scan
  (`sliding_window_scan`), provide a limb-aware entry point
  (`modexp_limbs`), and modular inversion (`modinv`) via binary EEA.
  Same dynamic-window odd-table semantics.
- `src/BornRuleKernel.jl` — Quantum Born Rule skill collapse kernel.
  Models a 1,000-skill library as a normalized amplitude vector and
  samples a concrete skill via \(P(i) = |c_i|^2\). Supports amplitude
  reinforcement from execution rewards. Includes the Quantum Re-Collapse
  `RetryDaemon` (`think_again`) that performs a golden-ratio moduli
  shift followed by a fresh Born collapse.
- `src/FeedbackLoop.jl` — the Algorithm Engine Feedback Loop: it
  ingests code or IR, runs a structural token/pattern matcher to
  isolate modular exponentiation blocks, computes collision metrics
  against known baselines (fixed-window binary, standard m-ary
  sliding window, adaptive window odd), and emits the divergence
  delta as the feedback report of the cycle.
- `lean/SovereignAlgorithmEngine.lean` — the Lean 4 model of the
  engine's configuration space: the dynamic-window invariant
  2^(w-1) < n <= 2^w, the collision-safety predicate, and proofs that
  the adaptive construction and the feedback-loop transition preserve
  safety. `lean/SovereignAlgorithmEngine.supplied.lean` is the
  supplied original, kept verbatim.
- `test/runtests.jl` — the Julia test suite.
- `kernels/architecture/AutonomousDaemonArchitecture.md` — specification
  of the Autonomous Feedback Loop Daemon Architecture and the Quantum
  Born Rule Skill Expansion Engine (1,000+ skills, 10 clusters).
- `kernels/fortran/modexp_dynamic_odd.f90` — Fortran kernel realising
  the same dynamic-window odd-table algorithm with 64-bit limb helpers.
- `kernels/fortran/modinv.f90` — Fortran modular inversion (binary EEA).
- `kernels/fortran/retry_daemon.f90` — Fortran port of the Quantum
  Re-Collapse `RetryDaemon` (moduli shift + Born re-collapse).
- `kernels/cuda/butterfly_warp_modexp.cu` — CUDA kernel using warp-level
  butterfly addressing (`__shfl_xor_sync`) for reductions and broadcasts
  inside a collaborative modular exponentiation.
- `kernels/cuda/modinv.cu` — CUDA modular inversion (binary EEA).
- `benchmarks/` — micro-benchmark scripts for Julia, Fortran, and CUDA.

## Running

```
julia test/runtests.jl     # the full suite
julia src/FeedbackLoop.jl  # the feedback report on the example snippet
```

### Kernels

```
# Julia full kernels (same semantics)
julia -e 'using .SovereignAlgorithmEngine; println(modexp_limbs(5, 13, 100; size_hint=4)); println(modinv(3, 7))'

# Born Rule collapse (uniform amplitudes → random skill)
julia -e 'using .SovereignAlgorithmEngine; amps = fill(complex(1/sqrt(1000)), 1000); println(born_rule_collapse(amps))'

# Quantum Re-Collapse / Think Again
julia -e 'using .SovereignAlgorithmEngine; amps = fill(1.0/sqrt(1000), 1000); d = RetryDaemon(amps); println(think_again(d, 0.2))'

# Fortran
gfortran -o test_modexp kernels/fortran/modexp_dynamic_odd.f90
./test_modexp
gfortran -o test_modinv kernels/fortran/modinv.f90
./test_modinv
gfortran -o test_retry kernels/fortran/retry_daemon.f90
./test_retry

# CUDA (compute capability 7.0+)
nvcc -o butterfly_modexp kernels/cuda/butterfly_warp_modexp.cu -arch=sm_70
./butterfly_modexp
nvcc -o modinv kernels/cuda/modinv.cu -arch=sm_70
./modinv
```

## Benchmarks

Micro-benchmarks live in `benchmarks/` and cover the modular-exponentiation,
modular-inversion, and Born Rule kernels.

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

See `benchmarks/README.md` for details. Timings are wall-clock averages on
small fixed vectors and are intended for regression tracking; they are
machine-dependent and do not constitute absolute performance claims.

The Lean file is checked with a Mathlib-providing Lean environment;
see STATUS.md for the verification record.
