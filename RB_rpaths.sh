#!/bin/bash -e
FILES_TO_SEARCH="*.dylib"
LIBS_TO_REPLACE="libboost_"

if [[ $# -gt 0 ]]; then
  FILES_TO_SEARCH="$1"
fi
if [[ $# -gt 1 ]]; then
  LIBS_TO_REPLACE="$2"
fi

echo
echo "Searching all dynamic libraries with following pattern: \"$FILES_TO_SEARCH\""
echo "Replacing all references to \"$LIBS_TO_REPLACE\" with absolute paths."
echo
# read -p "Are you sure? (y/n): " -n 1 -r
# echo
# echo
# if ! [[ $REPLY =~ ^[Yy]$ ]]; then
#   exit 0;
# fi

# Loop over all dyld files
files=$(find . -iname "*$FILES_TO_SEARCH*.dylib")

for file in $files; do
  echo
  echo "Processing $file file..."
  # Get dependencies for a given library as array
  IFS=$'\n' lines=($(otool -L $file))
  # Loop over each dependency
  for (( c=1; c<${#lines[@]}; c++ )); do
  	# Strip to just keep library name
  	orig_dependency=$(echo "${lines[c]}" | head -n1 | awk '{print $1;}')
    
    # If library doesn't contain keyword
    shopt -s nocasematch # case insensitive
    if ! [[ "${orig_dependency}" == *"${LIBS_TO_REPLACE}"* ]]; then
      continue;
    # If library already absolute
    elif  [[ "$orig_dependency" == "/"* ]]; then
      continue
    # If library starts with @, then strip until next /
    elif [[ "$orig_dependency" == "@"* ]]; then
      dependency=${orig_dependency#*/}
    else
      dependency=$orig_dependency
    fi
    
    full_path="$(pwd)/$dependency"
    install_name_tool -change "$orig_dependency" "$(pwd)/$dependency" "$file"
    echo "      Changing $orig_dependency to $full_path in $file..."
  done
  exit 1
done