using Test

include(joinpath(@__DIR__, "..", "src", "SovereignAlgorithmEngine.jl"))
using .SovereignAlgorithmEngine

@testset "dynamic window" begin
    @test dynamic_window(1) == 0
    @test dynamic_window(2) == 1
    @test dynamic_window(3) == 2
    @test dynamic_window(255) == 8
    @test dynamic_window(256) == 8
    @test dynamic_window(257) == 9
    @test dynamic_window(1024) == 10
    # The Lean invariant, checked at runtime: 2^(w-1) < n <= 2^w.
    for n in [2, 3, 4, 5, 17, 100, 255, 256, 257, 1000, 1024, 4097]
        w = dynamic_window(n)
        @test 2^(w - 1) < n <= 2^w
    end
end

@testset "odd-only table" begin
    @test odd_multiples(1) == [1]
    @test odd_multiples(3) == [1, 3, 5, 7]
    @test length(odd_multiples(8)) == 2^7
    @test all(isodd, odd_multiples(6))
end

@testset "modexp_dynamic_odd vs powermod" begin
    cases = [
        (5, 0, 7), (5, 1, 7), (2, 10, 1000), (7, 13, 100),
        (123, 456, 789), (999, 999, 10007), (3, 65535, 1000003),
        (10, 20, 999999937), (42, 424242, 100000007),
    ]
    for (g, e, m) in cases
        hint = max(ndigits(big(e), base = 2), 2)
        @test modexp_dynamic_odd(g, e, m; size_hint = hint) == powermod(big(g), big(e), big(m))
    end
    # Larger exponent, several window sizes: result is window-independent.
    g, e, m = big(7), big(2)^200 + 12345, big(10)^30 + 57
    expected = powermod(g, e, m)
    for hint in [8, 64, 201, 256, 1024]
        @test modexp_dynamic_odd(g, e, m; size_hint = hint) == expected
    end
    @test modexp_dynamic_odd(5, 3, 1; size_hint = 2) == powermod(big(5), big(3), big(1))
end

@testset "feedback loop matcher" begin
    engine = AlgorithmEngineFeedbackLoop()

    # The skeleton's supplied example: odd table present; the dynamic
    # patterns require literal log2 forms, which this snippet's
    # log(n)/log(2) spelling does not contain — so it classifies as
    # sliding_window, exactly as the original skeleton classifies it.
    supplied = """
    // Window size scales dynamically
    int w = (int)Math.ceil(Math.log(n) / Math.log(2));
    // Precomputation table stores only odd powers
    vector<Point> lookup(1 << (w - 1));
    for(int i = 0; i < (1 << (w - 1)); i++) {
        lookup[i] = base * (2 * i + 1);
    }
    """
    r = run_feedback_loop(engine, supplied)
    @test r.algorithm_family == "sliding_window"
    @test r.dynamic_window == false
    @test r.odd_only_table == true
    @test r.collision_confidence == 0.85

    adaptive = "int w = ceil(log2(n)); table[i] = base * (2 * i + 1); // odd only"
    r2 = run_feedback_loop(engine, adaptive)
    @test r2.algorithm_family == "adaptive_window_odd"
    @test r2.dynamic_window == true
    @test r2.odd_only_table == true
    @test r2.collision_confidence == 0.98

    plain = "for (i = 0; i < e; i++) { acc = acc * acc; }"
    r3 = run_feedback_loop(engine, plain)
    @test r3.algorithm_family == "fixed_window_binary"
    @test r3.dynamic_window == false
    @test r3.odd_only_table == false
    @test r3.collision_confidence == 0.75

    odd_only = "precompute odd multiples only, constant w = 4"
    r4 = run_feedback_loop(engine, odd_only)
    @test r4.algorithm_family == "sliding_window"
    @test r4.collision_confidence == 0.85
end
