#!/bin/bash

# this script can be run in an interactive job; set nprocs to the number of processors the interactive job is using
# salloc --x11=first -q debug -t 0:30:00 --nodes=1 -A marine-cpu
#nprocs=4
#rgcmd="mpirun -np "+nprocs
# in a serial job
#rgcmd=""

set -x

module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles
ESMF_BINDIR="/scratch1/NCEPDEV/nems/emc.nemspara/soft/esmf/8.0.1-intel18.0.5.274-impi2018.0.4-netcdf4.7.4_parallel.release/bin"
SCRIP_DIR="/scratch2/NCEPDEV/climate/Denise.Worthen/TTout"
FIX_DIR="/scratch1/NCEPDEV/global/glopara/fix/fix_fv3_gmted2010"
OUT_DIR="/scratch2/NCEPDEV/climate/Denise.Worthen/TTout"
meth="conserve"

#-------------------------------------
# 1deg->C96
#-------------------------------------
sorc="Ct.mx100"
dest="C96"
wgtfile=${OUT_DIR}/${sorc}".to."${dest}".nc"

$rgcmd ${ESMF_BINDIR}/ESMF_RegridWeightGen -s $SCRIP_DIR/${sorc}"_SCRIP_land.nc" -d ${FIX_DIR}/${dest}/${dest}_mosaic.nc -m ${meth} --tilefile_path ${FIX_DIR}/${dest} --ignore_unmapped -w $wgtfile 


#-------------------------------------
# 1/2deg->C192
#-------------------------------------
sorc="Ct.mx050"
dest="C192"
wgtfile=${OUT_DIR}/${sorc}".to."${dest}".nc"

$rgcmd ${ESMF_BINDIR}/ESMF_RegridWeightGen -s $SCRIP_DIR/${sorc}"_SCRIP_land.nc" -d ${FIX_DIR}/${dest}/${dest}_mosaic.nc -m ${meth} --tilefile_path ${FIX_DIR}/${dest} --ignore_unmapped -w $wgtfile

#-------------------------------------
# 1/4deg->C384
#-------------------------------------

sorc="Ct.mx025"
dest="C384"
wgtfile=${OUT_DIR}/${sorc}".to."${dest}".nc"

$rgcmd ${ESMF_BINDIR}/ESMF_RegridWeightGen -s $SCRIP_DIR/${sorc}"_SCRIP_land.nc" -d ${FIX_DIR}/${dest}/${dest}_mosaic.nc -m ${meth} --tilefile_path ${FIX_DIR}/${dest} --ignore_unmapped -w $wgtfile

#-------------------------------------
# 1/4deg->C96
#-------------------------------------

sorc="Ct.mx025"
dest="C96"
wgtfile=${OUT_DIR}/${sorc}".to."${dest}".nc"

$rgcmd ${ESMF_BINDIR}/ESMF_RegridWeightGen -s $SCRIP_DIR/${sorc}"_SCRIP_land.nc" -d ${FIX_DIR}/${dest}/${dest}_mosaic.nc -m ${meth} --tilefile_path ${FIX_DIR}/${dest} --ignore_unmapped -w $wgtfile
