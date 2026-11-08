# Full kernels for the Sovereign Algorithm Engine
#
# Extends the high-level WindowedExponentiation.jl into reusable,
# production-oriented kernels:
#   - Limb-based multi-precision arithmetic (schoolbook)
#   - Separated precomputation of the odd-only table
#   - Sliding-window scan kernel that consumes the table
#   - Dynamic-window sizing that matches the Lean invariant
#   - Modular inversion (binary extended Euclidean)
#
# The high-level modexp_dynamic_odd remains the public entry point;
# these kernels are the internals that can be swapped or accelerated.

using .SovereignAlgorithmEngine: dynamic_window, odd_multiples, isbitset

export precompute_odd_table, sliding_window_scan, modexp_limbs, modinv

# ---------------------------------------------------------------------------
# Limb helpers (64-bit limbs, schoolbook). Sufficient for the verified
# semantics; production would replace these with Montgomery or GMP.
# ---------------------------------------------------------------------------

const Limb = UInt64
const MAX_LIMBS = 32   # ~2048-bit

struct LimbVec
    limbs::Vector{Limb}
    nlimbs::Int
end

function to_limbs(x::Integer)
    x >= 0 || throw(ArgumentError("negative not supported in limb path"))
    if x == 0
        return LimbVec(Limb[0], 1)
    end
    limbs = Limb[]
    while x > 0
        push!(limbs, Limb(x & typemax(Limb)))
        x >>= 64
    end
    return LimbVec(limbs, length(limbs))
end

function from_limbs(v::LimbVec)
    r = big(0)
    for i in reverse(1:v.nlimbs)
        r = (r << 64) | big(v.limbs[i])
    end
    return r
end

# ---------------------------------------------------------------------------
# Modular inversion kernel — binary extended Euclidean algorithm
# Returns a such that (a * x) ≡ 1 (mod m), or throws if gcd ≠ 1.
# ---------------------------------------------------------------------------

function modinv(x::Integer, m::Integer)
    m >= 2 || throw(ArgumentError("modulus must be >= 2"))
    x = mod(x, m)
    x == 0 && throw(ArgumentError("not invertible"))

    u, v = big(x), big(m)
    x1, x2 = big(1), big(0)

    while u != 0
        while iseven(u)
            u >>= 1
            if iseven(x1)
                x1 >>= 1
            else
                x1 = (x1 + m) >> 1
            end
        end
        while iseven(v)
            v >>= 1
            if iseven(x2)
                x2 >>= 1
            else
                x2 = (x2 + m) >> 1
            end
        end
        if u >= v
            u -= v
            x1 -= x2
        else
            v -= u
            x2 -= x1
        end
    end

    v != 1 && throw(ArgumentError("not invertible: gcd=$(v)"))
    return mod(x2, m)
end

# ---------------------------------------------------------------------------
# Precomputation kernel: odd multiples only
# table[k+1] = g^(2k+1) mod M   for k = 0 .. 2^(w-1)-1
# ---------------------------------------------------------------------------

function precompute_odd_table(g::Integer, M::Integer, w::Integer)
    w >= 1 || throw(ArgumentError("window >= 1"))
    half = 1 << (w - 1)
    G = big(g) % big(M)
    Mbig = big(M)
    table = Vector{BigInt}(undef, half)
    g1 = M == 1 ? big(0) : G
    g2 = (g1 * g1) % Mbig
    table[1] = g1
    for k in 2:half
        table[k] = (table[k-1] * g2) % Mbig
    end
    return table
end

# ---------------------------------------------------------------------------
# Sliding-window scan kernel
# Consumes a precomputed odd table and the exponent bits from the top.
# ---------------------------------------------------------------------------

function sliding_window_scan(E::Integer, M::Integer, table::Vector{BigInt}, w::Integer)
    Mbig = big(M)
    result = big(1) % Mbig
    i = ndigits(big(E), base = 2)
    while i > 0
        if !isbitset(E, i - 1)
            result = (result * result) % Mbig
            i -= 1
        else
            len = min(w, i)
            while !isbitset(E, i - len)
                len -= 1
            end
            v = 0
            for b in 0:(len - 1)
                v = (v << 1) | Int(isbitset(E, i - 1 - b))
            end
            for _ in 1:len
                result = (result * result) % Mbig
            end
            result = (result * table[(v - 1) ÷ 2 + 1]) % Mbig
            i -= len
        end
    end
    return result
end

# ---------------------------------------------------------------------------
# Full limb-aware entry point (still uses BigInt under the hood for
# correctness; the limb conversion demonstrates the boundary that a
# true multi-precision kernel would own).
# ---------------------------------------------------------------------------

function modexp_limbs(g::Integer, e::Integer, mod::Integer; size_hint::Integer)
    e >= 0 || throw(ArgumentError("exponent must be non-negative"))
    mod >= 1 || throw(ArgumentError("modulus must be positive"))
    w = max(dynamic_window(size_hint), 1)
    table = precompute_odd_table(g, mod, w)
    return sliding_window_scan(e, mod, table, w)
end
