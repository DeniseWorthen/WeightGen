;------------------------------------------------------------------
; Denise.Worthen@noaa.gov  (Feb 2019)
;
; This script will generate the weights required for both
; unstaggering of velocities on the MOM6 and CICE tripole grids
; as well as bilinear and conservative regridding to pre-defined
; rectilinear grids. Weights will be generated using NCL's ESMF
; regridding script which relies on ESMF_RegridWeightGen.
;
; Prior to running this script, a file containing all the stagger
; locations and their vertices must be created. This file
; should be created by reading the MOM6 supergrid. This script
; assumes the file exists and is named "tripole.CRES.nc" where
; CRES describes the MOM6 resolution (mx025 = 1/4 deg, mx050 =
; 1/2 deg, mx100 = 1.0 deg)
;
; Generating accurate conservative weights requires that the
; vertices of the center T grid cell be given. These values
; are available in the tripole.CRES.nc file.
;
; The tripole.CRES.nc file is created using the gen_fixgrid.F90
; and associated code.
;
; Unless the underlying tripole grid changes, this script needs to be
; run one time only.
;
; If the environment variable NumProc is set prior to running this
; script, the weight generation will use NumProc to create the weights.
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; substitute a curvilinear_to_SCRIP.ncl which does not require
; re-ordering the grid
load "my_curvilinear_to_SCRIP.ncl"
;------------------------------------------------------------------
begin

    ; the weights need to generated one time only. The following
    ; flags will re-generate the chosen weights file
    generate_srcgrid_SCRIP_files = False
    ; next four are to generate weights -> rectilinear grid
    ; used for post
    generate_dstgrid_SCRIP_files = False
    generate_unstagger_weights = False
    generate_restagger_weights = False
    generate_tripole_rect_weights = False
    ; if set True, requires that the mx025 SCRIP file has been generated
    ; used for regridding 025 tripole field -> lower resolution tripole grid
    generate_tripole_tripole_weights = True

    ; specify the MOM6 resolution
    ; 025 must be run before lower resolutions in order to generate
    ; tripole to tripole weights
    ;cres = "mx025"
    ;cres = "mx050"
    ;cres = "mx100"
    cres = "mx400"

    ; specify locations to use
    ;    dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/GRIDS/"
    ;    dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/GRIDS/"
    ;    dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210727/"
    ;    dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-20210727/"
        dirsrc  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-ufs-20210822/"
        dirout  = "/scratch2/NCEPDEV/climate/Denise.Worthen/grids-ufs-20210822/"
    ; interpolation methods
    methods     = (/"bilinear" ,"conserve"/)

    ; source tripole grid
       gridfile = "tripole."+cres+".nc"
    staggerlocs = (/"Ct", "Cu", "Cv", "Bu"/)

    ; destination grids
    if(cres .eq. "mx025")then
       dstgrds  = (/    "0p25",     "0p5",  "1p0"/)
       dstres   = (/ "0.25deg",  "0.5deg", "1deg"/)

       dstlonbeg = (/  0.00,    0.00,   0.00/)
       dstlonend = (/359.75,  359.50, 359.00/)
       dstlatbeg = (/-90.00,  -90.00, -90.00/)
       dstlatend = (/ 90.00,   90.00,  90.00/)

        dstxdim  = (/1440,    720,   360/)
        dstydim  = (/ 721,    361,   181/)
    end if
    if(cres .eq. "mx050")then
       dstgrds   = (/     "0p5",  "1p0"/)
       dstres    = (/  "0.5deg", "1deg"/)

       dstlonbeg = (/  0.00,   0.00/)
       dstlonend = (/359.50, 359.00/)
       dstlatbeg = (/-90.00, -90.00/)
       dstlatend = (/ 90.00,  90.00/)

        dstxdim  = (/   720,   360/)
        dstydim  = (/   361,   181/)
    end if
    if(cres .eq. "mx100")then
       dstgrds   = (/  "1p0"/)
       dstres    = (/ "1deg"/)

       dstlonbeg = (/   0.00/)
       dstlonend = (/ 359.00/)
       dstlatbeg = (/ -90.00/)
       dstlatend = (/  90.00/)

        dstxdim  = (/   360/)
        dstydim  = (/   181/)
    end if

   if(generate_srcgrid_SCRIP_files)then
