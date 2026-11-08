module SovereignAlgorithmEngine

include("WindowedExponentiation.jl")
include("FeedbackLoop.jl")
include("FullKernels.jl")

export dynamic_window, odd_multiples, modexp_dynamic_odd
export AnalysisResult, AlgorithmEngineFeedbackLoop
export tokenize_and_inspect, evaluate_collision, run_feedback_loop
export precompute_odd_table, sliding_window_scan, modexp_limbs, modinv

end
