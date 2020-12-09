#!/bin/bash -e

# Usage
usage="$(basename "$0") [-h] command [-s start] [-e end] 

  modify jobs on the cluster with qdel, qhold and qrls

  where:
    -h       show this help text
    command  qdel, qhold or qrls
    -s       start index (if not present, do all jobs less than end index)
    -e       end index (if not present, do all jobs greater than start index)"

# No arguments
if [ $# -eq 0 ]; then
  echo "$usage" >&2
  exit 1
fi


# Get command. shift to ignore from rest
cmd=$1
if [ $cmd != "qdel" ] && [ $cmd != "qhold" ] && [ $cmd != "qrls" ]; then
  echo "Invalid command: $cmd" >&2
  exit
fi
shift

# Argument parsing
while getopts ":s:e:h" optname; do
  case "$optname" in
    "h")
      echo "$usage"
      exit 0;
      ;;
    "s")
      start=$OPTARG
      ;;
    "e")
      end=$OPTARG
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

qstat_output=$(qstat)
i=0
echo "$qstat_output" | while read line ; do
  i=$((i + 1))
  # Ignore table header
  if (( i < 3 )); then
    continue
  fi
  jobid=$(echo "$line" | awk '{print $1;}')
  # If "start" was set and jobid is less than start, skip
  if [ -n "$start" ] && (( jobid < start )); then
    continue
  # If "end" was set and jobid is greater than end, skip
  elif [ -n "$end" ] && (( jobid > end )); then
    continue
  fi
  $cmd "$jobid"
done