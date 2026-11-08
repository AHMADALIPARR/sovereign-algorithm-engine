! Fortran micro-benchmark driver
! Compile: gfortran -O3 -o fortran_bench benchmarks/fortran_bench.f90 kernels/fortran/modexp_dynamic_odd.f90 kernels/fortran/modinv.f90
! (Adjust module names / linking as needed; this is a self-contained timing harness.)

program fortran_bench
  use, intrinsic :: iso_fortran_env, only: int64, real64
  implicit none

  integer(int64) :: g, e, m, hint, r, inv
  real(real64) :: t0, t1, elapsed
  integer :: i, nrep

  print *, "=== Sovereign Algorithm Engine — Fortran Benchmarks ==="

  ! --- modexp (single-limb path) ---
  print *, ""
  print *, "[modexp_dynamic_odd]"
  nrep = 10000
  g = 5; e = 13; m = 100; hint = 4
  call cpu_time(t0)
  do i = 1, nrep
    r = modexp_dynamic_odd(g, e, m, hint)
  end do
  call cpu_time(t1)
  elapsed = (t1 - t0) / nrep * 1.0e6
  print *, "  5^13 mod 100:", elapsed, "µs/call"

  ! --- modinv ---
  print *, ""
  print *, "[modinv]"
  nrep = 100000
  g = 3; m = 7
  call cpu_time(t0)
  do i = 1, nrep
    inv = modinv(g, m)
  end do
  call cpu_time(t1)
  elapsed = (t1 - t0) / nrep * 1.0e6
  print *, "  inv(3) mod 7:", elapsed, "µs/call"

  print *, ""
  print *, "Done."
end program fortran_bench
