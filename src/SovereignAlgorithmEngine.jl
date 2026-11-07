module SovereignAlgorithmEngine

include("WindowedExponentiation.jl")
include("FeedbackLoop.jl")

export dynamic_window, odd_multiples, modexp_dynamic_odd
export AnalysisResult, AlgorithmEngineFeedbackLoop
export tokenize_and_inspect, evaluate_collision, run_feedback_loop

end
