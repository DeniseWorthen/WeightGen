; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;**********************************************************
;**********************************************************
begin

    dirsrc = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210201/"
   dirout = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210201/"

   ; first replicates current baseline c96 test
   fv3res = (/     96,      96,     192,     192,     384,     384,     768/)
  mom6res = (/"mx025", "mx100", "mx050", "mx100", "mx050", "mx025", "mx025"/)
  ; fv3res = (/     96/)
  ;mom6res = (/"mx100"/)
  ; fv3res = (/    192/)
  ;mom6res = (/"mx050"/)

    ntile = 6
   nfiles = dimsizes(fv3res)

   do nf= 0,nfiles-1
      res = fv3res(nf)
     ores = mom6res(nf)
     ares = "C"+fv3res(nf)
  outname = ares+"."+ores+"."
  
    wgtsfile = dirout+"Ct."+ores+".to."+ares+".nc"
      ocngrd = addfile(dirsrc+"Ct."+ores+"_SCRIP_land.nc","r")
    ;print(wgtsfile)
    ;print(ocngrd)
    print(outname)

   ; retrieve lat/lon of cube sphere tiles
    ff = addfile(wgtsfile,"r")
    lat1d = ff->yc_b
    lon1d = ff->xc_b
    lat1d@units = "degrees_N"
    lon1d@units = "degrees_E"
    ;printVarSummary(lat1d)

   ; retrieve regrid weight variables
     col = ff->col
     row = ff->row
       S = ff->S
     n_s = dimsizes(S)

   ; create a field for holding the destination field as 1d
   dst_field = new(dimsizes(lat1d),double,"No_FillValue")
   dst_field = 0.0

  ;print(dimsizes(row))
  ;print(dimsizes(col))
  ;print(dimsizes(S))
  ;print(n_s)
  ;print(dimsizes(dst_field))

  ; reshape variables
  lon3d = new((/ ntile, res, res /), typeof(lon1d))
  lat3d = new((/ ntile, res, res /), typeof(lat1d))
  ;printVarSummary(lat3d)

  do i = 0, ntile-1
   istr = (i*res*res)
   iend = istr+res*res-1
   lat3d(i,:,:) = onedtond(lat1d(istr:iend), (/ res, res /))
   lon3d(i,:,:) = onedtond(lon1d(istr:iend), (/ res, res /))
  end do

  ; retrieve ocean land mask
  i1d = ocngrd->grid_imask
  src_field = new(dimsizes(i1d),double,"No_FillValue")
  src_field = todouble(i1d)
  ;printVarSummary(src_field)
  ;print(dimsizes(src_field))

  ;print(n_s+"  "+dimsizes(dst_field)+"  "+dimsizes(row))
  ;print(dimsizes(src_field)+"  "+dimsizes(col))

  ; ESMF Ref Manual
  ; ("http://www.earthsystemmodeling.org/esmf_releases/public/ESMF_8_0_0/ESMF_refdoc/node3.html#SECTION03020000000000000000")
  do i = 0,n_s-1
    ii = row(i)-1
    jj = col(i)-1
   dst_field(ii) = dst_field(ii) + S(i)*src_field(jj)
  end do
  
;**********************************************************
; pre-define the output file
;**********************************************************

  do i = 0, ntile-1
    ofile = dirout+outname+"tile"+sprinti("%d", i+1)+".nc"
    print("output file "+ofile)
    system("rm -f "+ofile)
    fout = addfile(ofile, "c")
    setfileoption(fout, "DefineMode", True)

    ;--- create dimensions ---
    dimNames = (/ "grid_xt", "grid_yt" /)
    dimSizes = (/ res, res /)
    dimUnlim = (/ False, False /)
    filedimdef(fout, dimNames, dimSizes, dimUnlim)

    ;--- create lat,lon variable ---
    filevardef(fout, "grid_xt", typeof(lon1d), (/ "grid_yt", "grid_xt" /))
    filevardef(fout, "grid_yt", typeof(lat1d), (/ "grid_yt", "grid_xt" /))

    ; Copy attributes associated with each variable to the file
    filevarattdef(fout,  "grid_yt",  lat3d)
    filevarattdef(fout,  "grid_xt",  lon3d)

    ;--- create variable ---
    vname = "land_frac"
    filevardef(fout, vname, typeof(dst_field), (/ "grid_yt", "grid_xt" /))
    setfileoption(fout, "DefineMode", False)

    fout->grid_xt = (/ lon3d(i,:,:) /)
    fout->grid_yt = (/ lat3d(i,:,:) /)
  end do

;**********************************************************
; add variables
;**********************************************************

     vname = "land_frac"
     var3d = new((/ ntile, res, res /), typeof(dst_field), default_fillvalue(typeof(dst_field)) )

     do i = 0, ntile-1
      istr = (i*res*res)
      iend = istr+res*res-1
      var3d(i,:,:) = onedtond(dst_field(istr:iend), (/ res, res /))
     end do

     do i = 0, ntile-1
      ofile = dirout+outname+"tile"+sprinti("%d", i+1)+".nc"
       fout = addfile(ofile, "w")
       fout->$vname$ = (/ var3d(i,:,:) /)
     end do
  delete([/lat1d,lon1d,col,row,S,lat3d,lon3d,i1d,src_field,dst_field,var3d/])
 end do ; nfiles
end
exit
