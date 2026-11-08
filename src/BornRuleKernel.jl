# Quantum Born Rule Skill Expansion Kernel
#
# Models the 1,000+ skill library as a normalized amplitude vector
# and samples a concrete skill via the Born rule collapse
# P(i) = |c_i|^2 when an observer operator is applied.
#
# This kernel sits alongside the modular-arithmetic kernels and provides
# the probabilistic selection layer described in the Autonomous Daemon
# Architecture specification.
#
# Also implements the Quantum Re-Collapse / "Think Again" operator:
# unitary phase rotation via moduli shift followed by a fresh Born collapse.

export born_rule_collapse, update_amplitudes, skill_catalog_size
export RetryDaemon, think_again

const N_SKILLS = 1000
const GOLDEN_RATIO = (1.0 + sqrt(5.0)) / 2.0   # φ ≈ 1.61803398875

"""
    born_rule_collapse(amplitudes::Vector{ComplexF64}) -> Int

Collapse the capability wave function. Returns the index of the selected
skill (1-based) with probability |c_i|^2. Amplitudes must be normalized.
"""
function born_rule_collapse(amplitudes::Vector{ComplexF64})
    length(amplitudes) == N_SKILLS || throw(ArgumentError("expected $N_SKILLS amplitudes"))
    probs = abs2.(amplitudes)
    # Numerical guard
    s = sum(probs)
    s > 0 || throw(ArgumentError("zero probability mass"))
    probs ./= s
    # Inverse transform sampling
    r = rand()
    cum = 0.0
    for i in 1:N_SKILLS
        cum += probs[i]
        if r <= cum
            return i
        end
    end
    return N_SKILLS
end

"""
    update_amplitudes(amplitudes, skill_idx, reward) -> Vector{ComplexF64}

Reinforcement update: boost the amplitude of a successful skill and
re-normalize. reward ∈ [0,1].
"""
function update_amplitudes(amplitudes::Vector{ComplexF64}, skill_idx::Int, reward::Float64)
    1 <= skill_idx <= N_SKILLS || throw(ArgumentError("skill index out of range"))
    0.0 <= reward <= 1.0 || throw(ArgumentError("reward must be in [0,1]"))
    new_amps = copy(amplitudes)
    # Simple multiplicative reinforcement on the magnitude
    mag = abs(new_amps[skill_idx])
    new_amps[skill_idx] *= (1.0 + 0.1 * reward)
    # Re-normalize
    norm = sqrt(sum(abs2, new_amps))
    norm > 0 || return new_amps
    return new_amps ./ norm
end

"""
    skill_catalog_size() -> Int
"""
skill_catalog_size() = N_SKILLS

# ---------------------------------------------------------------------------
# Quantum Re-Collapse / "Think Again" daemon
# ---------------------------------------------------------------------------

mutable struct RetryDaemon
    amplitude_vector::Vector{Float64}
    moduli_state::Float64
    retry_count::Int
end

function RetryDaemon(initial_amplitudes::Vector{Float64})
    length(initial_amplitudes) == N_SKILLS ||
        throw(ArgumentError("expected $N_SKILLS amplitudes"))
    return RetryDaemon(copy(initial_amplitudes), 1.0, 0)
end

"""
    think_again(daemon, feedback_penalty) -> Int

Apply the Quantum Re-Collapse operator:
  1. Shift moduli state by the golden ratio (string-theoretic vacuum shift).
  2. Apply phase modulation and damp amplitudes by the feedback penalty.
  3. Renormalize so that ∑ |c_i|² = 1.
  4. Collapse via Born rule sampling and return the selected skill index.
"""
function think_again(daemon::RetryDaemon, feedback_penalty::Float64)
    0.0 <= feedback_penalty <= 1.0 || throw(ArgumentError("penalty must be in [0,1]"))
    daemon.retry_count += 1

    # 1. Moduli space shift
    daemon.moduli_state *= GOLDEN_RATIO

    # 2. Phase modulation + damping
    for i in 1:N_SKILLS
        phase_modulation = abs(sin(daemon.moduli_state * i))
        daemon.amplitude_vector[i] = max(
            daemon.amplitude_vector[i] * (1.0 - feedback_penalty) + phase_modulation,
            0.01
        )
    end

    # 3. Renormalize
    norm_sq = sum(x -> x * x, daemon.amplitude_vector)
    norm = sqrt(norm_sq)
    if norm > 0
        daemon.amplitude_vector ./= norm
    end

    # 4. Fresh Born collapse (real amplitudes → complex with zero imag)
    complex_amps = complex.(daemon.amplitude_vector)
    return born_rule_collapse(complex_amps)
end
