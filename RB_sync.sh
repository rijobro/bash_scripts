#!/bin/bash -e

# Usage
usage="$(basename "$0") [-h] src dst [-x] [-d] [-i include] [-e exclude] 

  rsync data

  where:
    -h   show this help text
    src  source
    dst  destination
    -x   delete folders in destination that are not in source
    -d   dry run
    -i   include pattern (can be used multiple times)
    -e   exlude pattern (can be used multiple times)"


# Not enough arguments
if [ $# -lt 2 ]; then
  echo "$usage" >&2
  exit 1
fi

# Get source and destination folders. shift to ignore from rest
src=$1
dst=$2
shift 2

# Argument parsing
while getopts ":i:e:hdx" optname; do
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

# Remove trailing slashes from src and dst (but add one back in for src)
function RB_remove_trailing_slashes() {
  VAR=$1
  while [ $(echo "${VAR: -1}") == "/" ]; do
    VAR=${VAR%?};
  done
  echo "${VAR}"
}
src=$(RB_remove_trailing_slashes "${src}/${subfolder}")/
dst=$(RB_remove_trailing_slashes "${dst}/${subfolder}")

# Set up includes and excludes
for i in "${exclude[@]}"; do
  exclude_str="$exclude_str --exclude=$i"
done
for i in "${include[@]}"; do
  include_str="$include_str --include=$i"
done

# Print info
echo -e "\nCopying from:\n\t${src}\nto:\n\t${dst}\n"

command="rsync"
# Dry run
if (( dry == 1 )); then
  command="$command --dry-run"
fi
# Delete
if (( delete == 1 )); then
  command="$command --delete"
fi

command="$command -auCOmvzh --stats --no-o --no-g --no-p"
# If version recent enough, use --info=progress2
if [[ $(rsync --version | grep 2018) ]]; then
  command="$command --info=progress2"
fi
command="$command ${include_str} ${exclude_str} ${src} ${dst}"

echo -e "Here's the command:\n\n${command}\n"

# Keep looping in case of dropped connection
while [ 1 ]
do
  # This is the actual rsync command
  ${command}
  # If exit code is not 0, retry
  if [ "$?" != "0" ] ; then
    echo "Rsync failure. Backing off and retrying..."
    sleep 60
  else
    echo "rsync completed normally"
    exit
  fi
done