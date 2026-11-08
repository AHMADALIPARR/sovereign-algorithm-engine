! Sovereign Algorithm Engine — Fortran modular inversion kernel
! Binary extended Euclidean algorithm.
!
! Returns inv such that (inv * x) ≡ 1 (mod m), or sets inv = 0 on failure.

module sovereign_modinv_kernel
  use, intrinsic :: iso_fortran_env, only: int64
  implicit none
  private
  public :: modinv

contains

  function modinv(x, m) result(inv)
    integer(int64), intent(in) :: x, m
    integer(int64) :: inv
    integer(int64) :: u, v, x1, x2, tmp

    if (m < 2) then
      inv = 0
      return
    end if

    u = mod(x, m)
    if (u == 0) then
      inv = 0
      return
    end if
    v = m
    x1 = 1
    x2 = 0

    do while (u /= 0)
      do while (mod(u, 2) == 0)
        u = u / 2
        if (mod(x1, 2) == 0) then
          x1 = x1 / 2
        else
          x1 = (x1 + m) / 2
        end if
      end do
      do while (mod(v, 2) == 0)
        v = v / 2
        if (mod(x2, 2) == 0) then
          x2 = x2 / 2
        else
          x2 = (x2 + m) / 2
        end if
      end do
      if (u >= v) then
        u = u - v
        x1 = x1 - x2
      else
        v = v - u
        x2 = x2 - x1
      end if
    end do

    if (v /= 1) then
      inv = 0
      return
    end if
    inv = mod(x2, m)
  end function modinv

end module sovereign_modinv_kernel

program test_modinv
  use sovereign_modinv_kernel
  implicit none
  integer(int64) :: x, m, inv
  x = 3; m = 7
  inv = modinv(x, m)
  print *, "inv(3) mod 7 =", inv, " (expected 5)"
end program test_modinv
