if [ -n "$ZSH_VERSION" ]; then
	shell=zsh
elif [ -n "$BASH_VERSION" ]; then
	shell=bash
else
	echo "Not sure what type of terminal we're in!"
fi

# HISTORY OPTIONS
HISTFILESIZE=1000000000
HISTSIZE=1000000000
# When the shell exits, append to the history file instead of overwriting it
if [[ "$shell" == "zsh" ]]; then
	HISTFILE=~/.zsh_history     #Where to save history to disk
	SAVEHIST=$HISTSIZE          #Number of history entries to save to disk
	HISTDUP=erase               #Erase duplicates in the history file
	setopt    appendhistory     #Append history to the history file (no overwriting)
	setopt    sharehistory      #Share history across terminals
	setopt    incappendhistory  #Immediately append to the history file, not just when a term is killed
elif [[ "$shell" == "bash" ]]; then
	# After each command, append to the history file and reread it
	HISTCONTROL=ignoredups:erasedups # Avoid duplicates
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
fi

# If interactive
if [ ! -z "$PS1" ]; then
	# Allows for searching after entering part of command
	if [[ "$shell" == "zsh" ]]; then
		autoload -U up-line-or-beginning-search
		autoload -U down-line-or-beginning-search
		zle -N up-line-or-beginning-search
		zle -N down-line-or-beginning-search
		bindkey "^[[A" up-line-or-beginning-search # Up
		bindkey "^[[B" down-line-or-beginning-search # Down
	elif [[ "$shell" == "bash" ]]; then
		bind '"[A":history-search-backward'
		bind '"[B":history-search-forward'
	fi
fi

git config --global user.name "rijobro"
git config --global user.email "richard.brown@ucl.ac.uk"

alias del='mv "$@" ~/.Trash'

######################################################
#                   LINUX
######################################################
if [ "$(uname)" != "Darwin" ] && [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	alias open='xdg-open'
	# Save github password for an hour
	git config --global credential.helper cache
	git config --global credential.helper 'cache --timeout=3600'
fi

######################################################
#                   Notifications
######################################################

function RB_disp_notification {
	if [[ "$(uname)" == "Darwin" ]]; then
		$(osascript -e "display notification \"$2\" with title \"$1\"")
	elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
		zenity --notification --text="${1}: ${2}" > /dev/null 2>&1
		if [ -f ~/tmp/notifications.log ]; then
			echo "${1}: ${2}" >> ~/tmp/notifications.log
		fi
	fi
}
if [[ "$shell" == "bash" ]]; then
	export -f RB_disp_notification
fi

function RB_ {
	command="$@"
	"$@"
	result=$?
	if [[ $result -eq 0 ]]; then
		RB_disp_notification "Task complete: Success!" "$command"
	elif [[ ! $result -eq 130 ]]; then
		RB_disp_notification "Task complete: Failed!" "$command"
	fi
	return $result
} 
if [[ "$shell" == "bash" ]]; then
	export -f RB_
fi

# For getting ssh notifications
function RB_watch_ssh {
	ssh $1 'mkdir -p ~/tmp && echo "Watching server notifications" > ~/tmp/notifications.log && tail -f ~/tmp/notifications.log' | \
	while read line; do
		RB_disp_notification "$1: $line"
	done
}

# Delete all remote git branches - useful for when forking and only want master
alias git_del_remote_branches="git branch -r | grep rijobro | while read -r line ; do git push rijobro --delete ${line#"rijobro/"}; done"
