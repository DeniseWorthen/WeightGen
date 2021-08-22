;------------------------------------------------------------------
; Creates SCRIP file with land mask on tripole resolution and then
; creates the mesh file from that SCRIP file
;
; Denise.Worthen@noaa.gov
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; substitute a curvilinear_to_SCRIP.ncl which does not require
; re-ordering the grid
load "my_curvilinear_to_SCRIP.ncl"
;------------------------------------------------------------------
begin
    ; specify locations to use
    ;dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210223/"
    ;dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210223/"
    ;dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210727/"
    ;dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210727/"
    dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-ufs-20210822/"
    dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-ufs-20210822/"

    ; specify the tripole resolution
    cice6res = (/"mx400", "mx100", "mx050", "mx025"/)
    ;cice6res = (/"mx400"/)
    ;cice6res = (/"mx072"/)
    nfiles = dimsizes(cice6res)

  do nf = 0,nfiles-1
    cres = cice6res(nf)
    ; source tripole grid
            srcloc = dirsrc
          gridfile = "tripole."+cres+".nc"
       staggerlocs = (/"Ct"/)
if(1 .eq. 0)then
;----------------------------------------------------------------------
; first generate SCRIP grid files
;----------------------------------------------------------------------

      ii = 0
      gf = addfile(dirsrc+gridfile,"r")

    Opt                   = True
    Opt@ForceOverwrite    = True
    Opt@PrintTimings      = True
    Opt@InterpMethod      = "bilinear"
    Opt@Debug             = True
    Opt@Check             = True

    print("working on stagger loc "+staggerlocs(ii))
          srcfile = dirsrc+staggerlocs(ii)+"."+cres+"_SCRIP_land.nc"
       srclonname = "lon"+staggerlocs(ii)
       srclatname = "lat"+staggerlocs(ii)
    cornerlonname = "lon"+staggerlocs(ii)+"_vert"
    cornerlatname = "lat"+staggerlocs(ii)+"_vert"

     Opt@GridMask      = gf->wet
     Opt@GridCornerLon = gf->$cornerlonname$
     Opt@GridCornerLat = gf->$cornerlatname$
     print("using locations "+srclatname+"  "+\
                              srclonname+"  "+\
                           cornerlatname+"  "+\
                           cornerlonname)

    ; substitue local version of curvilinear_to_SCRIP here
    my_curvilinear_to_SCRIP(srcfile, gf->$srclatname$, gf->$srclonname$, Opt)
    delete(Opt)
end if
          ii = 0
          srcfile = dirsrc+staggerlocs(ii)+"."+cres+"_SCRIP_land.nc"
;----------------------------------------------------------------------
; use the generated SCRIP file to create the mesh
;----------------------------------------------------------------------

  esmfversion = "8.0.1-intel18.0.5.274-impi2018.0.4-netcdf4.7.4_parallel.release/"
  ;esmfversion = "8.1.0bs27-intel18.0.5.274-impi2018.0.4-netcdf4.7.4_parallel.release/"
   esmfbindir = "/scratch1/NCEPDEV/nems/emc.nemspara/soft/esmf/"+esmfversion+"bin/"
     meshname = dirout+"mesh."+cres+".nc"
      esmfcmd = "ESMF_Scrip2Unstruct "+srcfile+" "+meshname+" 0 ESMF"

   syscmd = "module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles"
   system(syscmd)
   syscmd = esmfbindir+esmfcmd
   print("converting to mesh using "+syscmd)
   system(syscmd)

   ;delete([/srcfile, gf/])
   delete([/srcfile/])
 end do ; nfiles
exit
end
