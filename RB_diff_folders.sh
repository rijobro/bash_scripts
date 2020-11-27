#!/bin/bash -e

echo "Normal folders include:"
echo -e "\t(1) /Volumes/RBrown/Head_Moco"
echo -e "\t(2) /media/rich/RBrown/Head_Moco"
echo -e "\t(3) /SAN/inm/moco/headmoco"
echo -e "\t(4) rbrown@jet.cs.ucl.ac.uk:/slms/inm/research/moco/headmoco"
echo -e "\t(5) rmharbr@myriad.rc.ucl.ac.uk:/home/rmharbr/Scratch/Data/Head_Moco"
echo -e "\t(6) rmharbr@live.rd.ucl.ac.uk:/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09"
echo -e "\t(7) /home/rmharbr/Scratch/Data/Head_Moco"

# Ask for source directory
read -e -p 'Source directory: ' src
read -e -p 'Destination directory: ' dst
read -e -p 'Subfolder: ' subfolder

function RB_choose_with_numbers() {
  VAR=$1
  if [ "${VAR}" == "1" ]; then
	VAR="/Volumes/RBrown/Head_Moco"
  elif [ "${VAR}" == "2" ]; then
	VAR="/media/rich/RBrown/Head_Moco"
  elif [ "${VAR}" == "3" ]; then
    VAR="/SAN/inm/moco/headmoco"
  elif [ "${VAR}" == "4" ]; then
    VAR="rbrown@jet.cs.ucl.ac.uk:/slms/inm/research/moco/headmoco"
  elif [ "${VAR}" == "5" ]; then
    VAR="rmharbr@myriad.rc.ucl.ac.uk:/home/rmharbr/Scratch/Data/Head_Moco"
  elif [ "${VAR}" == "6" ]; then
    VAR="rmharbr@live.rd.ucl.ac.uk:/mnt/gpfs/live/ritd-ag-project-rd00qt-rbrow09"
  elif [ "${VAR}" == "7" ]; then
    VAR="/home/rmharbr/Scratch/Data/Head_Moco"
  fi
  echo "${VAR}"
}
src=$(RB_choose_with_numbers "${src}")
dst=$(RB_choose_with_numbers "${dst}")

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

# Exclude certain patterns
exclude="--exclude=forASH --exclude=inm-Projects --exclude=Neck_vs_Head_movement --exclude=processing --exclude=**.o --exclude=**~ --exclude=**.exe --exclude=**/.** --exclude=**.sh.o*"
echo -e "\nAlready excluding following patterns: ${exclude}\n"
read -e -p 'Extra excludes? (format: --exclude=PATTERN1 [space] --exclude=PATTERN2): ' extra_excludes
if [ ! -z "$extra_excludes" ]; then
  exclude="${extra_excludes},${exclude}"
fi

command="rsync -avun --delete ${exclude} ${src} ${dst}"
echo "${command}"
${command}