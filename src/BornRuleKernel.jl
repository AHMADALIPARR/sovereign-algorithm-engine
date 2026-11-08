# Quantum Born Rule Skill Expansion Kernel
#
# Models the 1,000+ skill library as a normalized amplitude vector
# and samples a concrete skill via the Born rule collapse
# P(i) = |c_i|^2 when an observer operator is applied.
#
# This kernel sits alongside the modular-arithmetic kernels and provides
# the probabilistic selection layer described in the Autonomous Daemon
# Architecture specification.

export born_rule_collapse, update_amplitudes, skill_catalog_size

const N_SKILLS = 1000

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
