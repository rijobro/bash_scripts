# HISTORY OPTIONS
HISTFILESIZE=1000000000
HISTSIZE=1000000000
HISTCONTROL=ignoredups:erasedups # Avoid duplicates
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Allows for searching after entering part of command
bind '"[A":history-search-backward'
bind '"[B":history-search-forward'

git config --global user.name "rijobro"
git config --global user.email "richard.brown@ucl.ac.uk"

######################################################
#                   LINUX
######################################################
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	alias open='xdg-open'
	# Save github password for an hour
	git config --global credential.helper cache
	git config --global credential.helper 'cache --timeout=3600'
fi

######################################################
#                   Notifications
######################################################

function RB_disp_notification {
	if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		zenity --notification --text="${1}: ${2}"
	elif [ "$(uname)" == "Darwin" ]; then
		$(osascript -e "display notification \"$2\" with title \"$1\"")
	fi

}
export -f RB_disp_notification
function RB_make {
	make "$@"
	result=$?
	if [ $result -eq 0 ];
	then
		RB_disp_notification "Build complete" "Success!"
	elif [ ! $result -eq 130 ];
	then
		RB_disp_notification "Build complete" "Failed!"
	fi
} 
export -f RB_make