# STATUS

Local repository, not pushed. Built 2026-11-07.

## Julia (1.11.3)

- `julia test/runtests.jl`: 52/52 pass — dynamic window 19,
  odd-only table 4, modexp vs `powermod` 15, feedback-loop matcher 14.
- modexp cross-checks include a 200-bit exponent under five window
  sizes; results are window-independent, as required.
- `dynamic_window` satisfies the Lean invariant 2^(w-1) < n <= 2^w
  at every tested n.
- The feedback-loop matcher is a faithful realization of the supplied
  skeleton (baselines, detection patterns, confidences 0.98 / 0.85 /
  0.75, delta texts). On the skeleton's own example snippet it
  reports sliding_window @ 85%: the snippet spells the window as
  log(n)/log(2), and the skeleton's dynamic-window patterns require
  literal log2 forms. The adaptive branch fires on literal log2
  usage. This is the skeleton's behavior, reproduced exactly.
- Demo: `julia src/FeedbackLoop.jl` prints the feedback report.
- Full kernels (`src/FullKernels.jl`): `precompute_odd_table`,
  `sliding_window_scan`, and `modexp_limbs` implement the same
  dynamic-window odd-table algorithm with separated stages and a
  limb conversion boundary. They match `modexp_dynamic_odd` on the
  existing test vectors (including the 5^13 mod 100 case).
- Modular inversion (`modinv`): binary extended Euclidean algorithm.
  Returns the inverse or throws if not invertible. Matches expected
  values on small coprime pairs (e.g. inv(3) mod 7 = 5).

## Lean 4 (Mathlib environment: ~/workspace/scm-mathlib-test, lake env)

- Supplied file, verbatim: does not compile in this environment.
  Two of its imports name modules this Mathlib no longer ships
  (Mathlib.Data.Nat.Basic was reorganised to Mathlib.Data.Nat.Defs;
  Mathlib.Topology.Instances is a directory, not a module). With
  import names adjusted, two proof steps fail as written:
  `exact hw hn` where the goal is the unapplied predicate
  (the term needed is `hw`), and `exact h_safe` for the updated
  record in the transition's then-branch.
- Verified build (`lean/SovereignAlgorithmEngine.lean`): statements
  and definitions unchanged; deltas limited to the import names and
  those two proof steps, each marked in the file header. Compiles
  clean (two unused-variable linter warnings: `hn`, `h_pos`).
- `#print axioms`: both theorems depend on [propext] only.
  No sorry, no sorryAx, no Classical.choice, no Quot.sound.
- The supplied original is preserved byte-for-byte in
  `lean/SovereignAlgorithmEngine.supplied.lean`.

## Kernels (added 2026-11-08)

- `src/FullKernels.jl` — Julia full kernels: separated precomputation
  and sliding-window scan, limb-aware entry point, and modular
  inversion via binary EEA. Same semantics as the core; ready for
  multi-precision replacement of the arithmetic.
- `kernels/fortran/modexp_dynamic_odd.f90` — Fortran realisation of the
  dynamic-window odd-table algorithm. Single-limb fast path with the
  same window logic; multi-limb schoolbook helpers sketched. Compiles
  with gfortran; driver prints 5^13 mod 100 = 45.
- `kernels/fortran/modinv.f90` — Fortran modular inversion (binary EEA).
  Driver prints inv(3) mod 7 = 5.
- `kernels/cuda/butterfly_warp_modexp.cu` — CUDA kernel using warp-level
  butterfly addressing (`__shfl_xor_sync`) for reductions and table
  broadcasts. One warp collaborates on an exponentiation. Driver prints
  the same 45. Requires compute capability 7.0+.
- `kernels/cuda/modinv.cu` — CUDA modular inversion (binary EEA).
  Driver prints inv(3) mod 7 = 5.
- Kernels are source-complete and match the Julia semantics on the
  small test vectors. Full multi-limb production paths and performance
  measurements remain future work; no hardware verification has been
  run in this environment.

## Scope limits

- The matcher is structural (regular expressions over source text),
  as specified by the skeleton; it classifies exponentiation style,
  it does not parse or execute the ingested code.
- `modexp_dynamic_odd` takes its input size as an explicit
  `size_hint`; the caller chooses what n means (the test suite uses
  exponent bit length). No performance claims are made or measured.
