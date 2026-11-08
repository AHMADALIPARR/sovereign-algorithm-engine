module SovereignAlgorithmEngine

include("WindowedExponentiation.jl")
include("FeedbackLoop.jl")
include("FullKernels.jl")
include("BornRuleKernel.jl")

export dynamic_window, odd_multiples, modexp_dynamic_odd
export AnalysisResult, AlgorithmEngineFeedbackLoop
export tokenize_and_inspect, evaluate_collision, run_feedback_loop
export precompute_odd_table, sliding_window_scan, modexp_limbs, modinv
export born_rule_collapse, update_amplitudes, skill_catalog_size
export RetryDaemon, think_again

end