;----------------------------------------------------------------------
; for each stagger grid, first generate SCRIP grid files which will be
; used in the gen_weights call
;----------------------------------------------------------------------

      gf = addfile(dirsrc+gridfile,"r")
   do ii = 0,dimsizes(staggerlocs)-1

    Opt                   = True
    Opt@ForceOverwrite    = True
    Opt@PrintTimings      = True
    Opt@InterpMethod      = "bilinear"
    Opt@Debug             = True
    Opt@Check             = True

    print("working on stagger loc "+staggerlocs(ii))
          srcfile = dirout+staggerlocs(ii)+"."+cres+"_SCRIP.nc"
       srclonname = "lon"+staggerlocs(ii)
       srclatname = "lat"+staggerlocs(ii)
    cornerlonname = "lon"+staggerlocs(ii)+"_vert"
    cornerlatname = "lat"+staggerlocs(ii)+"_vert"

     Opt@GridCornerLon = gf->$cornerlonname$
     Opt@GridCornerLat = gf->$cornerlatname$
     print("using locations "+srclatname+"  "+\
                              srclonname+"  "+\
                           cornerlatname+"  "+\
                           cornerlonname)

    ; substitue local version of curvilinear_to_SCRIP here
    my_curvilinear_to_SCRIP(srcfile, gf->$srclatname$, gf->$srclonname$, Opt)
    delete(Opt)
   end do

    ; close
    delete(gf)
   end if

   if(generate_unstagger_weights)then
;----------------------------------------------------------------------
; generate the weights used to unstagger the grids
;----------------------------------------------------------------------

     dstfile = dirout+"Ct."+cres+"_SCRIP.nc"
    do ii = 1,dimsizes(staggerlocs)-1

     Opt                   = True
     Opt@ForceOverwrite    = True
     Opt@PrintTimings      = True
     Opt@InterpMethod      = "bilinear"
     Opt@Debug             = True
     Opt@Check             = True

     srcfile = dirout+staggerlocs(ii)+"."+cres+"_SCRIP.nc"
     ; this is the file containing the weights
     wgtfile = dirout+"tripole."+cres+"."+staggerlocs(ii)+".to.Ct.bilinear.nc"

     ESMF_regrid_gen_weights(srcfile,dstfile,wgtfile,Opt)
     delete(Opt)
    end do
    ;close
    delete(dstfile)
    delete(srcfile)
    delete(wgtfile)
   end if

   if(generate_restagger_weights)then
;----------------------------------------------------------------------
; generate the weights used to restagger the grids. these can be used
; for example when changing MOM6 IC resolutions
;----------------------------------------------------------------------

     srcfile = dirout+"Ct."+cres+"_SCRIP.nc"
    do ii = 1,dimsizes(staggerlocs)-1

     Opt                   = True
     Opt@ForceOverwrite    = True
     Opt@PrintTimings      = True
     Opt@InterpMethod      = "bilinear"
     Opt@Debug             = True
     Opt@Check             = True

     dstfile = dirout+staggerlocs(ii)+"."+cres+"_SCRIP.nc"
     ; this is the file containing the weights
     wgtfile = dirout+"tripole."+cres+".Ct.to."+staggerlocs(ii)+".bilinear.nc"

     ESMF_regrid_gen_weights(srcfile,dstfile,wgtfile,Opt)
     delete(Opt)
    end do
    ;close
    delete(dstfile)
    delete(srcfile)
    delete(wgtfile)
   end if

   if(generate_dstgrid_SCRIP_files)then
