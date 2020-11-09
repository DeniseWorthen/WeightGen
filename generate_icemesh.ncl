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
    ; specify a location to use
        nemsrc     = "/scratch2/NCEPDEV/climate/Denise.Worthen/TTout2/"

    ; specify the tripole resolution
    cice6res = (/"mx100", "mx050", "mx025"/)
    nfiles = dimsizes(cice6res)

  do nf = 0,nfiles-1
    cres = cice6res(nf)
    ; source tripole grid
            srcloc = nemsrc
          gridfile = "tripole."+cres+".nc"
       staggerlocs = (/"Ct"/)

;----------------------------------------------------------------------
; first generate SCRIP grid files
;----------------------------------------------------------------------

      ii = 0
      gf = addfile(nemsrc+gridfile,"r")

    Opt                   = True
    Opt@ForceOverwrite    = True
    Opt@PrintTimings      = True
    Opt@InterpMethod      = "bilinear"
    Opt@Debug             = True
    Opt@Check             = True

    print("working on stagger loc "+staggerlocs(ii))
          srcfile = nemsrc+staggerlocs(ii)+"."+cres+"_SCRIP_land.nc"
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

;----------------------------------------------------------------------
; use the generated SCRIP file to create the mesh
;----------------------------------------------------------------------

   esmfbindir = "/scratch1/NCEPDEV/nems/emc.nemspara/soft/esmf/8.0.1-intel18.0.5.274-impi2018.0.4-netcdf4.7.4_parallel.release/bin/"
     meshname = nemsrc+"mesh."+cres+".nc"
      esmfcmd = "ESMF_Scrip2Unstruct "+srcfile+" "+meshname+" 0 ESMF"

   syscmd = "module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles"
   system(syscmd)
   syscmd = esmfbindir+esmfcmd
   print("converting to mesh using "+syscmd)
   system(syscmd)

   delete([/srcfile, gf/])
 end do ; nfiles
exit
end
