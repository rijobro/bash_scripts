#!/bin/bash -e

# Usage
usage="$(basename "$0") [-h] src dst [-s subfolder] [-x] [-d] [-i include] [-e exclude]

  rsync data in the headmoco directory

  where:
    -h   show this help text
    src  either absolute path (can be remote) or automatically pick by entering: "OSX", "Linux", "UCL", "RDS" or "CS".
    dst  either absolute path (can be remote) or automatically pick by entering: "OSX", "Linux", "UCL", "RDS" or "CS".
    -s   subfolder to rsync
    -x   delete folders in destination that are not in source
    -d   dry run
    -i   include pattern (can be used multiple times)
    -e   exclude pattern (can be used multiple times)"

# Get source
if [ ! -z "$1" ] && [ "$1" != -h ]; then
  src="$1"
  shift
fi
# Get destination
if [ ! -z "$1" ] && [ "$1" != -h ]; then
  dst="$1"
  shift
fi

# Argument parsing
while getopts ":s:i:e:hdx" optname; do
  echo "$OPTARG"
  case "$optname" in
    "h")
      echo "$usage"
      exit 0;
      ;;
    "d")
      dry=1
      ;;
    "x")
      delete=1
      ;;
    "s")
      subfolder=$OPTARG
      ;;
    "i")
      include+=("$OPTARG")
      ;;
    "e")
      exclude+=("$OPTARG")
      ;;
    "?")
      echo "Unknown option $OPTARG"
      exit 0;
      ;;
    ":")
      echo "No argument value for option $OPTARG"
      exit 0;
      ;;
    *)
      echo "Unknown error while processing options"
      exit 0;
      ;;
  esac
done
shift $((OPTIND - 1))

# Check source and destination have been entered
if [ -z "$src" ] || [ -z "$dst" ]; then
  echo "$usage" >&2
  exit 1
fi

function RB_get_src_and_dst() {
  VAR=$1
  # OSX
  if [ "${VAR}" == "OSX" ]; then
    if [ ! -d "/Volumes/RBrown/Head_Moco" ]; then
      echo "Error: OSX external hard drive not available" >&2
      exit 1
    fi
    VAR="/Volumes/RBrown/Head_Moco"
  # Linux
  elif [ "${VAR}" == "Linux" ]; then
    if [ ! -d "/media/rich/RBrown/Head_Moco" ]; then
      echo "Error: Linux external hard drive not available" >&2
      exit 1
    fi
    VAR="/media/rich/RBrown/Head_Moco"
  # UCL cluster
  elif [ "${VAR}" == "UCL" ]; then
    if [ -d "/home/rmharbr/Scratch/Data/Head_Moco" ]; then
      VAR="/home/rmharbr/Scratch/Data/Head_Moco"
    else
      VAR="rmharbr@myriad.rc.ucl.ac.uk:/home/rmharbr/Scratch/Data/Head_Moco"
    fi
  # RDS service
  elif [ "${VAR}" == "RDS" ]; then
    if [ -d "/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09" ]; then
      VAR="/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09"
    else
      VAR="rmharbr@live.rd.ucl.ac.uk:/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09"
    fi
  # CS cluster
  elif [ "${VAR}" == "CS" ]; then
    if [ -d "/SAN/inm/moco/headmoco" ]; then
      VAR="/SAN/inm/moco/headmoco"
    else
      VAR="rbrown@jet.cs.ucl.ac.uk:/slms/inm/research/moco/headmoco"
    fi
  fi
  echo "${VAR}"
}
src=$(RB_get_src_and_dst "${src}")
dst=$(RB_get_src_and_dst "${dst}")

# Exclude extra patterns
exclude+=("forASH")
exclude+=("inm-Projects")
exlucde+=("Neck_vs_Head_movement")
exclude+=("processing")
exclude+=("**.o")
exclude+=("**~")
exclude+=("**.exe")
exclude+=("**/.**")
exclude+=("**.sh.o*")

# Set up includes and excludes
for i in "${exclude[@]}"; do
  exclude_str="$exclude_str -e $i"
done
for i in "${include[@]}"; do
  include_str="$include_str -i $i"
done

# Create command
command="RB_sync.sh ${src}/${subfolder} ${dst}/${subfolder} "
if (( dry == 1 )); then
  command="${command} -d"
fi
if (( delete == 1)); then
  command="${command} -x"
fi
command="${command} ${include_str} ${exclude_str}"
eval "${command}"