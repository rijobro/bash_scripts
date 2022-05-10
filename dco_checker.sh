#!/bin/bash

set -e # stop on error

################################################################################
# Usage
################################################################################
print_usage()
{
	# Display Help
	echo 'Sign off any commits.'
	echo
	echo 'Syntax: dco_checker.sh [-h|--help] [-n|--num <val>]'
	echo
	echo 'options:'
	echo '-h, --help          : Print this help.'
	echo
	echo '-n, --num           : Max number of commits into past to check.'
	echo
}

################################################################################
# parse input arguments
################################################################################
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-h|--help)
			print_usage
			exit 0
		;;
		-n|--num)
			max_commits_to_check=$2
			shift
		;;
		*)
			print_usage
			exit 1
		;;
	esac
	shift
done

# Default variables
: ${max_commits_to_check:=2}

# check we're on a branch
branch_name=$(git rev-parse --abbrev-ref --symbolic-full-name HEAD)
if [ $branch_name == HEAD ]; then
	echo Not on a branch!
	exit 1
fi

# check clean
gsp=$(git status --porcelain)
if (( $? != 0 )); then
    echo "git status --porcelain failed"
    exit 1
elif ! [ -z "$gsp" ]; then
	echo Uncommited changes!
	exit 1
fi

# create backup branch
backup_branch_name=${branch_name}_backup_$(date +"%Y-%m-%d_%H-%M-%S")
echo -e "\nCreating backup branch: ${backup_branch_name}...\n"
git branch "${branch_name}_backup_$(date +"%Y-%m-%d_%H-%M-%S")"

# if something goes wrong, set branch back to original
function cleanup {
	echo Something gone wrong or cancelled. Resetting...
	git reset --hard $backup_branch_name
	git branch -d "${backup_branch_name}"
	exit 1
}
trap cleanup EXIT

# go back desired number of commits
git reset --hard HEAD~$(( ${max_commits_to_check} - 1 ))

# work forwards using git reset. When first unsigned commit is found, sign
# that off. From then on, use cherry-pick because we're changing the history.
num_signed_off=0
use_cherry_pick=false
for i in $(git log --reverse --ancestry-path $branch_name...$backup_branch_name --format=format:%H); do
	if ! git log -1 | grep -q 'Signed-off-by'; then
		echo "Not signed off. Signing off now..."
		git commit --amend -s --no-edit
		((num_signed_off+=1))
		use_cherry_pick=true
	fi

	if [ $use_cherry_pick = true ]; then
		git cherry-pick $i -m 1
	else
		git reset --hard $i
	fi
done

# if we're here, all went well. If no changes made, delete backup
trap - EXIT
echo -e "\nDone!"
echo "Number of commits signed off: ${num_signed_off}"
if [ $num_signed_off -eq 0 ]; then
	echo "Deleting backup..."
	git branch -D "${backup_branch_name}"
fi
