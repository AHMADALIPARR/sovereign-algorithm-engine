# SovereignAlgorithmEngine — the windowed exponentiation core.
#
# Two mechanisms define the engine:
#   1. Dynamic window sizing: w = ceil(log2(n)), scaling with input
#      size rather than a fixed constant.
#   2. Odd-only lookup tables: precomputed multiples restricted to
#      odd values (1P, 3P, 5P, ...), 2^(w-1) entries, halving memory
#      against a full 2^w table and streamlining indexing.

"""
    dynamic_window(n) -> Int

The dynamic window size w = ceil(log2(n)) for integer n >= 2, computed
exactly (no floating point): w is the unique value satisfying
2^(w-1) < n <= 2^w — the invariant the Lean model states as
`satisfiesDynamicWindow`. Returns 0 for n <= 1.
"""
function dynamic_window(n::Integer)
    n <= 1 && return 0
    return ndigits(n - 1, base = 2)
end

"""
    odd_multiples(w) -> Vector{Int}

The odd-only table's index set for window w: the odd values
1, 3, 5, ..., 2^w - 1 — exactly 2^(w-1) entries. The table entry for
odd value v = 2k + 1 sits at index k + 1, so indexing is (v - 1) / 2.
"""
function odd_multiples(w::Integer)
    w >= 1 || throw(ArgumentError("window must be >= 1"))
    return [2i + 1 for i in 0:(2^(w - 1) - 1)]
end

isbitset(x::Integer, k::Integer) = !iszero((x >> k) & 1)

"""
    modexp_dynamic_odd(g, e, mod; size_hint) -> BigInt

Modular exponentiation g^e mod mod by the dynamic-window, odd-only
method: the window w = ceil(log2(size_hint)) scales with the declared
input size; the precomputation table holds only the odd multiples
g^1, g^3, ..., g^(2^w - 1). The exponent is scanned from the top:
zero bits square, and each maximal window of length <= w ending in a
1 bit contributes one table lookup — the standard sliding-window
recoding in which every window value is odd by construction.
"""
function modexp_dynamic_odd(g::Integer, e::Integer, mod::Integer; size_hint::Integer)
    e >= 0 || throw(ArgumentError("exponent must be non-negative"))
    mod >= 1 || throw(ArgumentError("modulus must be positive"))
    G, E, M = big(g), big(e), big(mod)
    w = max(dynamic_window(size_hint), 1)
    half = 2^(w - 1)
    # Precompute odd multiples only: table[k + 1] = g^(2k + 1) mod mod.
    table = Vector{BigInt}(undef, half)
    g1 = mod == 1 ? big(0) : G % M
    g2 = (g1 * g1) % M
    table[1] = g1
    for k in 2:half
        table[k] = (table[k - 1] * g2) % M
    end
    result = big(1) % M
    i = ndigits(E, base = 2)  # next bit position to consume, from the top
    while i > 0
        if !isbitset(E, i - 1)
            result = (result * result) % M
            i -= 1
        else
            len = min(w, i)
            # Shrink the window until its lowest bit is 1 (window value odd).
            while !isbitset(E, i - len)
                len -= 1
            end
            v = 0
            for b in 0:(len - 1)
                v = (v << 1) | Int(isbitset(E, i - 1 - b))
            end
            for _ in 1:len
                result = (result * result) % M
            end
            result = (result * table[(v - 1) ÷ 2 + 1]) % M
            i -= len
        end
    end
    return result
end