;----------------------------------------------------------------------
;
;----------------------------------------------------------------------

     do ii = 0,dimsizes(dstgrds)-1

     ; rectilinear destination
     Opt                   = True
     Opt@ForceOverwrite    = True
     Opt@PrintTimings      = True
     Opt@Debug             = True
     Opt@Check             = True

     lons = fspan(dstlonbeg(ii),dstlonend(ii),dstxdim(ii))
     lats = fspan(dstlatbeg(ii),dstlatend(ii),dstydim(ii))
     ;print(dimsizes(lons))
     ;print(dimsizes(lats))
     Opt@LLCorner          = (/ -90.d,   0.d/)
     Opt@URCorner          = (/  90.d, 360.d/)

     Opt@DstGridLat = lats
     Opt@DstGridLon = lons
  
     dstfile = dirout+"rect."+dstgrds(ii)+"_SCRIP.nc"
     print("generating dstfile "+dstfile)
     rectilinear_to_SCRIP(dstfile,lats,lons,Opt)
     delete(lons)
     delete(lats)
     delete(Opt)
    end do
   end if

   if(generate_tripole_rect_weights)then
;----------------------------------------------------------------------
; generate the weight file  for tripole Ct->rect
;----------------------------------------------------------------------

    do jj = 0,dimsizes(methods)-1
      Opt                   = True
      Opt@ForceOverwrite    = True
      Opt@PrintTimings      = True
      Opt@InterpMethod      = methods(jj)
      Opt@Debug             = True
      Opt@Check             = True

     srcfile = dirout+"Ct."+cres+"_SCRIP.nc"
     do ii = 0,dimsizes(dstgrds)-1
      dstfile = dirout+"rect."+dstgrds(ii)+"_SCRIP.nc"
      ;this file contains the weights
      wgtfile = dirout+"tripole."+cres+".Ct.to.rect."+dstgrds(ii)+"."+methods(jj)+".nc"
      ESMF_regrid_gen_weights(srcfile,dstfile,wgtfile,Opt)
     end do

    end do
   end if

   if(generate_tripole_tripole_weights)then
    if(cres .ne. "mx025")then    ; don't try to generate mx025->mx025 weights
;----------------------------------------------------------------------
; generate the weight file  for tripole Ct->tripole Ct
; bilinear only
;----------------------------------------------------------------------

    if(cres .eq. "mx050")then              ; 1/4 => 1/2 tripole
      srccres = "mx025"
      dstcres = "mx050"
    end if
    if(cres .eq. "mx100")then              ; 1/4 => 1deg tripole
      srccres = "mx025"
      dstcres = "mx100"
    end if
    if(cres .eq. "mx400")then              ; 1/4 => 4deg tripole
      srccres = "mx025"
      dstcres = "mx400"
    end if
    
    ; abort of the Ct SCRIP file for the mx025 grid has not yet been
    ; created
    exists = isfilepresent(dirout+"Ct."+srccres+"_SCRIP.nc")
    if(.not.exists)then
     print ("============ ERROR =========")
     print("First generate the file "+dirout+"Ct."+srccres+"_SCRIP.nc")
     exit()
    end if
 
    ; re-define interpolation methods
    methods := (/"bilinear" ,"neareststod"/)
    
     do jj = 0,dimsizes(methods)-1
      srcfile = dirout+"Ct."+srccres+"_SCRIP.nc"
      dstfile = dirout+"Ct."+dstcres+"_SCRIP.nc"

       Opt                   = True
       Opt@ForceOverwrite    = True
       Opt@PrintTimings      = True
       Opt@InterpMethod      = methods(jj)
       Opt@Debug             = True
       Opt@Check             = True

       ;this file contains the weights
       wgtfile = dirout+"tripole."+srccres+".Ct.to."+dstcres+".Ct."+methods(jj)+".nc"
       ESMF_regrid_gen_weights(srcfile,dstfile,wgtfile,Opt)

     end do
    end if
   end if

exit
end
