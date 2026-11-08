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
- `kernels/fortran/modexp_dynamic_odd.f90` — Fortran kernel realising
  the same dynamic-window odd-table algorithm with 64-bit limb helpers.
- `kernels/cuda/butterfly_warp_modexp.cu` — CUDA kernel using warp-level
  butterfly addressing (`__shfl_xor_sync`) for reductions and broadcasts
  inside a collaborative modular exponentiation.

## Running

```
julia test/runtests.jl     # the full suite
julia src/FeedbackLoop.jl  # the feedback report on the example snippet
```

### Kernels

```
# Fortran
gfortran -o test_modexp kernels/fortran/modexp_dynamic_odd.f90
./test_modexp

# CUDA (compute capability 7.0+)
nvcc -o butterfly_modexp kernels/cuda/butterfly_warp_modexp.cu -arch=sm_70
./butterfly_modexp
```

The Lean file is checked with a Mathlib-providing Lean environment;
see STATUS.md for the verification record.
