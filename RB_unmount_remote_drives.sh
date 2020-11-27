#!/bin/bash -e

# Loop through all folders in mount directory
for d in ~/Documents/Mounts/* ; do

  mounted=$(mount)
  # If the directory is in the list of mounted drives, unmount.
  if [[ $mounted =~ .*$d.* ]];  then
    echo "about to unmount $d"
    # If sudo
    if [ "$EUID" -ne 0 ]; then
      umount $d
    else
      sudo umount -f $d
    fi
  fi
  # Delete folder
  rm -rf $d
done
