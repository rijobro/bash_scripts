#!/bin/bash -e

function RB_actual_mount {

  # Figure out if we're on linux or osx
  # Linux
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    volname="fsname"
  # OSX
  else
    extra_flags=",defer_permissions"
    volname="volname"
    local=" -o local"
  fi

  # Make folder if it doesn't already exist
  mkdir -p $2/$3

  # If nothing already mounted (empty)
  if ! [ "$(find "$2/$3" -mindepth 1 -print -quit 2>/dev/null)" ]; then
    echo -e "\nMounting $3..."
    sshfs -o allow_other${extra_flags} $1 $2/$3 -o ${volname}=$3 ${local} \
    && echo -e "\tdone." \
    || echo -e "\tMounting $3 failed."
  else
    echo -e "\n$3 already mounted, nothing to do."
  fi
}

# RDS
if [ "$#" -eq 0 ] || [ $1 == "RDS" ]; then
  RB_actual_mount rmharbr@live.rd.ucl.ac.uk:/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09 ~/Documents/Mounts RDS
fi
# UCL cluster
if [ "$#" -eq 0 ] || [ $1 == "UCL" ]; then
  RB_actual_mount rmharbr@myriad.rc.ucl.ac.uk:/home/rmharbr/                              ~/Documents/Mounts UCL
  RB_actual_mount rmharbr@myriad.rc.ucl.ac.uk:/home/rmharbr/Scratch/Data/Head_Moco        ~/Documents/Mounts UCL_data
fi
# CS cluster
if [ "$#" -eq 0 ] || [ $1 == "CS" ]; then
  RB_actual_mount rbrown@bchuckle.cs.ucl.ac.uk:/home/rbrown/                                  ~/Documents/Mounts CS
  RB_actual_mount rbrown@bchuckle.cs.ucl.ac.uk:/SAN/inm/moco/headmoco                         ~/Documents/Mounts CS_data
fi
# RAL
if [ "$#" -eq 0 ] || [ $1 == "RAL" ]; then
  RB_actual_mount 130.246.214.106:/home/rich/Documents/Data ~/Documents/Mounts RAL_GPU_data
  RB_actual_mount 130.246.214.106:/home/rich/Documents/Code ~/Documents/Mounts RAL_GPU_code
  RB_actual_mount 130.246.214.97:/home/rich/Documents/Data  ~/Documents/Mounts RAL_CPU_data
  RB_actual_mount 130.246.214.97:/home/rich/Documents/Code  ~/Documents/Mounts RAL_CPU_code
fi