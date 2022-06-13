#!/bin/bash

#----------------------------------------------------------------------
# Retrieve gfs v16 data.  v16 was officially implemented on 12 UTC
# March 22, 2021.  However, the way the switch over was done,
# the 'prod' v16 tarballs started March 21, 2021 06Z.
#----------------------------------------------------------------------

bundle=$1

set -x

cd $EXTRACT_DIR

date10_m6=`$NDATE -6 $yy$mm$dd$hh`

echo $date10_m6
yy_m6=$(echo $date10_m6 | cut -c1-4)
mm_m6=$(echo $date10_m6 | cut -c5-6)
dd_m6=$(echo $date10_m6 | cut -c7-8)
hh_m6=$(echo $date10_m6 | cut -c9-10)

#----------------------------------------------------------------------
# Get the atm and sfc 'anl' netcdf files from the gfs or gdas
# tarball.
#----------------------------------------------------------------------

if [ "$bundle" = "gdas" ] || [ "$bundle" = "gfs" ]; then

  if [ "$bundle" = "gdas" ] ; then
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_nc.tar
  else
    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_prod_gfs.${yy}${mm}${dd}_${hh}.gfs_nca.tar
  fi

  rm -f ./list.hires*
  touch ./list.hires3
  htar -tvf  $directory/$file > ./list.hires1
  grep "anl.nc" ./list.hires1 > ./list.hires2
  while read -r line
  do 
    echo ${line##*' '} >> ./list.hires3
  done < "./list.hires2"

  htar -xvf $directory/$file -L ./list.hires3
  rc=$?
  [ $rc != 0 ] && exit $rc

  rm -f ./list.hires*

#----------------------------------------------------------------------
# Get the 'abias' and radstat files when processing 'gdas'.
#----------------------------------------------------------------------

  if [ "$bundle" = "gdas" ] ; then

    directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
    file=com_gfs_prod_gdas.${yy}${mm}${dd}_${hh}.gdas_restart.tar

    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_air
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_int
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.abias_pc
    rc=$?
    [ $rc != 0 ] && exit $rc
    htar -xvf $directory/$file ./gdas.${yy}${mm}${dd}/${hh}/atmos/gdas.t${hh}z.radstat
    rc=$?
    [ $rc != 0 ] && exit $rc

  fi


elif [ "$bundle" = "gefs" ]; then

  RUNMEM=${RUNMEM:-"c00"}

  mkdir -p $EXTRACT_DIR/${bundle}.${yy}${mm}${dd}/${hh}/${RUNMEM}/atmos
  cd $EXTRACT_DIR/${bundle}.${yy}${mm}${dd}/${hh}/${RUNMEM}/atmos

  directory=/NCEPPROD/hpssprod/runhistory/rh${yy}/${yy}${mm}/${yy}${mm}${dd}
  file=com_gfs_prod_gfs.${yy}${mm}${dd}_${hh}.gfs_nca.tar

  rm -f ./list.hires*
  touch ./list.hires3
  htar -tvf  $directory/$file > ./list.hires1
  if [[ $RUNMEM == "c00" ]]; then
    grep "anl.nc" ./list.hires1 > ./list.hires2
  else
    grep "sfcanl.nc" ./list.hires1 > ./list.hires2
  fi
  while read -r line
  do
    echo ${line##*' '} >> ./list.hires3
  done < "./list.hires2"

  htar -xvf $directory/$file -L ./list.hires3
  rc=$?
  [ $rc != 0 ] && exit $rc

  rm -f ./list.hires*

  cp ./gfs.${yy}${mm}${dd}/${hh}/atmos/gfs.t${hh}z.*anl.nc .
  rm -rf ./gfs.${yy}${mm}${dd}

  if [[ $RUNMEM != "c00" ]]; then # Other members

    export MEMBER=`echo ${RUNMEM:-"c00"}|cut -c2-3`
    if [ $MEMBER -gt 90 ]; then
      sgrp=10
    elif [ $MEMBER -gt 80 ]; then
      sgrp=9
    elif [ $MEMBER -gt 70 ]; then
      sgrp=8
    elif [ $MEMBER -gt 60 ]; then
      sgrp=7
    elif [ $MEMBER -gt 50 ]; then
      sgrp=6
    elif [ $MEMBER -gt 40 ]; then
      sgrp=5
    elif [ $MEMBER -gt 30 ]; then
      sgrp=4
    elif [ $MEMBER -gt 20 ]; then
      sgrp=3
    elif [ $MEMBER -gt 10 ]; then
      sgrp=2
    elif [ $MEMBER -gt 0 ]; then
      sgrp=1
    else
      sgrp=5
    fi

    group=grp${sgrp}
    directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy_m6}/${yy_m6}${mm_m6}/${yy_m6}${mm_m6}${dd_m6}
    file=com_gfs_prod_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar

    rm -f ./list*.${group}
    htar -tvf  $directory/$file > ./list1.${group}
    grep "atmf006.nc" ./list1.${group} > ./list2.${group}
    grep "mem001" ./list2.${group} > ./list22.${group}
    while read -r line
    do
      echo ${line##*' '} >> ./list3.${group}
    done < "./list22.${group}"
    htar -xvf $directory/$file  -L ./list3.${group}
    rc=$?
    [ $rc != 0 ] && exit $rc

    sFile=`cat ./list3.${group}`
    cp $sFile .
    rm -rf ./enkfgdas.${yy_m6}${mm_m6}${dd_m6}
    rm -f ./list*.${group}
  fi
#----------------------------------------------------------------------
# Get the enkf netcdf history files.  They are not saved for the
# current cycle.  So get the 6-hr forecast files from the
# previous cycle.
#----------------------------------------------------------------------

else

  group=$bundle

  directory=/NCEPPROD/hpssprod/runhistory/5year/rh${yy_m6}/${yy_m6}${mm_m6}/${yy_m6}${mm_m6}${dd_m6}
  file=com_gfs_prod_enkfgdas.${yy_m6}${mm_m6}${dd_m6}_${hh_m6}.enkfgdas_${group}.tar

  rm -f ./list*.${group}
  htar -tvf  $directory/$file > ./list1.${group}
  grep "006.nc" ./list1.${group} > ./list2.${group}
  while read -r line
  do 
    echo ${line##*' '} >> ./list3.${group}
  done < "./list2.${group}"
  htar -xvf $directory/$file  -L ./list3.${group}
  rc=$?
  [ $rc != 0 ] && exit $rc
  rm -f ./list*.${group}

fi

set +x
echo DATA PULL FOR $bundle DONE

exit 0
