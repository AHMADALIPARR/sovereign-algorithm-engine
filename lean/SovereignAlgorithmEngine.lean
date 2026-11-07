-- SovereignAlgorithmEngine — verified build.
-- Statements and definitions are the owner's, unchanged. Three deltas
-- from the supplied original (kept verbatim in
-- SovereignAlgorithmEngine.supplied.lean), each forced by the
-- toolchain and recorded in STATUS.md:
--   1. Import names updated to this Mathlib's module layout.
--   2. adaptive_window_collision_safe: `exact hw` for `exact hw hn`.
--   3. feedback_preserves_safety, then-branch: the updated record is
--      rebuilt from h_safe's components instead of `exact h_safe`.
--
import Mathlib.Data.Nat.Defs
import Mathlib.Data.Real.Basic
import Mathlib.Topology.Instances.Real

namespace SovereignAlgorithmEngine

-- 1. Define the execution configuration space of the windowed exponentiation engine
structure ExponentiationConfig where
  inputSize : Nat
  windowSize : Nat
  isOddOnlyTable : Bool
  deriving Repr

-- 2. Define the expected dynamic window invariant: w = ceil(log2(n)) represented via natural bounds
def satisfiesDynamicWindow (n w : Nat) : Prop :=
  n > 0 → (2 ^ (w - 1) < n) ∧ (n ≤ 2 ^ w)

-- 3. Define the collision analysis safety predicate
-- An engine state is collision-safe if it correctly isolates odd tables and obeys logarithmic window bounds
def IsCollisionSafe (cfg : ExponentiationConfig) : Prop :=
  cfg.inputSize > 0 →
  cfg.isOddOnlyTable = true ∧
  satisfiesDynamicWindow cfg.inputSize cfg.windowSize

-- 4. Theorem: The adaptive window odd-power construction preserves collision safety bounds
theorem adaptive_window_collision_safe
  (n w : Nat) (hn : n > 0) (hw : satisfiesDynamicWindow n w) :
  IsCollisionSafe { inputSize := n, windowSize := w, isOddOnlyTable := true } := by
  intro h_pos
  constructor
  · rfl -- Proves isOddOnlyTable is true by construction
  · exact hw

-- 5. Verification of Feedback Loop Invariant Mapping
-- Ensures that the feedback delta engine never downgrades to an unverified constant-window state
-- when operating under sovereign adaptive policies.
def feedbackLoopTransition (cfg : ExponentiationConfig) : ExponentiationConfig :=
  if cfg.inputSize > 1 then
    { cfg with windowSize := cfg.windowSize, isOddOnlyTable := true }
  else
    cfg

theorem feedback_preserves_safety (cfg : ExponentiationConfig) (h_safe : IsCollisionSafe cfg) :
  IsCollisionSafe (feedbackLoopTransition cfg) := by
  dsimp [feedbackLoopTransition]
  split
  · intro h_pos
    exact ⟨rfl, (h_safe h_pos).2⟩
  · exact h_safe

end SovereignAlgorithmEngine
