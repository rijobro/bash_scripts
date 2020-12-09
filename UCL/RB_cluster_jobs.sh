#!/bin/bash -e

# Use watchall if installed. Else use watch
#if [[ ! -z $(command -v watchall) ]]; then
#	WATCH="watchall -n 10"
#else
#	WATCH="watch --interval=10 -t --color"
#fi
WATCH="watch --interval=10 -t --color"


# Print whole job names
export qstata="qstat -xml | tr '\n' ' ' | sed 's#<job_list[^>]*>#\n#g' | sed 's#<[^>]*>##g' | grep ' ' | column -t"

# Find any successfully completed jobs. Delete their log, and delete the empty log that will
# have been left in the working directory
export delete_successful=' \
	find ~/Code/cluster_scripts/0_Successful/ -name "*.sh.o*" | while read path1; do \
    	filename=$(basename "$path1"); \
    	find ~/Scratch/Data/Head_Moco -name "$filename" -not -path '*/\.*' | while read path2; do \
			rm $path2; \
		done; \
		mv $path1 ~/Code/cluster_scripts/2_Successful_archive/; \
	done; '

# Find any unsuccessfully completed jobs. Move their log to an archive (to avoid searching again),
# and delete the empty log that will have been left in the working directory.
export delete_unsuccessful=' \
	find ~/Code/cluster_scripts/1_Unsuccessful/ -name "*.sh.o*" | while read path1; do \
    	filename=$(basename "$path1"); \
    	find ~/Scratch/Data/Head_Moco -name "$filename" -not -path '*/\.*' | while read path2; do \
			rm $path2; \
		done; \
		mv $path1 ~/Code/cluster_scripts/3_Unsuccessful_archive/; \
	done; '

# Run the qstat command (with header saying how many are running of how many in total).
export qstat_command=' \
	# Get number of jobs running versus total number \
	running=$(expr $(qstat -s r | wc -l) - 2) && \
	if (( running < 0)); then \
		running=0; \
	fi && \
	total=$(expr $(qstat -u $USER | wc -l) - 2) && \
	if (( total > 0)); then \
		echo -e "\e[42mRunning $running jobs of $total\e[0m"; \
		eval $qstata; \
	else \
		echo "No jobs in the queue"; \
	fi; '

# List the unsuccessful jobs that are in the unsuccessful archive folder
export unsuccessful_list_command=' \
	failed=$(ls ~/Code/cluster_scripts/3_Unsuccessful_archive); \
	if [ ! -z "$failed" ]; then \
		num_failed=$(echo -e $failed | wc -w); \
		echo -e "\e[41m\nListing $num_failed failed jobs below:"; \
		echo -e "$failed\n\e[0m"; \
	fi '

# Call all commands
$WATCH -d ' \
	date; \
	$(command -v lquota); \
	eval "$unsuccessful_list_command"; \
	eval "$qstat_command"; \
	eval "$delete_successful"; \
	eval "$delete_unsuccessful"; \
	'
