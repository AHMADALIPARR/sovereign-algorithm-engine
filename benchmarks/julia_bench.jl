# Julia micro-benchmarks for Sovereign Algorithm Engine kernels
# Run: julia benchmarks/julia_bench.jl

using BenchmarkTools
using .SovereignAlgorithmEngine

println("=== Sovereign Algorithm Engine — Julia Benchmarks ===")

# --- Modular exponentiation ---
println("\n[modexp_dynamic_odd / modexp_limbs]")
cases = [
    (g=5, e=13, m=100, hint=4),
    (g=7, e=2^20 + 12345, m=10^9 + 7, hint=21),
    (g=3, e=2^64 - 1, m=2^64 - 59, hint=64),
]

for (g, e, m, hint) in cases
    t = @belapsed modexp_limbs($g, $e, $m; size_hint=$hint) samples=10 evals=1
    println("  $(g)^$(e) mod $(m)  (hint=$(hint)): $(round(t*1e6, digits=1)) µs")
end

# --- Modular inversion ---
println("\n[modinv]")
inv_cases = [(3, 7), (17, 10007), (65537, 2^32 - 5)]
for (x, m) in inv_cases
    t = @belapsed modinv($x, $m) samples=20
    println("  inv($(x)) mod $(m): $(round(t*1e6, digits=1)) µs")
end

# --- Born Rule collapse ---
println("\n[born_rule_collapse]")
amps = fill(complex(1.0 / sqrt(1000)), 1000)
t = @belapsed born_rule_collapse($amps) samples=50
println("  1000-skill collapse: $(round(t*1e6, digits=1)) µs")

println("\nDone.")
