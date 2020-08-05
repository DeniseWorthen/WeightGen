;------------------------------------------------------------------
; Denise.Worthen@noaa.gov  (Feb 2019)
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; substitute a curvilinear_to_SCRIP.ncl which does not require
; re-ordering the grid
load "my_curvilinear_to_SCRIP.ncl"
;------------------------------------------------------------------
begin

    ; specify the MOM6 resolution
    ;cres = "mx050"
    ;cres = "mx025"
    cres = "mx100"

    ; specify a location to use
        nemsrc     = "/scratch2/NCEPDEV/climate/Denise.Worthen/TTout/"

    ; 
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

exit
end

