subroutine find_ang

  use param
  use grdvars
  
  implicit none

  ! local variables
  integer :: i,j,m,n
  integer :: im1,jm1,ii,jj

  ! from geolonB fix in MOM6
  real(kind=8) :: len_lon ! The periodic range of longitudes, usually 360 degrees.
  real(kind=8) :: pi_720deg ! One quarter the conversion factor from degrees to radians.
  real(kind=8) :: lonB(2,2)  ! The longitude of a point, shifted to have about the same value.
  real(kind=8) :: lon_scale

  real(kind=8) :: modulo_around_point

!---------------------------------------------------------------------
! rotation angle for "use_bugs" = false case from MOM6
! src/initialization/MOM_shared_initialization.F90 but allow for not
! having halo values
! note this does not reproduce sin_rot,cos_rot found in MOM6 output
! differences are ~O 10-6
!---------------------------------------------------------------------

   pi_720deg = atan(1.0) / 180.0
     len_lon = 360.0
    do j=1,nj; do i = 1,ni
      do n=1,2 ; do m=1,2
                    jj = J+n-2; ii = I+m-2
       if(jj .eq. 0)jj = 1
       if(ii .eq. 0)ii = ni
        lonB(m,n) = modulo_around_point(LonBu(ii,jj), LonCt(i,j), len_lon)
      !  lonB(m,n) = modulo_around_point(LonBu(I+m-2,J+n-2), LonCt(i,j), len_lon)
      enddo ; enddo
                    jj = j-1; ii = i-1
       if(jj .eq. 0)jj = 1
       if(ii .eq. 0)ii = ni
      lon_scale = cos(pi_720deg*((LatBu(ii,jj) + LatBu(I,J)) + &
                                 (LatBu(I,jj) + LatBu(ii,J)) ) )
     anglet(i,j) = atan2(lon_scale*((lonB(1,2) - lonB(2,1)) + (lonB(2,2) - lonB(1,1))), &
                    (LatBu(ii,J) - LatBu(I,jj)) + &
                    (LatBu(I,J) - LatBu(ii,jj)) )
                    
      !lon_scale = cos(pi_720deg*((LatBu(I-1,J-1) + LatBu(I,J)) + &
      !                           (LatBu(I,J-1) + LatBu(I-1,J)) ) )
     !anglet(i,j) = atan2(lon_scale*((lonB(1,2) - lonB(2,1)) + (lonB(2,2) - lonB(1,1))), &
     !               (LatBu(I-1,J) - LatBu(I,J-1)) + &
     !               (LatBu(I,J) - LatBu(I-1,J-1)) )
    enddo ; enddo

end subroutine find_ang

! -----------------------------------------------------------------------------
!> Return the modulo value of x in an interval [xc-(Lx/2) xc+(Lx/2)]
!! If Lx<=0, then it returns x without applying modulo arithmetic.
function modulo_around_point(x, xc, Lx) result(x_mod)
  real(kind=8), intent(in) :: x  !< Value to which to apply modulo arithmetic
  real(kind=8), intent(in) :: xc !< Center of modulo range
  real(kind=8), intent(in) :: Lx !< Modulo range width
  real(kind=8) :: x_mod          !< x shifted by an integer multiple of Lx to be close to xc.

  if (Lx > 0.0) then
    x_mod = modulo(x - (xc - 0.5*Lx), Lx) + (xc - 0.5*Lx)
  else
    x_mod = x
  endif
end function modulo_around_point
