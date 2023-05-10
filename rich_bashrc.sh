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
	# add timestamp
	export HISTTIMEFORMAT="%F %T "
fi

# If interactive
if [ -t 1 ]; then
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

alias del='mv "$@" ~/.Trash'

######################################################
#                   LINUX AND GIT
######################################################
if [ "$(uname)" != "Darwin" ] && [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	alias open='xdg-open'
fi
git config --global pager.branch false
# Delete all remote git branches - useful for when forking and only want master
function git_del_remote_branches {
	if [ "$#" -ne 1 ]; then
		echo "Error: $0 github username as argument"
		return 1
	fi
	uname=$1
	git branch -r | grep $uname | while read -r line ; do git push $uname --delete ${line#"${uname}/"}; done
}
if [[ "$shell" == "bash" ]]; then
	export -f git_del_remote_branches
fi

######################################################
#                   Mac Docker
######################################################

if [[ "$(uname)" == "Darwin" ]]; then
	function docker_is_running() {
		command docker system info > /dev/null 2>&1 && echo 0 || echo 1
	}
	function docker() {
		if [[ "$1" == "run" || "$1" == "build" || "$1" == "search" ]]; then
			if [[ "$(docker_is_running)" != "0" ]]; then
				echo -e "\n\nStarting daemon...\n\n"
				open --background -a Docker
				res=$?
				if [ $res -ne 0 ]; then
					return $res
				fi
				while [[ "$(docker_is_running)" != "0" ]]; do
					sleep 1
				done
			fi
		fi
		command docker "${@}"
	}
	function docker_stop() {
		test -z "$(docker ps -q 2>/dev/null)" && osascript -e 'quit app "Docker"'
	}
fi
